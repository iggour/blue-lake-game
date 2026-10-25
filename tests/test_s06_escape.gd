extends SceneTree

## S06 take branch: reveal the sensor, take the original, run from the guard to the window,
## climb out with E, and land on the Truth Theater stage (not outside).
##
## Headless:      "$G" --headless --path . --script tests/test_s06_escape.gd
## With a window: "$G" --path . --script tests/test_s06_escape.gd   (screenshots -> .artifacts/screenshots/)

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
	# Arrive in S06 the way S05 hands off.
	main.s01_active = false
	main.s01_gate_open = true
	main.blue_lake_transform_completed = true
	main.chapter_state.complete_slice(ChapterState.Slice.S05_WINDOW)
	main._enter_s06_after_s05()
	await _frames(2)
	_check(main.s06_active, "S06 is active")

	_check(absf(main.player.position.x - main.S06_WINDOW_CENTER.x) < 1.0, "Graham arrives in front of 《窗》")
	await _walk_to_x(main.S06_PLATFORM_CENTER.x)
	await _press_e_expecting("CentralPlatform")
	_check(main.s06_platform_observed, "E observes the empty platform")
	await _press("blue_lake")
	await main.blue_lake_transform.finished
	await _frames(2)
	_check(main.blue_lake_active, "Space enters Blue Lake")
	await _solve_s06_gaze()
	await _shot("s06_0_revealed")
	await _press_e_expecting("CentralPlatform")
	_check(main.dialogue_label.text.contains("停产"), "Graham knows the model is discontinued")
	_check(main.s06_take_button.visible, "take / leave choice is shown")
	main.s06_take_button.pressed.emit()
	await _frames(2)
	_check(main.s06_chase_active, "taking the original starts the chase")
	await _shot("s06_1_chase")

	await _walk_to_x(main.S06_WINDOW_CENTER.x)
	await _press_e_expecting("EscapeWindow")
	_check(main.transition_started, "E at the window starts the curtain transition")
	await main.transition.finished
	await _frames(3)
	_check(main.scene_state == "theater", "the escape lands in the theater (got %s)" % main.scene_state)
	_check(main.chapter_state.has_story_event(&"s06_escaped_with_original"), "escape story event recorded")
	_check(main.dialogue_label.text.contains("舞台"), "landing text mentions the stage")
	await _shot("s06_2_theater")

	if failures.is_empty():
		print("TEST PASS: S06 escape -> theater")
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
	await _frames(2)
	var nearest: Dictionary = main._get_nearest_s06_interactable()
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
		if (action == "move_right" and x >= target) or (action == "move_left" and x <= target) or looped_back or main.transition_started:
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

func _solve_s06_gaze() -> void:
	# Blue Lake alone sees only the outline; turning 《凝视》 onto the platform adds the colour.
	await _chalk_on("Sensor", main.S06_PLATFORM_CENTER)
	_check(main.s06_contour_seen, "Chalk on the platform shows the outline")
	_check(not main.s06_sensor_revealed, "the outline alone does not reveal the part")
	_check(main.blue_lake_active, "Blue Lake stays on after the outline")
	await _chalk_on("Gaze", main.S06_GAZE_EYE)
	await _shot("s06_a_outline_gaze")
	for i in range(4):
		if main.s06_sensor_revealed:
			break
		await _chalk_on("Gaze", main.S06_GAZE_EYE)
	_check(main.s06_sensor_revealed, "turning 《凝视》 onto the platform reveals the part")
	_check(main.s06_gaze_index == 3, "《凝视》 ends up looking at the platform")
	_check(main.dialogue_label.text.contains("一模一样"), "Graham recognizes the model")

func _chalk_on(target: String, point: Vector2) -> void:
	if DisplayServer.get_name() == "headless":
		main.chalk_hover_target = target
		main._try_s06_chalk_interaction()
		await _frames(1)
	else:
		await _move_mouse(point)
		_check(main.chalk_hover_target == target, "Chalk hovers %s" % target)
		await _click()
