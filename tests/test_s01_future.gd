extends SceneTree

## S01, the future route: keep turning the right clock-eye forward, one notch per close-up;
## 《观看的永恒》 snows, then gathers dust; past 多年以后 the eye melts onto the floor, the "出口" sign
## goes dark and falls, and the door rusts through. Also: the melted eye does not turn back; the
## eyelid easter egg (inside the close-up); the face.
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
	_check(_says("嗡嗡"), "in winter the 出口 sign hums")
	await _close()

	await _walk_to_x(585.0)
	await _press_e_expecting("ClockForward")
	_check(main.s01_clocks_seen and main.s01_era == 1, "first E describes the painting")
	await _close()
	await _turn("ClockForward")
	_check(main.s01_era == 2 and _says("灰"), "forward reaches 多年以后: dust in the painting")
	await _shot("s01_f1_clock_years_later")
	await _close()
	# Years later the photo is empty but for the blue book, which leafs through itself.
	await _walk_to_x(180.0)
	await _press_e_expecting("EntrancePhoto")
	await _hand_to(Vector2(259, 337))
	await _press("interact")
	await _seconds(0.8)
	await _shot("s01_f1b_book_pages")
	await _seconds(1.0)
	_check(main.s01_book_open and _says("手印"), "the blue book shows a small handprint")
	await _close_photo()
	await _walk_to_x(585.0)
	await _turn("ClockForward")
	_check(main.s01_melt == 1 and _says("往下淌"), "past the last era the eye starts to melt")
	await _close()
	await _turn("ClockForward")
	_check(main.s01_melt == 2 and not main.s01_gate_open, "it drips onto the floor; the door rusts but holds")
	_check(main.closeup_anim == "splat", "a hyper-real insert: the eye on the carpet")
	await _seconds(0.3)
	await _shot("s01_f2b_hyperreal_eyeball")
	await _seconds(0.8)
	await _close()
	await _shot("s01_f2_melting_sign_fallen")

	await _walk_to_x(470.0)
	await _turn("ClockBack")
	_check(main.s01_era == 1 and main.s01_melt == 2 and _says("倒不回去"), "the painting turns back, the melted eye does not")
	await _close()

	await _walk_to_x(585.0)
	await _turn("ClockForward")
	await _close()
	await _turn("ClockForward")
	_check(main.s01_melt == 3 and main.s01_gate_open and main.s01_exit_route == "future", "the door rusts through")
	await _close()
	await _shot("s01_f3_rusted_open")

	# 《这不是一只眼睛》 up close: no hint, but Graham in its cornea; the third look pulls its eyelid shut.
	await _walk_to_x(910.0)
	await _press_e_expecting("NotAnEye")
	_check(main.closeup == "eye", "the eye's close-up")
	await _close()
	await _press_e_expecting("NotAnEye")
	await _seconds(0.4)
	await _shot("s01_f4_eye_fisheye")
	await _close()
	await _press_e_expecting("NotAnEye")
	_check(main.closeup_anim == "eyelid", "the third look pulls the eyelid down inside the close-up")
	await _seconds(0.7)
	_check(main._s01_hyper_now().size() == 2, "the eyelid is a hyper-real insert")
	await _shot("s01_f5_hyperreal_eyelid")
	await _seconds(1.2)
	_check(main.closeup == "" and main.s01_eyelid_closed and main.player.input_locked, "the eyelid closes and the gallery goes dark")
	await _seconds(0.5)
	await _shot("s01_f6_eyelid_dark")
	await _seconds(4.0)
	_check(not main.s01_eyelid_closed and not main.player.input_locked, "it opens again")
	_check(main.chapter_state.has_story_event(&"s01_easter_eyelid"), "easter egg recorded")

	await _walk_to_x(200.0)
	_check(main.s01_face_noticed and _says("这面墙在看我们"), "from the far left the wall reads as a face")
	await _shot("s01_f7_face")

	await _walk_to_x(720.0)
	await _press_e_expecting("ExitDoor")
	_check(main.s02_active, "E at the rusted-open door enters S02")
	_finish("S01 future route")

## One notch: E opens 《观看的永恒》 and the hand turns inside the close-up.
func _turn(item_name: String) -> void:
	await _press_e_expecting(item_name)
	_check(main.closeup.begins_with("clock"), "the clock close-up opened")
	await _seconds(1.05)

func _press_e_expecting(item_name: String) -> void:
	var nearest: Dictionary = main._get_nearest_s01_interactable()
	_check(nearest.get("name", "") == item_name, "at x=%d E targets %s, expected %s" % [main.player.position.x, nearest.get("name", "<nothing>"), item_name])
	_check(main.interaction_hint_label.visible, "E hint visible at %s" % item_name)
	await _press("interact")

func _close() -> void:
	await _seconds(0.35)
	await _press("interact")
	await _seconds(0.45)
	_check(main.closeup == "", "close-up closed")

func _hand_to(target: Vector2) -> void:
	for i in range(600):
		var d: Vector2 = target - main.s01_photo_hand
		if d.length() < 5.0:
			break
		_hold_if("move_right", d.x > 3.0)
		_hold_if("move_left", d.x < -3.0)
		_hold_if("move_down", d.y > 3.0)
		_hold_if("move_up", d.y < -3.0)
		await process_frame
	for a in ["move_right", "move_left", "move_down", "move_up"]:
		Input.action_release(a)
	await _frames(2)

func _hold_if(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _close_photo() -> void:
	await _hand_to(Vector2(40, 60))
	await _close()

func _walk_to_x(target: float) -> void:
	var action := "move_right" if target > main.player.position.x else "move_left"
	Input.action_press(action)
	for i in range(600):
		# Re-press every frame: a windowed run that loses focus releases held actions.
		Input.action_press(action)
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
