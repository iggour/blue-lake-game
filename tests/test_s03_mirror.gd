extends SceneTree

## S03 walkthrough with real input: the left wall is solid at first; E on the dead-end mirror
## asks for Space; Space + Chalk click on the mirror; then walking left through the wall reaches S04.
##
## Headless:      "$G" --headless --path . --script tests/test_s03_mirror.gd
## With a window: "$G" --path . --script tests/test_s03_mirror.gd   (screenshots -> .artifacts/screenshots/)

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
	# Arrive in S03 the way S02's second loop hands off.
	main.s01_gate_open = true
	main.gate_body.collision_layer = 0
	main.s01_active = false
	main.chapter_state.complete_slice(ChapterState.Slice.S01_ENTER)
	main.chapter_state.complete_slice(ChapterState.Slice.S02_LOST)
	main._enter_s03_after_s02()
	await _frames(2)
	_check(main.s03_active, "S03 is active")
	_check(absf(main.player.position.x - 120.0) < 1.0, "S03 starts at the hall entrance")

	# Before the mirror is solved the left wall is solid.
	await _walk_to_x(0.0)
	_check(main.player.position.x > 50.0, "left wall blocks before the mirror (x=%d)" % main.player.position.x)
	_check(main.s03_active, "still in S03")

	await _walk_to_x(260.0)
	await _press_e_expecting("MirrorInMirror")
	_check(main.dialogue_label.text.contains("镜中镜"), "hall exhibits still answer E in S03")
	await _walk_to_x(545.0)
	await _press_e_expecting("SecurityGuard")

	await _walk_to_x(983.0)
	await _press_e_expecting("Mirror")
	_check(main.s03_mirror_observed, "E observes the mirror")
	_check(main.dialogue_label.text.contains("Space"), "mirror dialogue tells you to press Space")
	await _frames(2)
	_check(main.interaction_hint_label.visible and main.interaction_hint_label.text.contains("SPACE"), "SPACE prompt is shown")
	await _shot("s03_1_mirror")

	await _press("blue_lake")
	await main.blue_lake_transform.finished
	await _frames(2)
	_check(main.blue_lake_active, "Space enters Blue Lake")
	_check(main.dialogue_label.text.contains("左键"), "Blue Lake tells you to left-click the mirror")
	if DisplayServer.get_name() == "headless":
		main.chalk_hover_target = "Mirror"
		main._try_s03_chalk_interaction()
	else:
		await _move_mouse(main.S03_MIRROR_CENTER)
		_check(main.chalk_hover_target == "Mirror", "Chalk hovers the mirror")
		await _shot("s03_2_blue_lake")
		await _click()
	_check(main.s03_mirror_intervened, "Chalk click reveals the mirrored door")
	await _frames(2)
	await _shot("s03_3_chalk_door")

	await _walk_to_x(0.0)
	_check(main.s04_active, "walking left through the wall reaches S04")
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S03_MIRROR), "S03 completed")

	if failures.is_empty():
		print("TEST PASS: S03")
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
	var nearest: Dictionary = main._get_nearest_s03_interactable()
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
		if (action == "move_right" and x >= target) or (action == "move_left" and x <= target) or looped_back or main.s04_active:
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
