extends SceneTree

## S01, the past route with real input, through the close-ups (特写):
## the photo starts in winter → turning the left clock-eye back makes 《观看的永恒》 warm (opening day)
## → in the opening-day photo the blue-eyed girl hands Graham her chalk out of the frame
## → on the map, the red "你在这里" dot walks the sulci and the chalk line becomes a key
## → the key opens the door (the door swings toward the viewer) → E at the open door enters S02.
##
## Headless:      "$G" --headless --path . --script tests/test_s01_enter.gd
## With a window: "$G" --path . --script tests/test_s01_enter.gd   (screenshots -> .artifacts/screenshots/)

const MainScene := preload("res://scenes/main/prototype_01.tscn")
const SHOT_DIR := "res://.artifacts/screenshots"

var main: Node2D
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _finish(label: String) -> void:
	if failures.is_empty():
		print("TEST PASS: " + label)
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _run() -> void:
	main = MainScene.instantiate()
	root.add_child(main)
	await _frames(5)
	_check(main.s01_active and main.s01_era == 1, "S01 starts with the photo in winter")
	_check(main.s01_maze_path.size() == 1 and main.s01_maze_path[0] == main.S01_MAZE_START, "the chalk line starts at 你在这里")
	await _shot("s01_1_start")

	await _hold("move_up", 60)
	_check(main.player.position.y >= 409.0, "cannot walk up onto the wall (y=%s)" % main.player.position.y)

	# The door: a close-up, locked. E puts it away.
	await _walk_to_x(720.0)
	await _press_e_expecting("ExitDoor")
	_check(main.closeup == "door" and main.player.input_locked, "E opens the door's close-up and Graham stands still")
	_check(not main.s01_gate_open and _says("门锁着"), "the door is locked")
	await _seconds(0.4)
	_check(main.interaction_hint_label.text == "E 收起", "in a close-up E puts it away (%s)" % main.interaction_hint_label.text)
	await _shot("s01_2_door_closeup")
	await _close()
	_check(main.closeup == "" and not main.player.input_locked, "E again closes it and Graham can walk")

	# The photo, in winter: a big close-up, WASD moves Graham's hand over it.
	await _walk_to_x(180.0)
	await _press_e_expecting("EntrancePhoto")
	_check(main.closeup == "photo" and _says("下雪") and _says("是我"), "the winter photo shows Graham on the ladder")
	await _seconds(0.4)
	_check(main.interaction_hint_label.text.contains("E 收起"), "over nobody, E puts it away (%s)" % main.interaction_hint_label.text)
	var px: float = main.player.position.x
	await _hand_to(Vector2(289, 248))
	_check(absf(main.player.position.x - px) < 1.0, "moving the hand does not move Graham")
	_check(main.interaction_hint_label.text.contains("E 碰一碰"), "over someone, E touches (%s)" % main.interaction_hint_label.text)
	await _shot("s01_3_photo_winter")
	await _press("interact")
	_check(main.closeup_anim == "lamp", "Graham in the photo fixes the lamp")
	await _seconds(1.6)
	_check(main.s01_lamp_fixed and _says("挥了挥手"), "the photo's lamp is on; she waves")
	await _hand_to(Vector2(96, 300))
	await _press("interact")
	await _seconds(0.7)
	await _shot("s01_3b_snow_out_of_the_photo")
	await _seconds(0.8)
	_check(main.s01_snow_out, "the cleaner shovels snow out of the photo")
	await _hand_to(Vector2(200, 318))
	await _press("interact")
	_check(_says("歪了歪头"), "the bear tilts its head")
	await _close_photo()
	await _shot("s01_3c_snow_on_the_floor")
	# The lamp fixed in the photo: the hall's 出口 sign stops humming.
	await _walk_to_x(720.0)
	await _press_e_expecting("ExitDoor")
	_check(_says("不再嗡嗡"), "the 出口 sign no longer hums (%s)" % main.dialogue_label.text)
	await _close()

	# 《观看的永恒》: the first look only describes it; then each E turns a hand by one notch.
	await _walk_to_x(470.0)
	await _press_e_expecting("ClockBack")
	_check(main.closeup == "clock_back" and main.s01_clocks_seen and main.s01_era == 1, "first E describes 《观看的永恒》 without turning")
	await _close()
	_check(main.interaction_hint_label.text == "E 往回拨", "hint becomes 往回拨 (%s)" % main.interaction_hint_label.text)
	await _press_e_expecting("ClockBack")
	_check(main.s01_era == 0 and main.closeup_anim == "turn", "turning back reaches opening day, inside the close-up")
	_check(_says("暖和") and not _says("照片"), "the painting turns warm; the text does not point at the photo")
	await _seconds(0.5)
	await _shot("s01_4_clock_turning")
	await _seconds(0.6)
	_check(main.closeup_anim == "", "the hand has finished turning")
	await _shot("s01_5_clock_opening_day")
	await _close()
	await _press_e_expecting("ClockBack")
	_check(main.s01_era == 0 and _says("拨不动"), "cannot turn back past opening day")
	await _close()

	main.s01_idle_time = 30.0
	await _seconds(1.5)
	_check(main.s01_eye_look.distance_to(main.S01_PHOTO_RECT.get_center()) < 40.0, "when stuck, 《这不是一只眼睛》 looks at the photo (%s)" % main.s01_eye_look)

	# Opening day: everyone in the photo can be touched; the girl has the chalk.
	await _walk_to_x(180.0)
	await _press_e_expecting("EntrancePhoto")
	_check(_says("开幕日") and _says("小女孩"), "the opening-day photo, with the girl")
	await _seconds(0.4)
	await _shot("s01_6_photo_opening_day")
	# A small puzzle inside the photo: no ribbon yet. The girl only stares at the guard's scissors.
	await _hand_to(Vector2(205, 312))
	await _press("interact")
	_check(_says("大剪刀") and main.closeup_anim == "" and not main.s01_has_chalk, "the girl keeps her chalk and stares at the scissors")
	await _hand_to(Vector2(320, 300))
	await _press("interact")
	_check(_says("等着剪") and not main.s01_ribbon_cut, "the guard has nothing to cut yet")
	await _hand_to(Vector2(70, 300))
	await _press("interact")
	await _seconds(0.9)
	await _shot("s01_6b_restorer_paints_the_ribbon")
	await _seconds(0.7)
	_check(main.s01_restorer_dab and _says("彩带") and _says("颜料"), "the restorer paints the ribbon")
	await _hand_to(Vector2(320, 300))
	await _press("interact")
	await _seconds(1.2)
	_check(main.s01_ribbon_cut, "now the guard cuts it")
	await _hand_to(Vector2(424, 300))
	await _press("interact")
	await _seconds(1.1)
	_check(main.s01_visitors_turned and _says("什么也没有"), "the visitors turn round, faceless")
	await _hand_to(Vector2(482, 304))
	await _press("interact")
	await _seconds(1.0)
	await _shot("s01_6c_cleaner_over_the_roof")
	await _seconds(1.2)
	_check(main.s01_cleaner_waved, "the cleaner grows over the roof and back")
	await _hand_to(Vector2(205, 312))
	await _press("interact")
	_check(main.closeup_anim == "chalk" and not main.s01_has_chalk, "she plays with the cut ribbon, then her arm comes out of the photo")
	await _seconds(0.4)
	await _shot("s01_6d_girl_twirls_the_ribbon")
	await _seconds(1.0)
	_check(main._s01_hyper_now().size() == 2, "a hyper-real insert cuts in (the real hand)")
	await _shot("s01_7_hyperreal_hand")
	await _seconds(1.4)
	_check(main.s01_has_chalk and _says("粉笔"), "Graham has the chalk")
	_check(main.closeup == "photo", "the close-up stays open after the chalk")
	await _close_photo()
	await _shot("s01_7b_hall_after_the_photo")

	# The map: a maze of sulci.
	await _walk_to_x(310.0)
	_check(main.interaction_hint_label.text == "E 拿出粉笔", "hint at the map with the chalk (%s)" % main.interaction_hint_label.text)
	await _press_e_expecting("CommunityMap")
	_check(main.closeup == "map" and main._s01_maze_active(), "the map's close-up takes WASD")
	await _seconds(0.4)
	_check(main.interaction_hint_label.text.contains("WASD"), "maze hint (%s)" % main.interaction_hint_label.text)
	await _press("move_up")
	_check(main.s01_maze_path.size() == 1, "no groove up from the start: the dot does not move")
	await _press("move_left")
	await _press("move_left")
	_check(main.s01_maze_path.size() == 3, "the dot walks two steps left")
	await _press("move_up")
	_check(main.s01_maze_path.size() == 4, "into a side groove")
	await _press("move_down")
	_check(main.s01_maze_path.size() == 3, "stepping back wipes the chalk")
	_check(main.player.position.x > 300.0 and main.player.position.x < 320.0, "Graham did not walk while drawing")
	# Put it away halfway and come back: the line stays.
	await _close()
	_check(main.s01_maze_path.size() == 3, "the chalk line stays on the map")
	await _shot("s01_8_map_on_the_wall_halfway")
	await _press_e_expecting("CommunityMap")
	for dir in ["move_left", "move_left", "move_left", "move_left", "move_left", "move_down", "move_left", "move_up", "move_left", "move_down", "move_left", "move_up"]:
		await _press(dir)
	await _shot("s01_9_map_almost")
	await _press("move_left")
	_check(main.closeup_anim == "key", "reaching 出口 lifts the key")
	_check(main.s01_maze_path.size() == main.S01_MAZE_PATHS[0].size(), "the line is the key's blade and teeth")
	await _seconds(1.2)
	await _shot("s01_10_key_out_of_the_map")
	await _seconds(1.6)
	_check(main.s01_has_key and main.closeup == "" and not main.player.input_locked, "Graham has the key; the close-up has closed")
	main.s01_idle_time = 30.0
	await _seconds(1.5)
	_check(main.s01_eye_look.distance_to(main.S01_DOOR_RECT.get_center()) < 40.0, "when stuck, the eye looks at the door (%s)" % main.s01_eye_look)

	# The door.
	await _walk_to_x(720.0)
	_check(main.interaction_hint_label.text == "E 开门", "hint at the door with the key (%s)" % main.interaction_hint_label.text)
	await _press_e_expecting("ExitDoor")
	await _seconds(0.4)
	_check(main.interaction_hint_label.text == "E 插钥匙", "in the door's close-up (%s)" % main.interaction_hint_label.text)
	await _shot("s01_11_lock")
	await _press("interact")
	_check(main.closeup_anim == "door", "the key goes in")
	await _seconds(0.85)
	_check(main._s01_hyper_now().size() == 2, "a hyper-real insert cuts in (the brass lock)")
	await _shot("s01_11b_hyperreal_lock")
	await _seconds(0.75)
	await _shot("s01_12_door_swings_open")
	await _seconds(1.3)
	_check(main.s01_gate_open and main.s01_exit_route == "past", "the key opens the door")
	_check(main.closeup == "" and main.s01_active, "the close-up closes; still in S01")
	_check(main.chapter_state.player_goal == &"find_a_way_out", "goal recorded")
	await _shot("s01_13_door_open")
	await _press_e_expecting("ExitDoor")
	_check(main.s02_active, "E at the open door enters S02")
	_finish("S01 past route")

