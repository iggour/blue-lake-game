extends SceneTree

## S05: open 《窗》 and walk into the sensor hall behind it (with depth), meet the cleaner,
## get the old lens cleaned and focused, and see that the chart's last cell is not empty.
## The hall's things are close-ups: the eyepiece (A/D slide the lens), the cleaner with his bucket
## (WASD hand), the rack, the pile, the mural.
##
## Headless:      "$G" --headless --path . --script tests/test_s05_window.gd
## With a window: "$G" --path . --script tests/test_s05_window.gd   (screenshots -> .artifacts/screenshots/)

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
	# Arrive in S05 the way S04 hands off: standing in front of 《窗》, frame and handle in place.
	main.s01_active = false
	main.s01_gate_open = true
	main.chapter_state.complete_slice(ChapterState.Slice.S04_VISITOR)
	main.player.position.x = 590.0
	main._enter_s05_after_s04()
	await _frames(2)
	_check(main.s05_active and main.s05_room == "window", "S05 starts in front of 《窗》")
	_check(main.space_prompt_visible and main.objective_label.text.contains("Space"), "S05 opens with the Space prompt and says how to open 《窗》")

	await _press_e_expecting("Window")
	_check(main.s05_window_observed, "E observes 《窗》")
	_check(main.dialogue_label.text.contains("蓝天") and not main.dialogue_label.text.contains("红房子"), "from the gallery 《窗》 is only a window (no house)")
	await _shot("s05_1_window")
	await _press("blue_lake")
	await main.blue_lake_transform.finished
	await _frames(2)
	_check(main.blue_lake_active, "Space enters Blue Lake")
	await _shot("s05_1b_blue_lake_window")
	main.chalk_hover_target = "Window"
	main._try_s05_chalk_interaction()
	_check(main.s05_window_open, "Chalk on the handle opens 《窗》")
	_check(main.chapter_state.knows(&"s05_blue_lake_can_change_the_world"), "first change of the world is learned")
	await create_timer(0.45).timeout
	await _shot("s05_2_opening")
	await create_timer(0.8).timeout
	_check(main.s05_room == "hall", "the landscape grows into the hall")
	_check(main.s05_labeled, "the cleaner tags Graham from afar")
	_check(main._s05_in_painting() and main.player.scale.x < 0.2, "Graham comes out of the red house's door, inside the mural, tiny (scale %.2f)" % main.player.scale.x)
	await _shot("s05_3_hall")
	await _drain()

	# Walk down the painted road and out of the mural onto the floor; she grows as she comes.
	await _hold("move_down", 40)
	_check(main.s05_stepped_out and not main._s05_in_painting(), "S walks out of the painting onto the floor")
	await _shot("s05_3b_out_of_mural")
	var y0: float = main.player.position.y
	await _hold("move_down", 20)
	_check(main.player.position.y > y0 + 20.0 and main.player.scale.x > 0.6, "nearer, Graham is bigger (scale %.2f)" % main.player.scale.x)

	# Five close-ups instead of twelve E points: the lens, the lamp, the bucket and the plinths are not E points.
	for inert in ["Lens", "Lamp", "Bucket", "Plinth_s01"]:
		await _stand_at(inert)
		var nearest: Dictionary = main._get_nearest_s05_interactable()
		_check(nearest.get("name", "") != inert, "%s is no longer an E point of its own" % inert)
	await _e_at("Eyepiece")
	_check(main.closeup == "eyepiece" and main.dialogue_label.text.contains("白雾"), "the eyepiece close-up: fogged")
	_check(main.interaction_hint_label.text.contains("A/D"), "A/D slides the lens (%s)" % main.interaction_hint_label.text)
	await _shot("s05_4_fogged")
	await _close()
	await _e_at("Mural")
	_check(main.closeup == "mural" and main.dialogue_label.text.contains("美术馆") and main.dialogue_label.text.contains("窗"), "the mural close-up: the red house (with windows) is the museum")
	await _shot("s05_4b_mural")
	await _close()
	await _e_at("Pile")
	_check(main.closeup == "pile" and main.dialogue_label.text.contains("搬了下来"), "the pile close-up: the exhibits were taken off the rack")
	await _close()
	await _e_at("Rack")
	_check(main.closeup == "rack" and main.dialogue_label.text.contains("空着"), "the rack close-up: the last row is empty except the fogged case")
	_check(not main.dialogue_label.text.contains("透明点"), "no clear spots in the fog yet")
	await _close()
	# The cleaner: tiny from far, a giant up close, normal only from the footprints.
	await _cleaner_closeup(0.15)
	_check(main.dialogue_label.text.contains("扣子"), "from far he looks tiny")
	await _shot("s05_5_cleaner_tiny")
	await _press("interact")
	_check(not main.s05_cleaner_met and main.dialogue_label.text.contains("脚印"), "tiny, he can't see her; LAN points at the footprints")
	await _close()
	await _cleaner_closeup(0.92)
	_check(main.dialogue_label.text.contains("鞋"), "up close only his shoe fits in the picture")
	await _shot("s05_5b_cleaner_giant")
	await _press("interact")
	_check(not main.s05_cleaner_met, "a giant can't see her either")
	await _close()
	await _cleaner_closeup(main.S05_FOOTPRINTS_Z)
	_check(main.interaction_hint_label.text == "E 说话", "the hand starts on him (%s)" % main.interaction_hint_label.text)
	await _press("interact")
	_check(main._s05_cleaner_size() == "normal" and main.s05_cleaner_met, "from the footprints he is normal size and talks")
	await _shot("s05_6_cleaner")
	await _drain()
	# The bucket: 《那喀索斯》's water. The boy looks up out of it; touching it breaks his face.
	await _hand_to(main.BUCKET_SPOT)
	_check(main.interaction_hint_label.text.contains("水"), "the hand over the bucket (%s)" % main.interaction_hint_label.text)
	await _press("interact")
	_check(main.dialogue_label.text.contains("那喀索斯") and main.dialogue_label.text.contains("楼下"), "the boy downstairs looks up out of the bucket")
	await _press("interact")
	_check(main.closeup_anim == "ripple", "E touches the water: a ripple")
	await _seconds(0.5)
	await _shot("s05_6b_bucket_ripple")
	await _seconds(1.1)
	await _close()
	# The eyepiece: A/D slide the lens. No counting of notches; the scale and the blur say it.
	await _e_at("Eyepiece")
	await _seconds(0.35)
	await _press("move_right")
	_check(main.s05_lens_notch == 3 and not main.dialogue_label.text.contains("格"), "D pushes the lens one notch, without counting what is left")
	await _press("move_right")
	_check(main.s05_lens_notch == main.S05_CLEAN_NOTCH and main.closeup_anim == "sponge", "in the cleaning zone the cleaner's sponge comes across the view")
	await _seconds(0.9)
	_check(main._s01_hyper_now().size() == 2 and main._s01_hyper_now()[0] == "sponge", "a hyper-real insert: the wet sponge on the lens")
	await _shot("s05_6c_hyperreal_sponge")
	await _seconds(1.7)
	_check(main.s05_lens_clean and main.closeup == "eyepiece", "the lens is clean; still looking")
	await _press("move_left")
	await _press("move_left")
	_check(not main.s05_cell_seen, "two notches back: still blurred")
	await _shot("s05_6d_blurred")
	await _press("move_left")
	_check(main.s05_lens_notch == main.S05_FOCUS_NOTCH and main.s05_cell_seen, "in focus: the last cell is not empty")
	await _seconds(0.4)
	await _shot("s05_7_eight_lenses")
	await _drain()
	await _close()
	await create_timer(main.S04_LINE_TIME + 0.5).timeout
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S05_WINDOW), "S05 complete")
	_check(main.s06_active, "hands on to S06")
	_check(main.s05_room == "hall" and main.player.ground_top == main.S05_PAINT_TOP_Y, "S06 continues in the same hall, depth still on")
	# What was seen through the eyepiece shows on the case: eight clear spots in the fog.
	await _drain()
	await _e_at("Rack")
	_check(main.dialogue_label.text.contains("透明点"), "the fifth case now has eight clear spots in its fog")
	await _shot("s05_8_breath_spots")
	await _close()
	if failures.is_empty():
		print("TEST PASS: S05")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

