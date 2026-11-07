extends SceneTree

## S03 walkthrough with real input, in the dark 表与里 hall:
## fix the picture lamp over 《那喀索斯》 and turn it until the water reflects into the prism (Venus's eye lights);
## Space + Chalk on her eye borrows her view (the guard's and the bonsai's hands fit her shoulders);
## E the guard: the glove comes off and he brings the marble arm; stand at the entrance so the reflection (Blue Lake)
## stands at the far door and rides the belt through the 里 side, pushing the bonsai onto the belt (E);
## in the warm light the rust leaves fall; Graham fits both arms; Venus holds the mirror;
## stand at the entrance so the reflection stands at the far door, E the door, leave right into S04.
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
	# Arrive in S03 the way S02 hands off: same hall, still dark, near the guard.
	main.s01_gate_open = true
	main.gate_body.collision_layer = 0
	main.s01_active = false
	main.s01_exit_route = "past"
	main.chapter_state.complete_slice(ChapterState.Slice.S01_ENTER)
	main.chapter_state.complete_slice(ChapterState.Slice.S02_LOST)
	main.player.position.x = 190.0
	main._enter_s03_after_s02()
	await _frames(2)
	_check(main.s03_active, "S03 is active")
	_check(main._s02_darkness() > 0.5, "the hall is dark")
	await _shot("s03_1_dark")

	# Space does nothing useful in the dark.
	await _press("blue_lake")
	await _frames(2)
	_check(not main.blue_lake_active, "no Blue Lake before there is light")
	_check(main.dialogue_label.text.contains("光"), "Blue Lake asks for light")

	# The belt still runs: Graham cannot cross the axis.
	await _hold("move_right", 200)
	_check(main.player.position.x < main.S02_BELT_FULL, "the belt still holds Graham back (x=%d)" % main.player.position.x)

	# 《那喀索斯》 and its picture lamp are one big close-up: the hand on the lamp, E fixes it, then turns it.
	await _walk_to_x(315.0)
	await _press_e_expecting("Narcissus")
	_check(main.closeup == "narcissus", "the 《那喀索斯》 close-up")
	await _hand_to(main._narc_map(main.S03_PICTURE_LAMP))
	await _press("interact")
	_check(main.s03_lamp_fixed, "E fixes the picture lamp")
	_check(not main.s03_eye_lit, "fixing alone does not light the eye")
	await _press("interact")
	await _shot("s03_2_lamp_wrong_angle")
	_check(not main.s03_eye_lit, "a wrong angle misses the prism")
	await _press("interact")
	_check(not main.s03_eye_lit, "another wrong angle misses the prism")
	await _press("interact")
	_check(main.s03_eye_lit, "the right angle reflects off the water into the prism")
	await _shot("s03_2b_lamp_right_angle_closeup")
	await _hand_to(Vector2(300, 200))
	await _close()
	var end: Vector2 = main._s03_reflection_end(main.S03_LAMP_GOOD)
	_check(absf(end.x - main.S02_AXIS_X) <= main.S02_LIGHT_HALF, "the good reflection really reaches the prism (x=%d)" % end.x)
	for i in range(main.S03_LAMP_GOOD):
		var miss: Vector2 = main._s03_reflection_end(i)
		_check(absf(miss.x - main.S02_AXIS_X) > main.S02_LIGHT_HALF, "angle %d really misses (x=%d)" % [i, miss.x])
	_check(main.dialogue_label.text.contains("Space") and main.space_prompt_visible, "right away, Blue Lake says to press Space")
	await create_timer(1.0).timeout
	_check(not main.s03_busy, "no long wait after the eye lights up")
	await _walk_to_x(main.S02_AXIS_X)
	await _press_e_expecting("SculptureVenus")
	_check(main.dialogue_label.text.contains("Space") and main.space_prompt_visible, "E Venus (eye lit): Blue Lake reminds Space")
	await _shot("s03_3_eye_lit")

	await _press("blue_lake")
	for i in range(80):
		await create_timer(0.1).timeout
		if main.blue_lake_active:
			break
	await _frames(2)
	_check(main.blue_lake_active, "Space enters Blue Lake once the eye is lit")
	await _shot("s03_4_blue_lake_layer")
	if DisplayServer.get_name() == "headless":
		main.chalk_hover_target = "VenusEye"
		main._try_s03_chalk_interaction()
	else:
		await _move_mouse(main.S02_EYE)
		_check(main.chalk_hover_target == "VenusEye", "Chalk hovers Venus's eye")
		await _click()
	_check(main.s03_pov_active, "Chalk on her eye borrows Venus's view")
	_check(not main.player.visible, "Graham's sprite is hidden inside Venus's view")
	await create_timer(3.3).timeout
	_check(main.s03_hands_seen, "in her view the hands fit her shoulders")
	await _shot("s03_5_venus_pov")
	# Clicking advances the overheard conversation.
	for i in range(main.S03_POV_LINES.size()):
		main._try_s03_chalk_interaction()
		await _frames(1)
	_check(main.dialogue_label.text.contains("Space"), "after the conversation Blue Lake says to put it away")
	await _press("blue_lake")
	await _frames(2)
	_check(not main.blue_lake_active and not main.s03_pov_active, "Space leaves Blue Lake and her view")
	_check(main.player.visible, "Graham is visible again after her view")

	await _walk_to_x(main.S02_GUARD_X)
	await _press_e_expecting("SecurityGuard")
	await create_timer(0.4).timeout
	_check(main.closeup == "guard" and main.interaction_hint_label.text == "E 那不是你的手吧", "in the guard's close-up (%s)" % main.interaction_hint_label.text)
	await _press("interact")
	await create_timer(0.9).timeout
	_check(main._s01_hyper_now().size() == 2 and main._s01_hyper_now()[0] == "marble", "a hyper-real insert: the marble hand in his sweaty fingers")
	await _shot("s03_6_hyperreal_marble")
	await create_timer(1.3).timeout
	_check(main.s03_glove_off, "the glove comes off")
	await _shot("s03_6b_glove")
	for i in range(100):
		await create_timer(0.1).timeout
		if main.s03_left_arm_ready and not main.s03_busy:
			break
	_check(main.s03_left_arm_ready, "the guard brings the marble arm to Venus")
	_check(not main.s03_left_installed, "but Graham fits it herself")

	# Stand still at the entrance: the reflection at the far door is Blue Lake, and the belt carries it.
	await _walk_to_x(main.S02_DOOR_RECT.get_center().x)
	# First ride: let the bonsai go by. Blue Lake stops in the middle and can try again.
	for i in range(100):
		await create_timer(0.1).timeout
		if main.s03_ride_active:
			break
	_check(main.s03_ride_active, "first ride starts")
	for i in range(200):
		await create_timer(0.1).timeout
		if not main.s03_ride_active:
			break
	_check(not main.s03_pot_on_belt and not main.s03_ride_done, "missing the bonsai leaves it in place")
	_check(main.dialogue_label.text.contains("再"), "Blue Lake offers to try again")
	_check(not main.player.input_locked, "Graham can move again after the ride")
	for i in range(100):
		await create_timer(0.1).timeout
		if main.s03_ride_active:
			break
	_check(main.s03_ride_active, "standing at the entrance sends Blue Lake riding through the 里 side")
	_check(absf(main.s03_ride_x - main._s02_mx(main.S02_DOOR_RECT.get_center().x)) < 40.0, "the ride starts at the far door")
	await _press("interact")
	_check(main.dialogue_label.text.contains("格雷汉"), "the far door carries an inventory tag with Graham's name")
	_check(main.closeup == "lan_tag", "LAN sees it up close, in the blue-lake layer")
	var x_before: float = main.s03_ride_x
	await create_timer(0.5).timeout
	await _shot("s03_7_lan_tag_closeup")
	_check(absf(main.s03_ride_x - x_before) < 0.5, "the ride waits while LAN looks")
	await _close()
	for i in range(100):
		await create_timer(0.05).timeout
		if absf(main.s03_ride_x - main.s03_pot_x) < 20.0:
			break
	await _press("interact")
	_check(main.s03_pot_on_belt, "E as Blue Lake passes pushes the bonsai onto the belt")
	await _shot("s03_8_pot_pushed")
	for i in range(200):
		await create_timer(0.1).timeout
		if not main.s03_ride_active:
			break
	_check(not main.s03_ride_active and main.s03_ride_done, "the ride ends in the middle; Blue Lake cannot leave by the far door")
	for i in range(100):
		await create_timer(0.1).timeout
		if main.s03_leaves_fallen:
			break
	_check(main.s03_leaves_fallen and main.s03_right_arm_ready, "in the warm light the rust leaves fall and free the iron arm")
	_check(absf(main.s03_pot_x - main.S03_POT_STOP) < 1.0, "the chain stops the pot in the warm light")
	await _shot("s03_9_leaves_fallen")

	# Venus's close-up: LAN's chalk drags each arm onto its shoulder; then E tries poses.
	await _walk_to_x(538.0)
	await _press_e_expecting("SculptureVenus")
	_check(main.closeup == "venus" and main._venus_arm_waiting(), "Venus's close-up, arms waiting")
	await create_timer(0.4).timeout
	await _press("blue_lake")
	_check(main.blue_lake_active, "Space brings out LAN's chalk inside the close-up")
	await _drag_arm("left", "right")
	_check(not main.s03_left_installed and main.dialogue_label.text.contains("接不上"), "marble does not fit the rusted side")
	await _drag_arm("left", "left")
	_check(main.s03_left_installed, "the marble arm on her marble shoulder")
	await _shot("s03_9b_marble_arm_on")
	await _drag_arm("right", "right")
	_check(main.s03_right_installed and main.s03_arms_returned, "the iron arm on her rusted shoulder")
	_check(not main.blue_lake_active, "the chalk is put away once both are on")
	for k in range(4):
		await _press("interact")
		await create_timer(0.7).timeout
		if k == 1:
			await _shot("s03_9c_venus_peace_sign")
	_check(not main.s03_mirror_held and main.venus_pose == 3, "four poses that are not it")
	await _press("interact")
	_check(main.closeup_anim == "mirror_pose", "the fifth: palms together")
	await create_timer(1.9).timeout
	await _shot("s03_9d_mirror_between_her_palms")
	await create_timer(0.8).timeout
	_check(main.s03_mirror_held, "the mirror's edge appears between her palms")
	await _close()
	_check(main.dialogue_label.text.contains("房间亮了"), "out of the close-up: the room is lit")
	await _shot("s03_10_mirror_held")

	# Not at the door yet: the reflection is not at the far door.
	await _walk_to_x(300.0)
	await _walk_to_x(main.S02_DOOR_RECT.get_center().x)
	await _shot("s03_11_reflection_at_door")
	await _press_e_expecting("HallDoor")
	await create_timer(1.9).timeout
	_check(main.s03_crossed, "E the door with the reflection at the far door: Graham trades places")
	_check(main.player.position.x > 900.0, "Graham now stands at the far door (x=%d)" % main.player.position.x)
	_check(main.player.push_x == 0.0, "the belt has stopped")
	await _shot("s03_12_crossed")
	await _walk_to_x(1050.0)
	_check(main.s04_active, "leaving by the far door reaches S04")
	_check(main.player.position.x < 200.0, "S04 is entered from the left (x=%d)" % main.player.position.x)
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S03_MIRROR), "S03 completed")
	await _shot("s03_13_s04_left")

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

## Drag an arm with LAN's chalk (mouse press on the arm, release on a shoulder) in Venus's close-up.
func _drag_arm(arm: String, onto: String) -> void:
	if DisplayServer.get_name() == "headless":
		# Headless has no real pointer to push events through; drive the same two steps directly.
		main._venus_grab(main.VENUS_ARM_REST[arm])
		await _frames(1)
		main._venus_drop(main.VENUS_SHOULDER[onto])
		await _frames(2)
		return
	var origin: Vector2 = main.CLOSEUP_RECTS["venus"].position
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = origin + main.VENUS_ARM_REST[arm]
	down.global_position = down.position
	down.pressed = true
	root.push_input(down)
	await _frames(2)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = origin + main.VENUS_SHOULDER[onto]
	up.global_position = up.position
	up.pressed = false
	root.push_input(up)
	await _frames(2)

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
