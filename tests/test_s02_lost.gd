extends SceneTree

## S02 "表与里" (dark) walkthrough with real input:
## E the door (both S01 routes), the guard, 《那喀索斯》, 《光》, 《机械维纳斯》;
## walk right until the belt holds Graham in place at the axis; let it carry her back;
## stand still for Blue Lake's figure; then E the guard again to complete S02.
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
	main.dialogue_needs_e = false  # tests drive the story; they don't page through dialogue
	root.add_child(main)
	await _frames(5)
	# Arrive in S02 the way S01 hands off (future route first, to check the swapped doors).
	main.s01_gate_open = true
	main.gate_body.collision_layer = 0
	main.s01_completion_started = true
	main.s01_exit_route = "future"
	main.chapter_state.complete_slice(ChapterState.Slice.S01_ENTER)
	main._enter_s02_after_s01()
	await _frames(2)
	_check(main.s02_active, "S02 is active")
	_check(absf(main.player.position.x - 120.0) < 1.0, "S02 starts at the hall entrance on the left")
	await _press_e_expecting("HallDoor")
	_check(main.dialogue_label.text.contains("锈穿"), "future route: the entrance is the rusted-through door")
	await _shot("s02_0_future_doors")
	main.s01_exit_route = "past"
	await _press_e_expecting("HallDoor")
	_check(main.dialogue_label.text.contains("出口") and not main.dialogue_label.text.contains("锈穿"), "past route: the entrance is the wooden door")
	await _shot("s02_1_enter")

	await _walk_to_x(main.S02_GUARD_X)
	await _press_e_expecting("SecurityGuard")
	_check(main.s02_guard_asked, "the guard was asked")
	_check(main.dialogue_label.text.contains("出口在对面"), "the guard points across")
	_check(not main.s02_completion_started, "asking the guard alone does not complete S02")
	_check(main.closeup == "guard", "the guard is a close-up")
	await _shot("s02_1b_guard_closeup")
	await _close()

	await _walk_to_x(330.0)
	await _press_e_expecting("Narcissus")
	_check(main.closeup == "narcissus" and main.dialogue_label.text.contains("水"), "《那喀索斯》 (with its lamp) is one big close-up; water in the dark")
	await _hand_to(Vector2(300, 352))
	_check(main.interaction_hint_label.text.contains("E 碰一碰"), "the hand is over the water (%s)" % main.interaction_hint_label.text)
	await _press("interact")
	_check(main.closeup_anim == "ripple" and main.s02_ripple_left > 0.0 and main.dialogue_label.text.contains("凉"), "the real water can be disturbed")
	await create_timer(0.5).timeout
	await _shot("s02_1c_ripple")
	await create_timer(1.1).timeout
	await _hand_to(Vector2(300, 200))
	await _close()
	_check(main.s02_ripple_left > 0.0, "back in the hall the water is still rippling")
	await _walk_to_x(535.0)
	await _press_e_expecting("SculptureVenus")
	_check(main.closeup == "venus" and main.dialogue_label.text.contains("轮廓"), "Venus and 《光》 are one close-up; in the dark only an outline")
	await _shot("s02_2_venus_light")
	await _close()

	_check(main._s02_belt_pull(500.0) == 0.0 and main._s02_belt_pull(main.S02_AXIS_X) == 0.0, "no belt at 《光》 or Venus: they can be looked at in peace")
	# Keep walking right: the belt matches her pace at the axis.
	var max_x := 0.0
	Input.action_press("move_right")
	for i in range(240):
		await physics_frame
		max_x = maxf(max_x, main.player.position.x)
	await _shot("s02_3_stalled")
	Input.action_release("move_right")
	_check(main.s02_belt_stalled, "walking right stalls on the belt")
	_check(max_x > main.S02_AXIS_X and max_x < main.S02_BELT_FULL, "she gets a little past the middle, then the belt holds her (max x=%d)" % max_x)

	# Standing still, the belt carries her back to the door.
	for i in range(900):
		await physics_frame
		if main.s02_carried_back:
			break
	_check(main.s02_carried_back, "the belt carried Graham back (x=%d)" % main.player.position.x)
	_check(main.player.position.x <= main.S02_BELT_START + 13.0, "she ends up back on the still carpet (x=%d)" % main.player.position.x)

	# Easter egg: step back onto the 表 side, stand still, and Blue Lake's figure develops on the 里 side.
	await _walk_to_x(450.0)
	for i in range(900):
		await physics_frame
		if main.s02_figure_alpha > 0.7:
			break
	_check(main.s02_figure_alpha > 0.7, "Blue Lake's figure appears (alpha=%.2f)" % main.s02_figure_alpha)
	await _shot("s02_4_blue_lake_figure")
	await _hold("move_right", 20)
	await _frames(30)
	_check(main.s02_figure_alpha < 0.3, "the figure fades when Graham moves (alpha=%.2f)" % main.s02_figure_alpha)

	await _walk_to_x(main.S02_GUARD_X)
	await _press_e_expecting("SecurityGuard")
	_check(main.dialogue_label.text.contains("一个姿势"), "the guard and the bonsai share a pose")
	await _shot("s02_5_counterpart")
	await create_timer(6.0).timeout
	_check(main.chapter_state.has_event(&"s02_counterpart_noticed"), "counterpart event recorded")
	_check(main.chapter_state.has_event(&"s02_space_loop_recognized"), "S02 knowledge recorded")
	_check(main.s03_active, "S02 completes and starts S03")
	_check(main._s02_darkness() > 0.5, "the hall is still dark going into S03")

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

func _close() -> void:
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
