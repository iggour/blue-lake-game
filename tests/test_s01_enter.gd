extends SceneTree

## S01, the past route with real input: the photo starts in winter; turning the left clock-eye back
## to opening day hangs the key on the real hook; the key opens the door; E at the open door enters S02.
##
## Headless:      "$G" --headless --path . --script tests/test_s01_enter.gd
## With a window: "$G" --path . --script tests/test_s01_enter.gd   (screenshots -> .artifacts/screenshots/)

const MainScene := preload("res://scenes/main/prototype_01.tscn")
const SHOT_DIR := "res://.artifacts/screenshots"

var main: Node2D
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _finish(label: String) -> void:
	if failures.is_empty():
		print("TEST PASS: " + label)
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _run() -> void:
	main = MainScene.instantiate()
	root.add_child(main)
	await _frames(5)
	_check(main.s01_active and main.s01_era == 1, "S01 starts with the photo in winter")
	await _shot("s01_1_start")

	await _hold("move_up", 60)
	_check(main.player.position.y >= 409.0, "cannot walk up onto the wall (y=%s)" % main.player.position.y)

	await _walk_to_x(720.0)
	await _press_e_expecting("ExitDoor")
	_check(not main.s01_gate_open and _says("空钩子"), "the door is locked, the hook empty")

	await _walk_to_x(180.0)
	await _press_e_expecting("EntrancePhoto")
	_check(_says("下雪") and _says("是我"), "the winter photo shows Graham on the ladder")
	await _shot("s01_2_winter_photo")

	await _walk_to_x(470.0)
	await _press_e_expecting("ClockBack")
	_check(main.s01_clocks_seen and main.s01_era == 1, "first E describes 《观看的永恒》 without turning")
	_check(main.interaction_hint_label.text == "E 往回拨", "hint becomes 往回拨 (%s)" % main.interaction_hint_label.text)
	await _press_e_expecting("ClockBack")
	_check(main.s01_era == 0 and main.s01_key_on_hook, "turning back reaches opening day and the key appears on the hook")
	await _press_e_expecting("ClockBack")
	_check(main.s01_era == 0 and _says("拨不动"), "cannot turn back past opening day")

	main.s01_idle_time = 30.0
	await _seconds(1.5)
	_check(main.s01_eye_look.distance_to(main.S01_HOOK) < 40.0, "when stuck, 《这不是一只眼睛》 looks at the key (%s)" % main.s01_eye_look)

	await _walk_to_x(180.0)
	await _press_e_expecting("EntrancePhoto")
	_check(_says("钥匙挂到"), "the opening-day photo shows the guard hanging the keys")
	await _shot("s01_3_opening_day")

	await _walk_to_x(720.0)
	_check(main.interaction_hint_label.text == "E 取钥匙开门", "hint at the door with the key (%s)" % main.interaction_hint_label.text)
	await _shot("s01_4_key_on_hook")
	await _press_e_expecting("ExitDoor")
	_check(main.s01_gate_open and main.s01_exit_route == "past", "the key opens the door")
	_check(main.s01_active, "opening the door does not jump into S02 by itself")
	_check(main.chapter_state.player_goal == &"find_a_way_out", "goal recorded")
	await _shot("s01_5_door_open")
	await _press_e_expecting("ExitDoor")
	_check(main.s02_active, "E at the open door enters S02")
	_finish("S01 past route")

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
		if (action == "move_right" and x >= target) or (action == "move_left" and x <= target):
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

func _says(fragment: String) -> bool:
	return main.dialogue_label.text.contains(fragment)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _seconds(t: float) -> void:
	await create_timer(t).timeout

func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png(SHOT_DIR + "/" + shot_name + ".png")
