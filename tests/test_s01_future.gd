extends SceneTree

## S01, the future route: keep turning the right clock-eye forward; past 多年以后 it melts onto the
## floor and the door rusts through. Also: some things do not turn back; the eyelid easter egg; the face.
##
## Headless:      "$G" --headless --path . --script tests/test_s01_future.gd
## With a window: "$G" --path . --script tests/test_s01_future.gd   (screenshots -> .artifacts/screenshots/)

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

	await _walk_to_x(720.0)
	await _press_e_expecting("ExitDoor")

	await _walk_to_x(585.0)
	await _press_e_expecting("ClockForward")
	_check(main.s01_clocks_seen, "first E describes the painting")
	await _press_e_expecting("ClockForward")
	_check(main.s01_era == 2 and not main.s01_key_on_hook, "forward reaches 多年以后")
	await _press_e_expecting("ClockForward")
	_check(main.s01_melt == 1 and _says("往下淌"), "past the last era the eye starts to melt")
	await _press_e_expecting("ClockForward")
	_check(main.s01_melt == 2 and not main.s01_gate_open, "it drips onto the floor; the door rusts but holds")
	await _shot("s01_f1_melting")

	await _walk_to_x(470.0)
	await _press_e_expecting("ClockBack")
	_check(main.s01_era == 1 and main.s01_melt == 2 and _says("倒不回去"), "the photo turns back, the melted eye does not")

	await _walk_to_x(585.0)
	await _press_e_expecting("ClockForward")
	await _press_e_expecting("ClockForward")
	_check(main.s01_melt == 3 and main.s01_gate_open and main.s01_exit_route == "future", "the door rusts through")
	await _shot("s01_f2_rusted_open")

	# Easter egg: the third look at 《这不是一只眼睛》 pulls its eyelid shut.
	await _walk_to_x(910.0)
	await _press_e_expecting("NotAnEye")
	await _press_e_expecting("NotAnEye")
	await _press_e_expecting("NotAnEye")
	_check(main.s01_eyelid_closed and main.player.input_locked, "the eyelid closes and the gallery goes dark")
	await _seconds(1.0)
	await _shot("s01_f3_eyelid_dark")
	await _seconds(4.0)
	_check(not main.s01_eyelid_closed and not main.player.input_locked, "it opens again")
	_check(main.chapter_state.has_story_event(&"s01_easter_eyelid"), "easter egg recorded")

	await _walk_to_x(200.0)
	_check(main.s01_face_noticed and _says("这面墙在看我们"), "from the far left the wall reads as a face")
	await _shot("s01_f4_face")

	await _walk_to_x(720.0)
	await _press_e_expecting("ExitDoor")
	_check(main.s02_active, "E at the rusted-open door enters S02")
	_finish("S01 future route")

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
