extends SceneTree

## S04 "整间展厅是一只眼睛" walkthrough with real input events (E / Space / walking / WASD inside the
## close-ups), Chalk clicks aimed directly.
##   修复台 close-up: the gaze (WASD) — the signal only shows in the corner of the eye; Chalk traces it.
##   抹核黄素 close-up: 12 drops; on the joints they make a point-light walker the visitors recognise.
##   少女: her faces change with the story. The freeze is a hyper-real insert (the painted eye).
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
	main.dialogue_needs_e = false  # tests drive the story; they don't page through dialogue
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

	await _press_action("blue_lake")
	await _frames(3)
	_check(not main.blue_lake_active, "Space before looking at 《窗》 does nothing")

	# Bright: the visitor can't see.
	await _press_e_at("Visitor")
	_check(main.closeup == "visitor" and main.dialogue_label.text.contains("太亮"), "bright: the visitor (a close-up) says it is too bright")
	await _close()

	# 修复台: the restorer only sees what is right in front of her.
	await _press_e_at("Bench")
	_check(main.closeup == "bench", "the restorer, 《星空下的神经》 and her bench are one close-up")
	await _gaze(Vector2(430, 220))
	await _press_action("interact")
	_check(not main.s04_restorer_met and main.dialogue_label.text.contains("正前方"), "touching her side: she doesn't notice")
	await _gaze(Vector2(356, 120))
	_check(main.interaction_hint_label.text == "E 说话", "the gaze right in front of her face (%s)" % main.interaction_hint_label.text)
	await _press_action("interact")
	_check(main.s04_restorer_met, "in front of her: she talks")
	await _drain_lines()
	await _shot("s04_1b_bench_closeup")
	await _gaze(Vector2(240, 340))
	await _close()

	# 《窗》, then LAN draws the curtain (in the hall).
	await _press_e_at("Window")
	_check(main.s04_window_seen and main.closeup == "window", "E 《窗》: seen, close-up")
	await _close()
	await _press_action("blue_lake")
	await _wait(1.4)
	_check(main.blue_lake_active, "Space: Blue Lake (first transform in S04)")
	await _chalk("S04Window")
	_check(main.s04_window == "mid", "Chalk on 《窗》: half-drawn (dusk)")
	await _wait(0.5)
	await _press_e_at("Visitor")
	_check(main.dialogue_label.text.contains("眼角"), "dusk: the visitor hints at the corner of the eye")
	await _close()
	await _shot("s04_2_dusk")

	# Peripheral vision inside the bench close-up: the centre of the gaze sees the signal hold still.
	await _press_e_at("Bench")
	var node1: Vector2 = main._s04_bench_node(1)
	await _gaze(node1)
	_check(main._s04_bench_signal_alpha(node1) < 0.1, "looking straight at it: the signal is invisible")
	await _gaze(node1 + Vector2(130, 0))
	_check(main._s04_bench_signal_alpha(node1) > 0.5, "looking beside it: the signal shows")
	await _shot("s04_2b_corner_of_the_eye")
	_check(main.blue_lake_active and main.chalk_cursor.visible and main.chalk_cursor.z_index > main.closeup_layer.z_index, "the chalk cursor shows above the close-up")
	main._s04_bench_chalk(main._s04_bench_node(2))
	_check(main.s04_signal_progress == 0, "tracing out of order is refused")
	for k in range(4):
		main._s04_bench_chalk(main._s04_bench_node(k))
		await _frames(1)
	_check(main.s04_signal_traced, "Chalk traces the signal in the close-up")
	_check(main.s04_starry_repaired and main.s04_has_riboflavin, "at dusk the restorer repairs it and hands over riboflavin")
	await _shot("s04_3_traced")
	await _drain_lines()
	await _gaze(Vector2(240, 340))
	await _close()

	# The girl's faces (after the repair she knows what you are here for).
	await _press_e_at("PearlHeadphones")
	_check(main.closeup == "girl", "the girl's close-up")
	for k in range(3):
		await _press_action("interact")
		await _wait(0.45)
		if k == 1:
			await _shot("s04_3b_girl_eyeroll")
	_check(main.s04_girl_face == 2 and main.chapter_state.has_event(&"s04_girl_face_eyeroll"), "three faces after the repair")
	await _close()

	# The girl walks only while it is not bright. Freeze her in the wrong place first.
	await _chalk("S04Window")
	_check(main.s04_window == "rod", "Chalk again: closed (dark)")
	await _frames(3)
	_check(main.s04_girl_out, "dark: 《戴珍珠耳机的少女》 leaves her frame")
	var x0: float = main.s04_girl_x
	await _wait(0.5)
	_check(main.s04_girl_x != x0, "she moves in the dark")
	await _press_e_at("PearlHeadphones")
	_check(main.dialogue_label.text.contains("空") or main.closeup == "girl", "her frame is empty")
	await _press_action("interact")
	_check(main.dialogue_label.text.contains("偷笑"), "an empty chair and yellow footprints; someone giggles")
	await _shot("s04_4_empty_frame")
	await _close()
	main.s04_girl_x = 650.0
	await _chalk("S04Window")
	_check(main.s04_girl_frozen and not main.s04_girl_caught, "bright too far from the restorer: frozen, not caught")
	_check(main._s01_hyper_now().size() == 2 and main._s01_hyper_now()[0] == "painted_eye", "the freeze cuts to a hyper-real painted eye")
	await _shot("s04_5_hyperreal_painted_eye")
	await _wait(1.0)
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
	await _press_e_at("PearlHeadphones")
	await _press_action("interact")
	await _wait(0.45)
	await _press_action("interact")
	_check(main.dialogue_label.text.contains("好久不见"), "caught: she cries, then sees LAN")
	await _shot("s04_6b_girl_sees_lan")
	await _wait(0.45)
	await _press_action("interact")
	_check(main.dialogue_label.text.contains("嘘"), "and asks you not to tell")
	await _wait(0.45)
	await _close()

	# The white mouse: at dusk both apples of 《双生》 show, and it comes out to gnaw them.
	await _chalk("S04Window")   # mid
	await _wait(0.5)
	_check(main.s04_mouse == "eating", "dusk: both apples show and the mouse gnaws them (%s)" % main.s04_mouse)
	await _shot("s04_6b2_mouse_apples")
	await _press_e_at("SculptureTwins")
	_check(main.closeup == "twins" and main.dialogue_label.text.contains("小白鼠"), "《双生》 close-up: a red and a green apple, and the mouse")
	await _wait(0.4)
	_check(main.interaction_hint_label.text == "E 碰碰老鼠", "E startles it (%s)" % main.interaction_hint_label.text)
	await _press_action("interact")
	_check(main.s04_mouse == "fleeing", "startled, it runs for the bench")
	await _wait(0.6)
	_check(main.closeup == "", "the close-up puts itself away to show it run")
	await _wait(2.2)
	_check(main.s04_mouse == "bottle" and main.dialogue_label.text.contains("尾巴"), "it dives into the riboflavin bottle; its tail sticks out")
	await _chalk("S04Window")   # rod
	await _chalk("S04Window")   # cone

	# Riboflavin: Graham dabs it on herself. On the joints it moves the way she walks.
	await _press_action("blue_lake")
	await _frames(2)
	_check(not main.blue_lake_active, "Space: Blue Lake put away")
	await _press_e_at("Bench")
	await _gaze(Vector2(500, 286))
	_check(main.interaction_hint_label.text == "E 揪住尾巴", "the tail out of the bottle (%s)" % main.interaction_hint_label.text)
	await _press_action("interact")
	_check(main.closeup_anim == "tail", "E pulls it out by the tail")
	await _wait(1.3)
	await _shot("s04_6b3_mouse_joints")
	await _wait(1.2)
	_check(main.s04_mouse == "running" and main.dialogue_label.text.contains("关节"), "it shakes the paint off except in its joints, and runs off to the visitors")
	_check(main.interaction_hint_label.text == "E 拿起核黄素", "the bottle on the bench (%s)" % main.interaction_hint_label.text)
	await _press_action("interact")
	_check(main.closeup == "smear", "the riboflavin close-up: Graham's front")
	await _wait(0.4)
	_check(main.S04_DROPS == 4, "four drops of riboflavin: hands and feet, like the mouse")
	# A drop near a joint settles on it.
	main.closeup_hand = (main.S04_JOINTS[4] as Vector2) + Vector2(14, -10)
	await _press_action("interact")
	_check(main.s04_dabs[0] == main.S04_JOINTS[4], "a drop near a wrist lands on the wrist")
	for k in [5, 10]:
		main.closeup_hand = main.S04_JOINTS[k]
		await _press_action("interact")
	await _shot("s04_6c_dabs")
	main.closeup_hand = main.S04_JOINTS[11]
	await _press_action("interact")
	_check(main.s04_riboflavin_applied and main._s04_joint_hits() == 4, "four drops, on both hands and both feet (%d)" % main._s04_joint_hits())
	await _wait(0.5)
	_check(main.closeup == "", "the close-up closes after the last drop")
	await _press_e_at("Bench")
	await _gaze(Vector2(556, 290))
	await _press_action("interact")
	_check(main.s04_uv_on, "the ultraviolet lamp on")
	await _frames(3)
	_check(main.chapter_state.has_story_event(&"hyperreal_fluor"), "a hyper-real insert: riboflavin glowing on skin")
	await _shot("s04_6d_hyperreal_fluor")
	await _wait(1.0)
	await _gaze(Vector2(240, 340))
	await _close()
	await _press_e_at("Window")
	_check(main.chapter_state.has_event(&"s04_blue_handprint_seen") and main.dialogue_label.text.contains("那是我的"), "bright + UV: LAN's blue handprint in the blind spot")
	await _shot("s04_6e_window_uv")
	await _wait(0.4)
	_check(main.interaction_hint_label.text == "E 装上画框", "then the frame (%s)" % main.interaction_hint_label.text)
	await _press_action("interact")
	_check(main.s04_frame_installed, "E in 《窗》's close-up: frame installed")
	await _close()
	await _press_action("blue_lake")
	await _frames(2)
	await _chalk("S04Window")   # mid
	await _chalk("S04Window")   # rod
	await _press_action("blue_lake")
	await _wait(0.6)
	_check(main.s04_win_t > 0.9 and main._s04_point_light_on(), "dark + UV: Graham is a point-light walker")
	_check(main.s04_mouse == "pacing" and main.s04_mouse_seen, "in the dark the visitors see the mouse's dots run, and know it for a mouse")

	# The visitors see only movement: standing still in front of them does nothing.
	await _press_e_at("VisitorGroup")
	_check(not main.s04_visitors_recognized and main.dialogue_label.text.contains("停下来"), "standing still: not recognised")
	await _close()
	main.player.position.x = 880.0
	Input.action_press("move_right")
	await _wait(0.4)
	await _shot("s04_7_point_light_walker")
	Input.action_release("move_right")
	await _frames(2)
	_check(main.s04_visitors_recognized, "walking past them, the joints glowing: recognised by her gait")
	await _drain_lines()

	# 《窗》 under ultraviolet: the painted-out handle; then the frame goes back on.
	await _press_e_at("Window")
	_check(main.s04_handle_found and main.closeup == "window", "E 《窗》 under UV: the handle she painted out")
	await _shot("s04_8_frame_handle")
	await _wait(S04_wait())
	_check(main.s05_active, "S04 completes -> S05")
	_check(main.closeup == "" and main.player.modulate.a == 1.0, "leaving S04 puts the close-up away and Graham back to normal")
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

## Move the gaze (or the brush) in a big close-up with WASD.
func _gaze(target: Vector2) -> void:
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

func _close() -> void:
	await _wait(0.35)
	await _drain_lines()
	await _press_action("interact")
	await _wait(0.45)
	_check(main.closeup == "", "close-up closed (%s)" % main.closeup)

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

func _wait(t: float) -> void:
	await create_timer(t).timeout

func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png(SHOT_DIR + "/" + shot_name + ".png")