func _press_e_expecting(item_name: String) -> void:
	var nearest: Dictionary = main._get_nearest_s01_interactable()
	_check(nearest.get("name", "") == item_name, "at x=%d E targets %s, expected %s" % [main.player.position.x, nearest.get("name", "<nothing>"), item_name])
	_check(main.interaction_hint_label.visible, "E hint visible at %s" % item_name)
	await _press("interact")

## E in a close-up puts it away (once nothing is playing in it).
func _close() -> void:
	await _seconds(0.35)
	await _press("interact")
	await _seconds(0.45)
	_check(main.closeup == "", "close-up closed")

## Moves Graham's hand over the photo (its own space) with WASD.
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
	await _frames(2)

func _hold_if(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)

## Move the hand onto the sky (nobody there) and put the photo away.
func _close_photo() -> void:
	await _hand_to(Vector2(40, 60))
	await _close()

func _walk_to_x(target: float) -> void:
	var action := "move_right" if target > main.player.position.x else "move_left"
	Input.action_press(action)
	for i in range(600):
		# Re-press every frame: a windowed run that loses focus releases held actions.
		Input.action_press(action)
		await physics_frame
		var x: float = main.player.position.x
		if (action == "move_right" and x >= target) or (action == "move_left" and x <= target):
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

func _says(fragment: String) -> bool:
	return main.dialogue_label.text.contains(fragment)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _seconds(t: float) -> void:
	await create_timer(t).timeout

func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png(SHOT_DIR + "/" + shot_name + ".png")
