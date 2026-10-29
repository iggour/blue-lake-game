extends SceneTree

## S05 style sample: both art layers load, Space reveals Blue Lake from Graham,
## chalk on 《窗》 shows the handle, then opens it.
##
## Headless:      "$G" --headless --path . --script tests/test_style_sample_s05.gd
## With a window: "$G" --path . --script tests/test_style_sample_s05.gd   (screenshots -> .artifacts/screenshots/)

const SampleScene := preload("res://scenes/style_sample/s05_style_sample.tscn")
const SHOT_DIR := "res://.artifacts/screenshots"

var s: Node2D
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	s = SampleScene.instantiate()
	root.add_child(s)
	await _frames(5)
	for sprite in [s.normal_handle, s.normal_open, s.bl_handle, s.bl_open]:
		_check(sprite.texture != null, "texture loaded: %s" % sprite.texture)
	_check(not s.blue_lake_active and s._radius() == 0.0, "starts in the normal world")
	await _shot("sample_1_normal")

	s.player.position.x = 590.0
	s.observe()
	_check(s.dialogue_label.text.contains("太像一扇真正的窗"), "E on 《窗》 describes the painting")

	s.chalk_click(Vector2(590, 300))
	_check(s.window_state == 0, "chalk does nothing outside Blue Lake")

	s.toggle_blue_lake()
	await _seconds(s.REVEAL_TIME + 0.2)
	_check(s.blue_lake_active and s.is_blue_lake_fully_shown(), "Space reveals the Blue Lake layer")
	await _shot("sample_2_bluelake")

	s.chalk_click(Vector2(100, 100))
	_check(s.window_state == 0, "chalk off the painting does nothing")
	s.chalk_click(Vector2(590, 300))
	_check(s.window_state == 1 and s.bl_handle.visible, "first chalk touch reveals the handle")
	_check(s.dialogue_label.text.contains("把手一直在那里"), "handle line")
	await _shot("sample_3_bluelake_handle")

	s.toggle_blue_lake()
	await _seconds(s.REVEAL_TIME + 0.2)
	_check(s._radius() <= 0.5 and s.normal_handle.visible, "back in the normal world, the brass handle stays")
	await _shot("sample_4_normal_handle")

	s.player.position.x = 300.0
	s.toggle_blue_lake()
	await _seconds(0.14)
	await _shot("sample_5_reveal_midway")
	s.player.position.x = 590.0
	await _seconds(s.REVEAL_TIME)
	s.chalk_click(Vector2(590, 300))
	_check(s.window_state == 2 and s.bl_open.visible, "second chalk touch opens the painting")
	_check(s.dialogue_label.text.contains("这不是出口"), "open line")
	await _shot("sample_6_bluelake_open")
	s.toggle_blue_lake()
	await _seconds(s.REVEAL_TIME + 0.2)
	_check(s.normal_open.visible, "opened painting in the normal world")
	await _shot("sample_7_normal_open")

	if failures.is_empty():
		print("TEST PASS: style sample S05")
		quit(0)
	else:
		for f in failures:
			print("TEST FAIL: " + f)
		quit(1)

func _check(cond: bool, label: String) -> void:
	if not cond:
		failures.append(label)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _seconds(t: float) -> void:
	await create_timer(t).timeout

func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await _frames(3)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.get_texture().get_image().save_png("%s/%s.png" % [SHOT_DIR, name])
