extends SceneTree

## S06: light the heap, shift its pieces until the shadow is Kent, the cleaner sees the fifth case, Blue Lake reveals the sensor.
##
## Headless:      "$G" --headless --path . --script tests/test_s06_shadow.gd
## With a window: "$G" --path . --script tests/test_s06_shadow.gd   (screenshots -> .artifacts/screenshots/)

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
	await _setup_s06()
	_check(main.s06_active and main.s05_room == "hall", "S06 in the sensor hall")
	await _drain()
	await _press("blue_lake")
	await _frames(2)
	_check(not main.blue_lake_active and main.dialogue_label.text.contains("灯"), "Space before the lamp is on: LAN asks for the lamp")
	# Imitation hint: up close the giant cleaner reaches the top of the rack for the card.
	await _talk_cleaner(0.92)
	_check(main.s06_has_card, "the giant cleaner fetches case 5's card from the top of the rack")
	await _drain()
	await _close()
	await _e_at("Rack")
	_check(main.closeup == "rack" and main.dialogue_label.text.contains("卡片"), "the rack close-up: the card with the silhouette pinned on it")
	await _wait(0.4)
	await _shot("s06_0_card")
	await _close()
	# The pile, from just behind the lamp: E switches it on, Space hands LAN's chalk, the chalk drags.
	await _e_at("Pile")
	_check(main.closeup == "pile", "the pile close-up")
	await _wait(0.35)
	_check(main.interaction_hint_label.text == "E 开灯", "E turns the lamp on (%s)" % main.interaction_hint_label.text)
	await _press("interact")
	await _wait(0.7)
	_check(main.s06_lamp_on, "the lamp is on")
	await _shot("s06_1_messy_shadow")
	await _press("blue_lake")
	await _frames(2)
	_check(main.blue_lake_active, "Space in the close-up: LAN's chalk")
	# A wrong place: the shadow moves but does not settle.
	main._s06_grab(main.s06_pieces["body"])
	_check(main.s06_drag == "body", "the chalk picks up the eyeball")
	main._s06_drop(Vector2(200, 300))
	_check(not main._s06_piece_ok("body") and main.s06_pieces["body"] == Vector2(200, 300), "dropped in a wrong place, it stays there")
	# The right places: each settles, its shadow lit; the last one makes Kent.
	for piece in ["head", "legs_l", "eyes", "legs_r", "body"]:
		main._s06_grab(main.s06_pieces[piece])
		main._s06_drop(main._s06_piece_target(piece) + Vector2(3, 2))
		_check(main._s06_piece_ok(piece), "%s settles where its shadow belongs" % piece)
		if piece == "eyes":
			await _shot("s06_1b_half_done")
	_check(main.closeup_anim == "kent", "all five: the shadow becomes Kent")
	await _wait(1.0)
	_check(main._s01_hyper_now().size() == 2 and main._s01_hyper_now()[0] == "spider", "a hyper-real insert: a jumping spider's main eyes")
	await _shot("s06_1c_hyperreal_spider")
	await _wait(1.6)
	_check(main.s06_shadow_done and not main.blue_lake_active, "the shadow is Kent; the chalk is put away")
	await _drain()
	await _close()
	await _shot("s06_2_kent_shadow")
	await _talk_cleaner(main.S05_FOOTPRINTS_Z)
	_check(main.s06_wipe_t < 0.0 and main.dialogue_label.text.contains("小一点"), "normal size: too big to get into the fifth case")
	await _close()
	await _talk_cleaner(0.15)
	_check(main.s06_wipe_t >= 0.0 and not main.s06_case_clean, "from far he is tiny and climbs into the fifth case")
	await _drain()
	await _close()
	await _e_at("Rack")
	_check(main.dialogue_label.text.contains("擦玻璃"), "the rack close-up: the tiny cleaner wiping the case from inside")
	await _wait(1.0)
	await _shot("s06_2b_wiping_inside")
	await _close()
	await _wait(main.S06_WIPE_TIME)
	_check(main.s06_case_clean and main.s06_wipe_t < 0.0, "he comes out; the case is clean")
	await _drain()
	await _e_at("Rack")
	_check(main.dialogue_label.text.contains("Space"), "the rack: clean but unreadable, press Space")
	await _wait(0.35)
	await _press("blue_lake")
	await _frames(2)
	_check(main.blue_lake_active, "Space in the rack close-up: LAN's chalk")
	main._s06_rack_chalk(main.SENSOR_CASE.position + Vector2(8, 8))
	_check(main.dialogue_label.text.contains("只是灰"), "a wrong spot: only grey")
	for i in range(8):
		main._s06_rack_chalk(main._sensor_lens_at(i) + Vector2(2, -2))
		if i == 3:
			await _shot("s06_2c_marking_lenses")
	_check(main.s06_sensor_revealed, "all eight lenses marked: the sensor shows")
	await _wait(0.3)
	await _shot("s06_3_sensor")
	await _drain()
	await _close()
	await _wait(main.S04_LINE_TIME + 0.5)
	_check(main.s07_active, "S06 complete -> S07")
	_finish("S06")

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
