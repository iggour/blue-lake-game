extends SceneTree

## The picture lamp over 《那喀索斯》 works the first time it is found, even before the belt has stopped
## Graham (S03 starts right there). If it is not found, LAN points at it after a while in S03.
##
## Headless:      "$G" --headless --path . --script tests/test_s02_lamp_first.gd

const MainScene := preload("res://scenes/main/prototype_01.tscn")
const SHOT_DIR := "res://.artifacts/screenshots"

var main: Node2D
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _start_s02() -> void:
	main = MainScene.instantiate()
	root.add_child(main)
	await _frames(5)
	main.s01_gate_open = true
	main.gate_body.collision_layer = 0
	main.s01_completion_started = true
	main.s01_exit_route = "past"
	main.chapter_state.complete_slice(ChapterState.Slice.S01_ENTER)
	main._enter_s02_after_s01()
	await _frames(2)

func _run() -> void:
	await _start_s02()
	await _walk_to_x(330.0)
	await _press_e_expecting("Narcissus")
	await create_timer(0.4).timeout
	await _hand_to(main._narc_map(main.S03_PICTURE_LAMP))
	_check(main.interaction_hint_label.text.contains("E 碰一碰"), "the hand on the lamp (%s)" % main.interaction_hint_label.text)
	await _press("interact")
	_check(main.s03_active and main.s03_lamp_fixed, "found first, the lamp is fixed at once (S03 starts)")
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S02_LOST), "S02 counts as done")
	_check(main.dialogue_label.text.contains("灯亮了"), "the lamp comes on")
	await _press("interact")
	_check(main.s03_lamp_angle == 1, "E again turns it, still in the close-up")
	await _close()
	main.queue_free()
	await _frames(2)

	# Not found: S03 the usual way; after a while LAN points at the lamp.
	await _start_s02()
	main.s02_completion_started = true
	main.chapter_state.complete_slice(ChapterState.Slice.S02_LOST)
	main._enter_s03_after_s02()
	await create_timer(main.S03_LAMP_HINT_AFTER + 0.5).timeout
	_check(main.dialogue_label.text.contains("画灯"), "LAN points at the picture lamp (%s)" % main.dialogue_label.text)
	_check(not main.s03_lamp_fixed, "the hint does not fix it")
	if failures.is_empty():
		print("TEST PASS: S02 lamp found first")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _press_e_expecting(item_name: String) -> void:
	var nearest: Dictionary = main._get_nearest_s02_interactable()
	_check(nearest.get("name", "") == item_name, "at x=%d E targets %s, expected %s" % [main.player.position.x, nearest.get("name", "<nothing>"), item_name])
	_check(main.interaction_hint_label.visible, "E hint visible at %s" % item_name)
	await _press("interact")

func _close() -> void:
	# In a big close-up E acts on what is under the hand: move it off first.
	if main.closeup == "cleaner":
		await _hand_to(Vector2(380, 40))
	elif main.closeup == "narcissus":
		await _hand_to(Vector2(300, 200))
	await create_timer(0.35).timeout
	await _press("interact")
	await create_timer(0.45).timeout
	_check(main.closeup == "", "close-up closed")

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
	await process_frame

func _hold_if(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _walk_to_x(target: float) -> void:
	var action := "move_right" if target > main.player.position.x else "move_left"
	Input.action_press(action)
	for i in range(900):
		await physics_frame
		var x: float = main.player.position.x
		if (action == "move_right" and x >= target) or (action == "move_left" and x <= target) or main.s03_active:
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
