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
	_check(main.player.position.x < main.S02_AXIS_X + 4.0, "the belt still holds Graham back (x=%d)" % main.player.position.x)

	await _walk_to_x(main.S03_PICTURE_LAMP.x)
	await _press_e_expecting("PictureLamp")
	_check(main.s03_lamp_fixed, "E fixes the picture lamp")
	_check(not main.s03_eye_lit, "fixing alone does not light the eye")
	await _press_e_expecting("PictureLamp")
	await _shot("s03_2_lamp_wrong_angle")
	_check(not main.s03_eye_lit, "a wrong angle misses the prism")
	await _press_e_expecting("PictureLamp")
	_check(not main.s03_eye_lit, "another wrong angle misses the prism")
	await _press_e_expecting("PictureLamp")
	_check(main.s03_eye_lit, "the right angle reflects off the water into the prism")
	var end: Vector2 = main._s03_reflection_end(main.S03_LAMP_GOOD)
	_check(absf(end.x - main.S02_AXIS_X) <= main.S02_LIGHT_HALF, "the good reflection really reaches the prism (x=%d)" % end.x)
	for i in range(main.S03_LAMP_GOOD):
		var miss: Vector2 = main._s03_reflection_end(i)
		_check(absf(miss.x - main.S02_AXIS_X) > main.S02_LIGHT_HALF, "angle %d really misses (x=%d)" % [i, miss.x])
	await create_timer(3.2).timeout
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
	_check(main.s03_glove_off, "the glove comes off")
	await _shot("s03_6_glove")
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
	await _shot("s03_7_ride_start")
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

	await _walk_to_x(538.0)
	await _press_e_expecting("SculptureVenus")
	_check(main.s03_left_installed and main.s03_right_installed, "Graham fits both arms in the middle")
	for i in range(100):
		await create_timer(0.1).timeout
		if main.s03_mirror_held and not main.s03_busy:
			break
	_check(main.s03_mirror_held, "Venus holds the mirror")
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
