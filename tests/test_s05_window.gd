extends SceneTree

## S05 walkthrough: 《窗》 hangs on the wall; E asks for Space; Space + Chalk reveals the handle,
## Space + Chalk again opens it, and the opened Window leads on to S06.
##
## Headless:      "$G" --headless --path . --script tests/test_s05_window.gd
## With a window: "$G" --path . --script tests/test_s05_window.gd   (screenshots -> .artifacts/screenshots/)

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
	# Arrive in S05 the way S04 hands off: standing in front of 《窗》.
	main.s01_active = false
	main.s01_gate_open = true
	main.blue_lake_transform_completed = true
	main.chapter_state.complete_slice(ChapterState.Slice.S04_VISITOR)
	main.player.position.x = 590.0
	main._enter_s05_after_s04()
	await _frames(2)
	_check(main.s05_active, "S05 is active")
	_check(main.S05_WINDOW_CENTER.y < 372.0, "《窗》 hangs on the wall, above the floor line")

	await _press_e_expecting("Window")
	_check(main.s05_window_observed, "E observes 《窗》")
	_check(main.dialogue_label.text.contains("Space"), "E on 《窗》 says to press Space")
	await _shot("s05_1_window")

	await _press("blue_lake")
	# The first Space in a Slice plays the Blue Lake transformation before the Chalk appears.
	await main.blue_lake_transform.finished
	await _frames(2)
	_check(main.blue_lake_active, "Space enters Blue Lake")
	_check(main.dialogue_label.text.contains("左键"), "Blue Lake says to left-click 《窗》")
	if DisplayServer.get_name() == "headless":
		main.chalk_hover_target = "Window"
		main._try_s05_chalk_interaction()
	else:
		await _move_mouse(main.S05_WINDOW_CENTER)
		_check(main.chalk_hover_target == "Window", "Chalk hovers 《窗》")
		await _click()
	_check(main.s05_window_handle_found, "first Chalk click reveals the handle")
	_check(main.dialogue_label.text.contains("Space"), "after the handle, Blue Lake says to press Space again")
	await _frames(2)
	await _shot("s05_2_handle")

	await _press("blue_lake")
	await _frames(3)
	_check(main.blue_lake_active, "Space enters Blue Lake again")
	if DisplayServer.get_name() == "headless":
		main.chalk_hover_target = "Window"
		main._try_s05_chalk_interaction()
	else:
		await _move_mouse(main.S05_WINDOW_CENTER)
		_check(main.chalk_hover_target == "Window", "Chalk hovers 《窗》")
		await _click()
	_check(main.s05_window_open, "second Chalk click opens 《窗》")
	await _frames(2)
	await _shot("s05_3_open")
	await create_timer(1.2).timeout
	_check(main.s06_active, "opened 《窗》 leads on to S06")

	if failures.is_empty():
		print("TEST PASS: S05")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _move_mouse(point: Vector2) -> void:
	# get_mouse_position() reads the real OS cursor, so the cursor has to be moved (needs a window).
	root.warp_mouse(point)
	await _frames(3)

func _click() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = root.get_mouse_position()
	click.global_position = click.position
	click.pressed = true
	root.push_input(click)
	await _frames(1)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click)
	await _frames(2)

func _press_e_expecting(item_name: String) -> void:
	var nearest: Dictionary = main._get_nearest_s05_interactable()
	_check(nearest.get("name", "") == item_name, "at x=%d E targets %s, expected %s" % [main.player.position.x, nearest.get("name", "<nothing>"), item_name])
	_check(main.interaction_hint_label.visible, "E hint visible at %s" % item_name)
	await _press("interact")

func _walk_to_x(target: float) -> void:
	var action := "move_right" if target > main.player.position.x else "move_left"
	var last_x: float = main.player.position.x
	Input.action_press(action)
	for i in range(600):
		await physics_frame
		var x: float = main.player.position.x
		var looped_back := absf(x - last_x) > 100.0
		last_x = x
		if (action == "move_right" and x >= target) or (action == "move_left" and x <= target) or looped_back or main.s06_active:
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
