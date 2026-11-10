extends SceneTree

## S08: take the sensor, the guard gives chase (never catches up), vision narrows into a tunnel, E 《窗》 -> curtain -> theater stage.
##
## Headless:      "$G" --headless --path . --script tests/test_s08_escape.gd
## With a window: "$G" --path . --script tests/test_s08_escape.gd   (screenshots -> .artifacts/screenshots/)

const MainScene := preload("res://scenes/main/prototype_01.tscn")
const SHOT_DIR := "res://.artifacts/screenshots"

var main: Node2D
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _setup_s06() -> void:
	main = MainScene.instantiate()
	main.dialogue_needs_e = false  # tests drive the story; they don't page through dialogue
	root.add_child(main)
	await _frames(5)
	main.s01_active = false
	main.s01_gate_open = true
	main.chapter_state.complete_slice(ChapterState.Slice.S05_WINDOW)
	main._enter_s06_after_s05()
	await _frames(2)

## Skip S06 with its outcome in place: lamp on, shadow is Kent, case clean, sensor revealed.
func _setup_s07() -> void:
	await _setup_s06()
	main.s06_lamp_on = true
	for piece in main.S06_PIECES:
		main.s06_pieces[piece] = main._s06_piece_target(piece)
	main.s06_shadow_done = true
	main.s06_case_clean = true
	main.s06_sensor_revealed = true
	main.s05_lines = []
	main.s06_finish_pending = false
	main.chapter_state.complete_slice(ChapterState.Slice.S06_PLATFORM)
	main._enter_s07_after_s06()
	await _frames(2)
	await _drain()

func _run() -> void:
	await _setup_s07()
	await _e_at("Rack")
	await _wait(0.4)
	await _press("interact")
	await _wait(1.2)
	_check(main.s07_hesitated, "first E in the rack close-up: hesitation")
	await _press("interact")
	_check(main.closeup_anim == "take", "second E: the glass door opens")
	await _wait(1.0)
	_check(main._s01_hyper_now().size() == 2 and main._s01_hyper_now()[0] == "aperture", "a hyper-real insert: the lenses' apertures closing on her hand")
	await _shot("s08_0_hyperreal_aperture")
	await _wait(1.8)
	_check(main.closeup == "" and not main.player.input_locked, "the close-up is gone; she can run")
	_check(main.s08_active and main.s08_stolen, "she takes the sensor -> S08")
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S07_RETURN), "S07 complete")
	await _wait(0.8)
	_check(main.s08_run < 1.0, "standing still: the circle does not close")
	_check(main.s08_mouse_on and main.dialogue_label.text.contains("鼠贼"), "the guard kicks the bucket; the mouse behind it bolts")
	await _shot("s08_0b_mouse_bolts")
	# Running away from the mouse: the circle holds.
	main.player.position = Vector2(main._s05_px(150, 0.05), main._s05_y(0.05))
	await _frames(2)
	Input.action_press("move_up")
	for f in range(10):
		await physics_frame
	var r0: float = main.s08_run
	for f in range(30):
		await physics_frame
	Input.action_release("move_up")
	_check(main.s08_run == r0 and r0 < 1.0, "running, but not after the mouse: the circle does not close (%.0f)" % main.s08_run)
	# Following it: the circle closes with the distance run.
	var closest := 99999.0
	var half_shot := false
	for f in range(1800):
		var d: Vector2 = main._s08_mouse_screen() - main.player.position
		_hold_if("move_right", d.x > 18.0)
		_hold_if("move_left", d.x < -18.0)
		_hold_if("move_down", d.y > 8.0)
		_hold_if("move_up", d.y < -8.0)
		await physics_frame
		if main.s08_active and main.scene_state == "gallery":
			closest = minf(closest, main.s08_guard.distance_to(main.player.position))
		if not half_shot and main.s08_run > main.S08_RUN_TOTAL * 0.5:
			half_shot = true
			_check(main._s08_iris_radius() < 500.0, "half-way: the circle has closed in")
			await _shot("s08_1_iris")
		if main.s08_black_time >= 0.0 or main.scene_state == "theater":
			break
	for a in ["move_right", "move_left", "move_down", "move_up"]:
		Input.action_release(a)
	_check(closest >= main.S08_GUARD_REACH - 10.0, "the guard never reaches her (closest %.0f)" % closest)
	_check(main.s08_exit_started, "the circle closes completely")
	await _wait(0.3)
	await _shot("s08_2_black")
	await _wait(1.0)
	_check(main.scene_state == "theater", "after the black: the theater")
	_check(main.theater_reveal >= 0.0, "a circle of light comes on first")
	await _wait(0.3)
	await _shot("s08_3_spotlight")
	_check(main.dialogue_label.text.contains("灯光"), "a circle of light on Graham")
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S08_TRUE_EXIT), "S08 complete")
	_check(main.player.scale == Vector2.ONE and main.player.ground_top == 410.0, "depth off on the stage")
	await _wait(2.0)
	await _shot("s08_4_stage")
	_finish("S08")

func _stand_at(item_name: String, dz: float = 0.0) -> void:
	var item: Dictionary = main._s05_item(item_name)
	var z: float = clampf(main._s05_item_z(item) + dz, 0.0, 1.0)
	var x: float = main._s05_px(main.S05_RAIL_X if item_name == "Lens" else item.x, z)
	main.player.position = Vector2(x, main._s05_y(z))
	await _frames(2)

func _e_at(item_name: String, dz: float = 0.0) -> void:
	await _stand_at(item_name, dz)
	var nearest: Dictionary = main._get_nearest_interactable()
	_check(nearest.get("name", "") == item_name, "at %s, E targets %s" % [item_name, nearest.get("name", "<nothing>")])
	await _press("interact")

func _e_room(item_name: String) -> void:
	for item in main.s07_room_items:
		if item.name == item_name and (item.room == main.s07_room or item.room == "any"):
			main.player.position = Vector2(item.position.x, 470.0)
	await _frames(2)
	var nearest: Dictionary = main._get_nearest_interactable()
	_check(nearest.get("name", "") == item_name, "in %s, E targets %s" % [main.s07_room, nearest.get("name", "<nothing>")])
	await _press("interact")

func _drain() -> void:
	var guard := 0
	while not main.s05_lines.is_empty() and guard < 20:
		await _press("interact")
		guard += 1

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

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _frames(3)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png(SHOT_DIR + "/" + shot_name + ".png")

func _finish(label: String) -> void:
	if failures.is_empty():
		print("TEST PASS: " + label)
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _stand_cleaner(z: float) -> void:
	main.player.position = Vector2(main._s05_px(main.S05_CLEANER_X, z), main._s05_y(z))
	await _frames(2)

func _talk_cleaner(z: float) -> void:
	await _stand_cleaner(z)
	var nearest: Dictionary = main._get_nearest_interactable()
	_check(nearest.get("name", "") == "Cleaner", "at z=%.2f E targets the cleaner (got %s)" % [z, nearest.get("name", "<nothing>")])
	await _press("interact")
	_check(main.closeup == "cleaner", "E opens the cleaner's close-up")
	await _wait(0.35)
	# The hand starts on him: E talks.
	await _press("interact")

func _close() -> void:
	await _wait(0.35)
	await _press("interact")
	await _wait(0.45)
	_check(main.closeup == "", "close-up closed (%s)" % main.closeup)

func _hand_to(target: Vector2) -> void:
	for i in range(600):
		var d: Vector2 = target - main.closeup_hand
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
