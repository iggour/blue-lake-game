extends SceneTree

## S02 walkthrough with real input: E at every exhibit, the guard and the dead end,
## then walk right twice and get looped back to the entrance; the second loop completes S02.
##
## Headless:      "$G" --headless --path . --script tests/test_s02_lost.gd
## With a window: "$G" --path . --script tests/test_s02_lost.gd   (screenshots -> .artifacts/screenshots/)

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
	# Arrive in S02 the way S01 hands off.
	main.s01_gate_open = true
	main.gate_body.collision_layer = 0
	main.s01_completion_started = true
	main.chapter_state.complete_slice(ChapterState.Slice.S01_ENTER)
	main._enter_s02_after_s01()
	await _frames(2)
	_check(main.s02_active, "S02 is active")
	_check(absf(main.player.position.x - 120.0) < 1.0, "S02 starts at the hall entrance on the left")
	await _shot("s02_1_enter")

	for item_name in ["PearlHeadphones", "StarryNerves", "MirrorInMirror"]:
		await _walk_to_x(_item(item_name).position.x)
		await _press_e_expecting(item_name)
	for item_name in ["SculptureGaze", "SculptureVenus", "SculptureTwins", "SculptureLight", "SculptureBlind"]:
		await _walk_to_x(_item(item_name).position.x)
		await _press_e_expecting(item_name)
	await _shot("s02_2_sculptures")
	# Before the guard has spoken, the dead end can be reached and read.
	await _walk_to_x(983.0)
	_check(main.s02_loop_count == 0, "no loop before the guard has been asked")
	await _press_e_expecting("DeadEnd")
	await _shot("s02_3_dead_end")

	await _walk_to_x(545.0)
	await _press_e_expecting("SecurityGuard")
	await _walk_to_x(1000.0)
	_check(main.s02_loop_count == 1, "first walk right loops back once (count=%d)" % main.s02_loop_count)
	_check(main.player.position.x < 200.0, "looped back to the entrance (x=%d)" % main.player.position.x)
	await _shot("s02_4_loop")
	await create_timer(0.9).timeout
	await _walk_to_x(1000.0)
	_check(main.s03_active, "second loop completes S02 and starts S03")

	if failures.is_empty():
		print("TEST PASS: S02")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _item(item_name: String) -> Dictionary:
	for item in main.s02_interactables:
		if item.name == item_name:
			return item
	return {}

func _press_e_expecting(item_name: String) -> void:
	var nearest: Dictionary = main._get_nearest_s02_interactable()
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
		if (action == "move_right" and x >= target) or (action == "move_left" and x <= target) or looped_back or main.s03_active:
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
