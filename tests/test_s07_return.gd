extends SceneTree

## S06 leave branch -> S07 with real input only: a real mouse click on 「留下展品」, held keys to walk,
## real Space and real Chalk clicks on the mirror and 《窗》 traces, until S08 starts.
## Needs a window (real cursor):  "$G" --path . --script tests/test_s07_return.gd
## Headless only checks the hand-off: "$G" --headless --path . --script tests/test_s07_return.gd

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
	var windowed := DisplayServer.get_name() != "headless"
	main.s01_active = false
	main.s01_gate_open = true
	main.blue_lake_transform_completed = true
	main.chapter_state.complete_slice(ChapterState.Slice.S05_WINDOW)
	main._enter_s06_after_s05()
	await _frames(2)
	await _press_e_expecting("CentralPlatform")
	await _press("blue_lake")
	await main.blue_lake_transform.finished
	await _frames(2)
	main.chalk_hover_target = "Sensor"
	main._try_s06_chalk_interaction()
	await _press_e_expecting("CentralPlatform")
	_check(main.s06_leave_button.visible, "choice is shown")
	if windowed:
		var button: Button = main.s06_leave_button
		await _move_mouse(button.get_global_rect().get_center())
		await _click()
	else:
		main.s06_leave_button.pressed.emit()
	await create_timer(1.0).timeout
	_check(main.s07_active, "leaving the original starts S07")
	await _shot("s07_1_enter")
	if not windowed:
		_finish()
		return

	_check(main.s07_room == "gallery", "S07 starts back in the 《窗》 room")
	_check(not main.s04_lights_off, "the lights are on again")

	# Right wall chalk door -> the hall with the dead-end mirror.
	await _walk_to_x(1010.0)
	_check(main.s07_room == "hall", "walking through the right chalk door reaches the hall")
	await _walk_to_x(983.0)
	await _press_e_expecting("ReturnMirror")
	_check(main.dialogue_label.text.contains("Space"), "mirror revisit says to press Space")
	await _press("blue_lake")
	if not main.blue_lake_active:
		await main.blue_lake_transform.finished
		await _frames(2)
	_check(main.blue_lake_active, "Space enters Blue Lake in S07")
	_check(main.dialogue_label.text.contains("左键"), "Blue Lake says to left-click the mirror")
	await _move_mouse(main.S03_MIRROR_CENTER)
	_check(main.chalk_hover_target == "ReturnMirror", "Chalk hovers the mirror")
	await _shot("s07_2_hall_blue_lake")
	await _click()
	_check(main.s07_mirror_trace_found, "mirror trace found")
	await _shot("s07_3_mirror_trace")

	# Left wall chalk door -> back to 《窗》.
	await _walk_to_x(0.0)
	_check(main.s07_room == "gallery", "walking through the left chalk door returns to the 《窗》 room")
	await _walk_to_x(590.0)
	await _press_e_expecting("ReturnWindow")
	_check(main.s07_window_observed, "E revisits 《窗》")
	await _press("blue_lake")
	await _frames(3)
	_check(main.blue_lake_active, "Space enters Blue Lake again")
	await _move_mouse(main.S05_WINDOW_CENTER)
	_check(main.chalk_hover_target == "ReturnWindow", "Chalk hovers 《窗》")
	await _click()
	_check(main.s07_window_trace_found, "《窗》 trace found")
	await _shot("s07_4_window_trace")
	await create_timer(1.0).timeout
	_check(main.s08_active, "S07 completes into S08")
	await _shot("s08_0_enter")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("TEST PASS: S07")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _nearest() -> Dictionary:
	return main._get_nearest_s07_interactable() if main.s07_active else main._get_nearest_s06_interactable()

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
	var nearest: Dictionary = _nearest()
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
		if (action == "move_right" and x >= target) or (action == "move_left" and x <= target) or looped_back or main.s08_active:
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
