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
	await _setup_s07()
	await _e_at("Rack")
	await _e_at("Rack")
	_check(main.s08_active and main.s08_stolen, "second E takes the sensor -> S08")
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S07_RETURN), "S07 complete")
	var g0: Vector2 = main.s08_guard
	await _wait(1.2)
	_check(main.s08_guard.distance_to(g0) > 30.0, "the guard comes after Graham")
	await _shot("s08_1_chase")
	# Stand still: he closes in but never catches her.
	await _wait(5.0)
	_check(main.s08_guard.distance_to(main.player.position) >= main.S08_GUARD_REACH - 1.0, "the guard never quite reaches her")
	_check(main.s08_chase_time > main.S08_TUNNEL_TIME * 0.8, "the tunnel has closed in")
	await _shot("s08_2_tunnel")
	await _e_at("BackWindow")
	_check(main.transition_started, "E 《窗》: climb out")
	await _wait(4.5)
	_check(main.scene_state == "theater", "the curtain opens on the theater")
	_check(main.dialogue_label.text.contains("舞台"), "standing on the stage")
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S08_TRUE_EXIT), "S08 complete")
	_check(main.player.scale == Vector2.ONE and main.player.ground_top == 410.0, "depth off on the stage")
	await _shot("s08_3_stage")
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
