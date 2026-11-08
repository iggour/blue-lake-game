extends SceneTree

## S07 (optional): look at the red house through the hall's windows, revisit three rooms, find one new thing in each; the eyepiece shows this hall itself.
##
## Headless:      "$G" --headless --path . --script tests/test_s07_red_house.gd
## With a window: "$G" --path . --script tests/test_s07_red_house.gd   (screenshots -> .artifacts/screenshots/)

const MainScene := preload("res://scenes/main/prototype_01.tscn")
const SHOT_DIR := "res://.artifacts/screenshots"

var main: Node2D
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _setup_s06() -> void:
	main = MainScene.instantiate()
	root.add_child(main)
	await _frames(5)
	main.s01_active = false
	main.s01_gate_open = true
	main.chapter_state.complete_slice(ChapterState.Slice.S05_WINDOW)
	main._enter_s06_after_s05()
	await _frames(2)

## Skip S06 with its outcome in place: lamp on, shadow is Kent, case clean, sensor revealed.
func _setup_s07() -> void:
	await _setup_s06()
	main.s06_lamp_on = true
	for piece in main.S06_PIECES:
		main.s06_pieces[piece] = main._s06_piece_target(piece)
	main.s06_shadow_done = true
	main.s06_case_clean = true
	main.s06_sensor_revealed = true
	main.s05_lines = []
	main.s06_finish_pending = false
	main.chapter_state.complete_slice(ChapterState.Slice.S06_PLATFORM)
	main._enter_s07_after_s06()
	await _frames(2)
	await _drain()

func _run() -> void:
	await _setup_s07()
	_check(main.s07_active and main.s07_room == "hall", "S07 in the hall")
	await _press("blue_lake")
	await main.blue_lake_transform.finished
	await _frames(2)
	_check(main.blue_lake_active, "Space: Blue Lake")
	await _shot("s07_0_windows")
	var rooms := [["s01", "MapSticker", 0, "map"], ["s02", "BlueFish", 1, "narcissus"], ["s04", "GirlDrawing", 2, "girl"]]
	for entry in rooms:
		var room: String = entry[0]
		if not main.blue_lake_active:
			await _press("blue_lake")
			await _frames(2)
		main.chalk_hover_target = "MuralWindow%d" % entry[2]
		main._try_s07_chalk_interaction()
		await _wait(1.0)
		_check(main.s07_room == room, "Chalk on window %d leads to %s (got %s)" % [entry[2], room, main.s07_room])
		_check(main.player.ground_top == 410.0 and main.player.scale == Vector2.ONE, "no depth in %s" % room)
		# The hidden thing is found inside that room's old close-up.
		await _e_room(entry[1])
		_check(main.closeup == entry[3], "in %s, E opens the old close-up %s (got %s)" % [room, entry[3], main.closeup])
		await _wait(0.4)
		if room == "s02":
			await _hand_to(Vector2(300, 350))
			await _press("interact")
			_check(main.s07_fish_fled and not main.s07_found[room], "touched, the fish darts off and comes back")
			await _wait(0.5)
			await _shot("s07_s02_fish")
			await _wait(1.0)
		await _press("interact")
		await _wait(0.9)
		_check(main.s07_found[room], "found the hidden thing in %s" % room)
		_check(main.dialogue_label.text.contains("回去"), "LAN says how to get back from %s" % room)
		await _shot("s07_" + room)
		await _close()
		await _press("blue_lake")
		await _frames(2)
		_check(main.blue_lake_active, "Space in %s: Blue Lake" % room)
		main.chalk_hover_target = "ReturnWindow"
		main._try_s07_chalk_interaction()
		await _wait(1.0)
		_check(main.s07_room == "hall" and main.player.ground_top == main.S05_PAINT_TOP_Y, "Chalk on the room's own window leads back to the hall")
		_check(main.s07_shelved[room] and main.dialogue_label.text.contains("编号"), "the cleaner numbers it and puts it on its plinth")
		await _drain()
	# Telescope: the eyepiece close-up; A/D bring one window of the red house at a time into focus.
	main.s05_lens_notch = 2
	await _e_at("Eyepiece")
	_check(main.closeup == "eyepiece" and main.dialogue_label.text.contains("左下"), "through the eyepiece, notch 2 brings the bottom-left window into focus")
	await _wait(0.4)
	await _shot("s07_telescope")
	await _press("move_right")
	_check(main.dialogue_label.text.contains("水桶"), "notch 3: this hall, something behind the bucket")
	await _close()
	# The button behind the bucket is picked up right there in the hall.
	await _e_at("Bucket")
	_check(main.s07_found["hall"] and main.s07_shelved["hall"], "behind the bucket: the fourth thing, shelved")
	_check(main.chapter_state.has_event(&"achievement_all_filed") and main.achievements_unlocked.has("ACH_CH1_ALL_FILED"), "all four plinths full: a platform achievement (no in-game pop-up)")
	await _drain()
	await _close()
	await _e_at("Mural")
	_check(main.dialogue_label.text.contains("亮了 4 扇"), "the mural close-up: all four windows lit, each with its thing")
	await _wait(0.4)
	await _shot("s07_lit_windows")
	await _close()
	await _e_at("Rack")
	_check(main.closeup == "rack" and main.interaction_hint_label.text == "E 伸手", "the rack close-up in S07 (%s)" % main.interaction_hint_label.text)
	await _wait(0.4)
	await _press("interact")
	await _wait(1.2)
	_check(main.s07_hesitated and main.s07_active, "first E: the hand stops at the glass; Graham hesitates")
	await _shot("s07_hesitate")
	_finish("S07")

