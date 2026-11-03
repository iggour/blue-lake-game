extends SceneTree

## S05: open 《窗》 and walk into the sensor hall behind it (with depth), meet the cleaner,
## get the old lens cleaned and focused, and see that the chart's last cell is not empty.
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
	# Arrive in S05 the way S04 hands off: standing in front of 《窗》, frame and handle in place.
	main.s01_active = false
	main.s01_gate_open = true
	main.chapter_state.complete_slice(ChapterState.Slice.S04_VISITOR)
	main.player.position.x = 590.0
	main._enter_s05_after_s04()
	await _frames(2)
	_check(main.s05_active and main.s05_room == "window", "S05 starts in front of 《窗》")

	await _press_e_expecting("Window")
	_check(main.s05_window_observed, "E observes 《窗》")
	_check(main.dialogue_label.text.contains("红房子"), "the painting shows the red house")
	await _shot("s05_1_window")
	await _press("blue_lake")
	await main.blue_lake_transform.finished
	await _frames(2)
	_check(main.blue_lake_active, "Space enters Blue Lake")
	main.chalk_hover_target = "Window"
	main._try_s05_chalk_interaction()
	_check(main.s05_window_open, "Chalk on the handle opens 《窗》")
	_check(main.chapter_state.knows(&"s05_blue_lake_can_change_the_world"), "first change of the world is learned")
	await create_timer(0.45).timeout
	await _shot("s05_2_opening")
	await create_timer(0.8).timeout
	_check(main.s05_room == "hall", "the landscape grows into the hall")
	_check(main.s05_labeled, "the cleaner tags Graham from afar")
	await _shot("s05_3_hall")
	await _drain()

	# Depth: W walks away from the camera and Graham gets smaller.
	var y0: float = main.player.position.y
	await _hold("move_up", 20)
	_check(main.player.position.y < y0 - 20.0, "W walks into depth")
	_check(main.player.scale.x < 0.98, "farther away, Graham is smaller (scale %.2f)" % main.player.scale.x)

	await _e_at("Eyepiece")
	_check(main.s05_view == "lens" and main.dialogue_label.text.contains("白雾"), "eyepiece before cleaning: fogged")
	await _shot("s05_4_fogged")
	await _e_at("Bucket")
	_check(main.dialogue_label.text.contains("楼下"), "the bucket leaked to the floor below (《那喀索斯》's water)")
	await _e_at("Mural")
	_check(main.dialogue_label.text.contains("美术馆"), "the red house is the museum")
	await _e_at("BlindStation")
	_check(main.dialogue_label.text.contains("最后一行"), "《盲》 points at the chart's last row")
	await _e_at("AiwsSample")
	_check(main.s05_view == "aiws", "looking through the macropsia sample")
	await _shot("s05_5_aiws")

	await _e_at("Cleaner")
	_check(main.s05_cleaner_met, "the cleaner talks once Graham is close")
	await _shot("s05_6_cleaner")
	await _drain()

	# Push the lens down the rail until it is big enough for him to see.
	for i in range(4):
		await _e_at("Lens", -0.05)
	_check(main.s05_lens_notch == 5, "lens pushed to the far end (notch %d)" % main.s05_lens_notch)
	_check(main.s05_lens_clean, "near him, the cleaner sees the lens and cleans it")
	await _drain()
	await _e_at("Eyepiece")
	_check(not main.s05_cell_seen and main.dialogue_label.text.contains("太远"), "clean but out of focus")
	for i in range(3):
		await _e_at("Lens", 0.05)
	_check(main.s05_lens_notch == main.S05_FOCUS_NOTCH, "lens pulled back into focus")
	await _e_at("Eyepiece")
	_check(main.s05_cell_seen, "in focus: the last cell is not empty")
	await _shot("s05_7_eight_lenses")
	await _drain()
	await create_timer(main.S04_LINE_TIME + 0.5).timeout
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S05_WINDOW), "S05 complete")
	_check(main.s06_active, "hands on to S06")
	_check(main.player.scale == Vector2.ONE and main.player.ground_top == 410.0, "depth mode is switched off after S05")

	if failures.is_empty():
		print("TEST PASS: S05")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _stand_at(item_name: String, dz: float = 0.0) -> void:
	var item: Dictionary = main._s05_item(item_name)
	var z: float = clampf(main._s05_item_z(item) + dz, 0.0, 1.0)
	var x: float = main._s05_px(main.S05_RAIL_X if item_name == "Lens" else item.x, z)
	main.player.position = Vector2(x, main._s05_y(z))
	await _frames(2)

func _e_at(item_name: String, dz: float = 0.0) -> void:
	await _stand_at(item_name, dz)
	await _press_e_expecting(item_name)

func _drain() -> void:
	var guard := 0
	while not main.s05_lines.is_empty() and guard < 20:
		await _press("interact")
		guard += 1

func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _frames(3)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png(SHOT_DIR + "/" + shot_name + ".png")

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _press_e_expecting(item_name: String) -> void:
	var nearest: Dictionary = main._get_nearest_s05_interactable()
	_check(nearest.get("name", "") == item_name, "at x=%d E targets %s, expected %s" % [main.player.position.x, nearest.get("name", "<nothing>"), item_name])
	_check(main.interaction_hint_label.visible, "E hint visible at %s" % item_name)
	await _press("interact")

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
