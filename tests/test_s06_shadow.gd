extends SceneTree

## S06: light the heap, shift its pieces until the shadow is Kent, the cleaner sees the fifth case, Blue Lake reveals the sensor.
##
## Headless:      "$G" --headless --path . --script tests/test_s06_shadow.gd
## With a window: "$G" --path . --script tests/test_s06_shadow.gd   (screenshots -> .artifacts/screenshots/)

const MainScene := preload("res://scenes/main/prototype_01.tscn")
const SHOT_DIR := "res://.artifacts/screenshots"

var main: Node2D
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _setup_s06() -> void:
	main = MainScene.instantiate()
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
	main.s06_pieces = main.S06_PIECE_CORRECT.duplicate()
	main.s06_shadow_done = true
	main.s06_case_clean = true
	main.s06_sensor_revealed = true
	main.s05_lines = []
	main.chapter_state.complete_slice(ChapterState.Slice.S06_PLATFORM)
	main._enter_s07_after_s06()
	await _frames(2)
	await _drain()

func _run() -> void:
	await _setup_s06()
	_check(main.s06_active and main.s05_room == "hall", "S06 in the sensor hall")
	await _drain()
	await _press("blue_lake")
	await _frames(2)
	_check(not main.blue_lake_active, "Space before the lamp is on does nothing")
	await _e_at("Lamp")
	_check(main.s06_lamp_on, "E turns the floor lamp on")
	await _shot("s06_1_messy_shadow")
	await _press("blue_lake")
	await main.blue_lake_transform.finished
	await _frames(2)
	_check(main.blue_lake_active, "Space: Blue Lake")
	var before: int = main.s06_pieces["head"]
	main.chalk_hover_target = "Piece_head"
	main._try_s06_chalk_interaction()
	_check(main.s06_pieces["head"] != before and not main.s06_shadow_done, "Chalk shifts one piece; not done yet")
	for piece in main.S06_PIECES:
		var guard := 0
		while main.s06_pieces[piece] != main.S06_PIECE_CORRECT[piece] and guard < 3:
			main.chalk_hover_target = "Piece_" + piece
			main._try_s06_chalk_interaction()
			guard += 1
	_check(main.s06_shadow_done, "the shadow is Kent")
	_check(not main.blue_lake_active, "Blue Lake folds away when the shadow is done")
	await _shot("s06_2_kent_shadow")
	await _drain()
	await _e_at("Cleaner")
	_check(main.s06_case_clean, "the cleaner sees the shadow looking at the fifth case and wipes it")
	await _drain()
	await _e_at("Rack")
	_check(main.dialogue_label.text.contains("Space"), "E the rack: the case is clean but unreadable, press Space")
	await _press("blue_lake")
	await _frames(2)
	_check(main.blue_lake_active, "Space: Blue Lake again")
	main.chalk_hover_target = "SensorCase"
	main._try_s06_chalk_interaction()
	_check(main.s06_sensor_revealed, "Chalk on the case: the sensor shows")
	_check(main.chapter_state.knows(&"s06_invisible_does_not_mean_nonexistent"), "S06 knowledge learned")
	await _shot("s06_3_sensor")
	await _drain()
	await _wait(main.S04_LINE_TIME + 0.5)
	_check(main.s07_active, "S06 complete -> S07")
	_finish("S06")

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