func _e_at_cleaner() -> void:
	var nearest: Dictionary = main._get_nearest_interactable()
	_check(nearest.get("name", "") == "Cleaner", "E targets the cleaner (got %s)" % nearest.get("name", "<nothing>"))
	await _press("interact")
	await _wait(0.35)

func _stand_at(item_name: String, dz: float = 0.0) -> void:
	var item: Dictionary = main._s05_item(item_name)
	var z: float = clampf(main._s05_item_z(item) + dz, 0.0, 1.0)
	var x: float = main._s05_px(main.S05_RAIL_X if item_name == "Lens" else item.x, z)
	main.player.position = Vector2(x, main._s05_y(z))
	await _frames(2)

func _e_at(item_name: String, dz: float = 0.0) -> void:
	await _stand_at(item_name, dz)
	var nearest: Dictionary = main._get_nearest_interactable()
	_check(nearest.get("name", "") == item_name, "at %s, E targets %s" % [item_name, nearest.get("name", "<nothing>")])
	await _press("interact")

func _e_room(item_name: String) -> void:
	for item in main.s07_room_items:
		if item.name == item_name and (item.room == main.s07_room or item.room == "any"):
			main.player.position = Vector2(item.position.x, 470.0)
	await _frames(2)
	var nearest: Dictionary = main._get_nearest_interactable()
	_check(nearest.get("name", "") == item_name, "in %s, E targets %s" % [main.s07_room, nearest.get("name", "<nothing>")])
	await _press("interact")

func _drain() -> void:
	var guard := 0
	while not main.s05_lines.is_empty() and guard < 20:
		await _press("interact")
		guard += 1

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

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _frames(3)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png(SHOT_DIR + "/" + shot_name + ".png")

func _finish(label: String) -> void:
	if failures.is_empty():
		print("TEST PASS: " + label)
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _stand_cleaner(z: float) -> void:
	main.player.position = Vector2(main._s05_px(main.S05_CLEANER_X, z), main._s05_y(z))
	await _frames(2)

func _talk_cleaner(z: float) -> void:
	await _stand_cleaner(z)
	var nearest: Dictionary = main._get_nearest_interactable()
	_check(nearest.get("name", "") == "Cleaner", "at z=%.2f E targets the cleaner (got %s)" % [z, nearest.get("name", "<nothing>")])
	await _press("interact")
	_check(main.closeup == "cleaner", "E opens the cleaner's close-up")
	await _wait(0.35)
	# The hand starts on him: E talks.
	await _press("interact")

func _close() -> void:
	# In a big close-up E acts on what is under the hand: move it off first.
	if main.closeup == "cleaner":
		await _hand_to(Vector2(380, 40))
	elif main.closeup == "narcissus":
		await _hand_to(Vector2(300, 200))
	await _wait(0.35)
	await _press("interact")
	await _wait(0.45)
	_check(main.closeup == "", "close-up closed (%s)" % main.closeup)

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
