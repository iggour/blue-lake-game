extends SceneTree

## S04 "整间展厅是一只眼睛" walkthrough with real input events (E / Space / walking), Chalk clicks
## aimed directly when headless.
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

	# Arrive in S04 the way S03 hands off.
	main.s01_active = false
	main.s01_gate_open = true
	main.gate_body.collision_layer = 0
	main.west_exit_body.collision_layer = 0
	main.chapter_state.complete_slice(ChapterState.Slice.S03_MIRROR)
	main._enter_s04_after_s03()
	await _frames(2)
	_check(main.s04_active, "S04 is active")
	_check(main.player.position.x < 200.0, "Graham arrives at the left wall (x=%d)" % main.player.position.x)
	_check(main.s04_window == "cone" and main.s04_win_t == 0.0, "the room starts bright (cone window)")
	await _shot("s04_1_enter_bright")

	# Space does nothing before 《窗》 has been looked at.
	await _press_action("blue_lake")
	await _frames(3)
	_check(not main.blue_lake_active, "Space before looking at 《窗》 does nothing")

	# Bright: the visitor can't see; the restorer only sees what is right in front of her.
	await _press_e_at("Visitor")
	_check(main.dialogue_label.text.contains("太亮"), "bright: the visitor says it is too bright")
	await _press_e_at("RestorerSide")
	_check(not main.s04_restorer_met and main.dialogue_label.text.contains("正前方"), "beside the restorer: she doesn't notice Graham")
	await _press_e_at("Restorer")
	_check(main.s04_restorer_met, "in front of the restorer: she talks")
	await _drain_lines()

	# 《窗》, then Blue Lake draws the curtain.
	await _press_e_at("Window")
	_check(main.s04_window_seen, "E 《窗》: seen")
	await _press_action("blue_lake")
	await _wait(1.4)
	_check(main.blue_lake_active, "Space: Blue Lake (first transform in S04)")
	await _chalk("S04Window")
	_check(main.s04_window == "mid", "Chalk on 《窗》: half-drawn (dusk)")
	await _wait(0.5)
	_check(absf(main.s04_win_t - 0.5) < 0.01, "the room eases to the dusk window")
	await _press_e_at("Visitor")
	_check(main.dialogue_label.text.contains("眼角"), "dusk: the visitor hints at the corner of the eye")
	await _shot("s04_2_dusk")

	# Peripheral vision: looking straight at the painting shows nothing, from the side the signal shows.
	main.player.position.x = main.S04_STARRY_CENTER.x
	await _frames(2)
	_check(main._s04_signal_alpha() < 0.1, "straight in front of 《星空下的神经》 the signal is invisible")
	main.player.position.x = main.S04_RESTORER_FRONT
	await _frames(2)
	_check(main._s04_signal_alpha() > 0.5, "from the side (in front of the restorer) the signal shows")
	await _chalk("Signal2")
	_check(main.s04_signal_progress == 0, "tracing out of order is refused")
	for k in range(4):
		await _chalk("Signal%d" % k)
	_check(main.s04_signal_traced, "Chalk traces the signal")
	_check(main.s04_starry_repaired and main.s04_has_riboflavin, "at dusk the restorer repairs it and hands over riboflavin")
	await _shot("s04_3_traced")
	await _drain_lines()

	# The girl: she walks only while it is not bright. Freeze her in the wrong place first.
	await _chalk("S04Window")
	_check(main.s04_window == "rod", "Chalk again: closed (dark)")
	await _frames(3)
	_check(main.s04_girl_out, "dark: 《戴珍珠耳机的少女》 leaves her frame")
	var x0: float = main.s04_girl_x
	await _wait(0.5)
	_check(main.s04_girl_x != x0, "she moves in the dark")
	await _shot("s04_4_dark_girl")
	main.s04_girl_x = 650.0
	await _chalk("S04Window")
	_check(main.s04_girl_frozen and not main.s04_girl_caught, "bright too far from the restorer: frozen, not caught")
	await _shot("s04_5_frozen_wrong_place")
	var xf: float = main.s04_girl_x
	await _wait(0.3)
	_check(main.s04_girl_x == xf, "frozen while bright")
	await _chalk("S04Window")   # mid
	await _chalk("S04Window")   # rod
	main.s04_girl_x = main.S04_RESTORER_FRONT + 10.0
	await _chalk("S04Window")   # cone: caught right in front of her
	_check(main.s04_girl_caught, "bright with her in front of the restorer: caught")
	await _shot("s04_6_caught")
	await _drain_lines()
	_check(not main.s04_girl_out, "she goes back into her frame")

	# Riboflavin on Graham, ultraviolet on.
	await _press_action("blue_lake")
	await _frames(2)
	_check(not main.blue_lake_active, "Space: Blue Lake put away")
	await _press_e_at("Workbench")
	_check(main.s04_riboflavin_applied, "E bench: riboflavin applied")
	await _press_e_at("Workbench")
	_check(main.s04_uv_on, "E bench: ultraviolet on")
	await _press_e_at("Window")
	_check(main.chapter_state.has_event(&"s04_blue_handprint_seen"), "bright + UV: E 《窗》 shows the blue handprint in the blind spot")
	await _press_action("blue_lake")
	await _frames(2)
	await _chalk("S04Window")   # mid
	await _chalk("S04Window")   # rod
	await _press_action("blue_lake")
	await _wait(0.6)
	_check(main.s04_win_t > 0.9, "dark again")

	# The visitors see only movement: standing still in front of them does nothing.
	await _press_e_at("VisitorGroup")
	_check(not main.s04_visitors_recognized and main.dialogue_label.text.contains("停下来"), "standing still: not recognised")
	main.player.position.x = 880.0
	Input.action_press("move_right")
	await _wait(0.4)
	Input.action_release("move_right")
	await _frames(2)
	_check(main.s04_visitors_recognized, "walking past them, glowing: recognised by her gait")
	await _shot("s04_7_recognised")
	await _drain_lines()

	# 《窗》 under ultraviolet: the painted-out handle; then the frame goes back on.
	await _press_e_at("Window")
	_check(main.s04_handle_found, "E 《窗》 under UV: the handle she painted out")
	await _press_e_at("Window")
	_check(main.s04_frame_installed, "E 《窗》: frame installed")
	await _shot("s04_8_frame_handle")
	await _wait(S04_wait())
	_check(main.s05_active, "S04 completes -> S05")
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S04_VISITOR), "S04 marked complete")

	if failures.is_empty():
		print("TEST PASS: S04")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func S04_wait() -> float:
	return main.S04_LINE_TIME + 0.5

func _chalk(target: String) -> void:
	# Aim the Chalk the way _update_chalk_hover would, then click.
	main.chalk_hover_target = target
	main._try_s04_chalk_interaction()
	await _frames(2)

func _drain_lines() -> void:
	var guard := 0
	while not main.s04_lines.is_empty() and guard < 20:
		await _press_action("interact")
		guard += 1

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

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _frames(3)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png(SHOT_DIR + "/" + shot_name + ".png")