func _stand_cleaner(z: float) -> void:
	main.player.position = Vector2(main._s05_px(main.S05_CLEANER_X, z), main._s05_y(z))
	await _frames(2)

func _cleaner_closeup(z: float) -> void:
	await _stand_cleaner(z)
	var nearest: Dictionary = main._get_nearest_interactable()
	_check(nearest.get("name", "") == "Cleaner", "at z=%.2f E targets the cleaner (got %s)" % [z, nearest.get("name", "<nothing>")])
	await _press("interact")
	_check(main.closeup == "cleaner", "E opens the cleaner's close-up")
	await _seconds(0.35)

func _close() -> void:
	# In a big close-up E acts on what is under the hand: move it off first.
	if main.closeup == "cleaner":
		await _hand_to(Vector2(380, 40))
	elif main.closeup == "narcissus":
		await _hand_to(Vector2(300, 200))
	await _seconds(0.35)
	await _press("interact")
	await _seconds(0.45)
	_check(main.closeup == "", "close-up closed")

func _seconds(t: float) -> void:
	await create_timer(t).timeout

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

func _stand_at(item_name: String, dz: float = 0.0) -> void:
	var item: Dictionary = main._s05_item(item_name)
	var z: float = clampf(main._s05_item_z(item) + dz, 0.0, 1.0)
	var x: float = main._s05_px(main.S05_RAIL_X if item_name == "Lens" else item.x, z)
	main.player.position = Vector2(x, main._s05_y(z))
	await _frames(2)

func _e_at(item_name: String, dz: float = 0.0) -> void:
	await _stand_at(item_name, dz)
	await _press_e_expecting(item_name)

func _drain() -> void:
	var guard := 0
	while not main.s05_lines.is_empty() and guard < 20:
		await _press("interact")
		guard += 1

func _shot(shot_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _frames(3)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png(SHOT_DIR + "/" + shot_name + ".png")

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _press_e_expecting(item_name: String) -> void:
	var nearest: Dictionary = main._get_nearest_s05_interactable()
	_check(nearest.get("name", "") == item_name, "at x=%d E targets %s, expected %s" % [main.player.position.x, nearest.get("name", "<nothing>"), item_name])
	_check(main.interaction_hint_label.visible, "E hint visible at %s" % item_name)
	await _press("interact")

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
