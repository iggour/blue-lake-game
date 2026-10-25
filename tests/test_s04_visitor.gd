extends SceneTree

## S04 walkthrough with real input events (keyboard E / Space, mouse move + left click).
##
## Headless:      "$G" --headless --path . --script tests/test_s04_visitor.gd
## With a window: "$G" --path . --script tests/test_s04_visitor.gd   (screenshots -> .artifacts/screenshots/)

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

	# Arrive in S04 the way S03 hands off, with S01-S03 effects in place.
	main.s01_active = false
	main.s01_gate_open = true
	main.gate_body.collision_layer = 0
	main.west_exit_body.collision_layer = 0
	main.blue_lake_transform_completed = true
	main.chapter_state.complete_slice(ChapterState.Slice.S03_MIRROR)
	main._enter_s04_after_s03()
	await _frames(2)
	_check(main.s04_active, "S04 is active")
	_check(main.player.position.x > 900.0, "Graham arrives at the right wall (x=%d)" % main.player.position.x)
	await _shot("s04_1_enter")

	# Order of the room: the visitor is met before the restorer.
	var visitor_x: float = _item("Visitor").position.x
	var restorer_x: float = _item("Restorer").position.x
	var pigment_x: float = _item("PigmentStation").position.x
	var window_x: float = _item("BlockedWindow").position.x
	_check(visitor_x > window_x and window_x > restorer_x, "《窗》 hangs between visitor and restorer")
	_check(absf(pigment_x - restorer_x) < 120.0, "pigment station sits beside the restorer")
	await _press_e_at("Restorer")
	_check(not main.s04_restorer_observed, "restorer stays busy until the visitor is met")

	await _press_e_at("Visitor")
	_check(main.s04_visitor_observed, "E: visitor observed")
	await _press_e_at("Restorer")
	await _press_e_at("Restorer")
	_check(main.s04_pigment_borrowed, "E: pigment borrowed from restorer")
	await _press_e_at("PigmentStation")
	_check(main.s04_pigment_applied, "E: pigment applied")

	await _press_e_at("Lamp")
	_check(main.dialogue_label.text.contains("Space"), "E at the lamp points to Space + Chalk")

	await _press_action("blue_lake")
	await _frames(3)
	_check(main.blue_lake_active, "Space: Blue Lake active")
	if DisplayServer.get_name() == "headless":
		# No real cursor headless: aim the Chalk the way _update_chalk_hover would.
		main.chalk_hover_target = "Lamp"
		main._try_s04_chalk_interaction()
	else:
		await _click_at(_lamp_point())
	_check(main.s04_lamp_observed, "Chalk click on the lamp registers")
	await _shot("s04_2_lamp")

	await _press_e_at("LightSwitch")
	_check(main.s04_lights_off, "E: lights off")
	await _press_e_at("Visitor")
	_check(main.s04_visitor_recognized, "E: visitor recognizes Graham")
	await _press_e_at("Visitor")
	_check(main.s04_visitor_moved, "E: visitor steps aside")
	await _shot("s04_3_lights_off")
	await _press_e_at("BlockedWindow")
	_check(main.s05_active, "E on the Window completes S04 -> S05")

	if failures.is_empty():
		print("TEST PASS: S04")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _lamp_point() -> Vector2:
	return main.S04_LAMP_CENTER

func _item(item_name: String) -> Dictionary:
	for item in main.s04_interactables:
		if item.name == item_name:
			return item
	return {}

func _press_e_at(item_name: String) -> void:
	var item := _item(item_name)
	main.player.position = Vector2(item.position.x, main.player.ground_y)
	await _frames(2)
	var nearest: Dictionary = main._get_nearest_s04_interactable()
	_check(nearest.get("name", "") == item_name, "standing at %s, E targets %s" % [item_name, nearest.get("name", "<nothing>")])
	await _press_action("interact")

func _press_action(action: String) -> void:
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

func _click_at(point: Vector2) -> void:
	# get_mouse_position() reads the real OS cursor, so the cursor has to be moved (needs a window).
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.warp_mouse(point)
	root.push_input(motion)
	await _frames(2)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = point
	click.global_position = point
	click.pressed = true
	root.push_input(click)
	await _frames(1)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click)
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
