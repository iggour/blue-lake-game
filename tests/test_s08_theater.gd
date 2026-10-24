extends SceneTree

## S08 walkthrough: reobserve the Window, enter Blue Lake, open it with Chalk,
## and land on the Truth Theater stage through the curtain transition.
##
## Headless (asserts only):
##   "$G" --headless --path . --script tests/test_s08_theater.gd
## With a window (also saves screenshots to .artifacts/screenshots/):
##   "$G" --path . --script tests/test_s08_theater.gd

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

	# Jump straight to S08 the same way S07 hands off (S07 completion unlocks S08).
	main.s01_active = false
	main.s01_gate_open = true
	main.chapter_state.complete_slice(ChapterState.Slice.S07_RETURN)
	main._enter_s08_after_s07()
	await _frames(2)
	_check(main.s08_active, "S08 is active")
	_check(main.chapter_state.current_slice == ChapterState.Slice.S08_TRUE_EXIT, "ChapterState is on S08")

	# E: reobserve the Window.
	main._try_s08_interact()
	_check(main.s08_window_observed, "E reobserves the Window")
	await _frames(2)
	await _shot("s08_1_window")

	# Space: first entry plays the Blue Lake transformation.
	main._try_toggle_s08_blue_lake()
	await main.blue_lake_transform.finished
	await _frames(2)
	_check(main.blue_lake_active, "Space enters Blue Lake")

	# Left click with the Chalk Cursor on the Window.
	main.chalk_hover_target = "FinalWindow"
	main._try_s08_chalk_interaction()
	_check(main.s08_window_open, "Chalk opens the Window")
	_check(main.chapter_state.is_slice_completed(ChapterState.Slice.S08_TRUE_EXIT), "S08 completed")
	await _frames(2)
	await _shot("s08_2_window_open")

	# The transition: window -> curtain closes -> curtain opens.
	await create_timer(1.3).timeout
	_check(main.transition_started, "curtain transition started")
	await create_timer(1.7).timeout
	await _shot("s08_3_curtain")
	await main.transition.finished
	await _frames(3)

	_check(main.scene_state == "theater", "lands in the theater, not outside (got %s)" % main.scene_state)
	_check(main.chapter_state.map_state == &"Theater_Stage_Entrance", "map_state is Theater_Stage_Entrance")
	_check(main.chapter_state.has_story_event(&"theater_entered"), "theater_entered story event")
	_check(not main.player.input_locked, "player can move on stage")
	await _shot("s08_4_theater")

	if failures.is_empty():
		print("TEST PASS: S08 -> theater")
		quit(0)
	else:
		for f in failures:
			printerr("TEST FAIL: " + f)
		quit(1)

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
	var image := root.get_texture().get_image()
	image.save_png(SHOT_DIR + "/" + shot_name + ".png")
