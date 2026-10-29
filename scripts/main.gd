extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const CursorScript := preload("res://scripts/chalk_cursor.gd")
const TransitionScript := preload("res://scripts/transition_overlay.gd")
const BlueLakeTransformScript := preload("res://scripts/blue_lake_transform.gd")
const ChapterStateScript := preload("res://scripts/chapter_state.gd")
# S01 entrance hall. From afar the wall is a face: 《观看的永恒》 and 《这不是一只眼睛》 are the eyes,
# the key hook is the nose and the exit door is the mouth.
const S01_PHOTO_RECT := Rect2(110, 215, 140, 100)
const S01_MAP_RECT := Rect2(270, 225, 80, 90)
const S01_CLOCKS_RECT := Rect2(430, 185, 190, 110)
const S01_CLOCK_BACK := Vector2(470, 236)      # left melting eye: its hands turn the photo back
const S01_CLOCK_FORWARD := Vector2(585, 236)   # right melting eye: forward, and then it melts
const S01_DOOR_RECT := Rect2(680, 282, 80, 90)
const S01_HOOK := Vector2(720, 266)
const S01_EYE_RECT := Rect2(850, 185, 120, 110)
const S01_EYE_CENTER := Vector2(910, 236)
const S01_PHOTO_ERAS := ["开幕日", "冬天", "多年以后"]
const S01_HINT_AFTER := 12.0                   # seconds without progress before the eye starts hinting

# Glass centre of the dead-end mirror at the far right of the S02/S03 hall.
const S03_MIRROR_CENTER := Vector2(983, 286)
# Wall spotlight aimed at 《窗》 in the S04 room; the Chalk marks it.
const S04_LAMP_CENTER := Vector2(500, 300)
# 《窗》 hangs on the wall here in S04 and S05 (same room, same painting).
const S05_WINDOW_CENTER := Vector2(590, 285)
# S06 central platform room: the empty 《看见》 plinth, 《凝视》's mechanical eye, and the back of 《窗》.
const S06_PLATFORM_CENTER := Vector2(560, 282)
const S06_GAZE_EYE := Vector2(330, 290)
const S06_WINDOW_CENTER := Vector2(900, 285)
# Where 《凝视》 looks, in the order the Chalk turns it; index 3 is the platform.
const S06_GAZE_PLACES := ["天花板", "《盲》", "地面", "中央展台"]

# Prototype 0.2 is retained as a reference implementation, not as the default
# Chapter 1 route. Slice-specific content will be reattached deliberately.
const LEGACY_PROTOTYPE_FLOW_ENABLED: bool = false
const S01_ENABLED: bool = true
const S02_ENABLED: bool = true
const S03_ENABLED: bool = true
const S04_ENABLED: bool = true
const S05_ENABLED: bool = true
const S06_ENABLED: bool = true
const S07_ENABLED: bool = true
const S08_ENABLED: bool = true

var player: GrahamSteel
var chapter_state: ChapterState
var s01_active := true
var s01_completion_started := false
var s01_gate_open := false
var s01_interactables: Array[Dictionary] = []
var s01_era := 1                      # the photo is titled 开幕日 but starts in winter
var s01_melt := 0                     # 0..3: the right eye melts onto the floor, the door rusts through
var s01_key_on_hook := false          # mirrors the photo: the key hangs there only on opening day
var s01_exit_route := ""              # "past" (the key) or "future" (rusted through)
var s01_clocks_seen := false
var s01_face_noticed := false
var s01_idle_time := 0.0
var s01_eye_look := Vector2(910, 440) # where 《这不是一只眼睛》 is looking (world position)
var s01_eye_visits := 0
var s01_eyelid_closed := false
var s01_dark_overlay: ColorRect
var s02_active := false
var s02_completion_started := false
var s02_loop_count := 0
var s02_loop_triggered := false
var s02_interactables: Array[Dictionary] = []
var s03_active := false
var s03_mirror_observed := false
var s03_mirror_intervened := false
var s03_mirror_crossed := false
var s03_interactables: Array[Dictionary] = []
var s04_active := false
var s04_visitor_observed := false
var s04_restorer_observed := false
var s04_pigment_borrowed := false
var s04_pigment_applied := false
var s04_lamp_observed := false
var s04_lights_off := false
var s04_visitor_recognized := false
var s04_visitor_moved := false
var s04_interactables: Array[Dictionary] = []
var s05_active := false
var s05_window_observed := false
var s05_window_handle_found := false
var s05_window_open := false
var s05_interactables: Array[Dictionary] = []
var s06_active := false
var s06_platform_observed := false
var s06_sensor_revealed := false
# Gaze puzzle: Blue Lake alone sees only the outline; 《凝视》 alone sees only colour.
var s06_contour_seen := false
var s06_gaze_index := 0
var s06_choice_visible := false
var s06_stolen := false
var s06_chase_active := false
var s06_guard_chase_x := 300.0
var s06_interactables: Array[Dictionary] = []
var s07_active := false
var s07_mirror_observed := false
var s07_mirror_trace_found := false
var s07_window_observed := false
var s07_window_trace_found := false
# S07 revisits two real rooms: "gallery" (the 《窗》 room of S04) and "hall" (the S02/S03 hall).
var s07_room := "gallery"
var s07_interactables: Array[Dictionary] = []
var s08_active := false
var s08_window_observed := false
var s08_window_open := false
var s08_exit_started := false
var s08_interactables: Array[Dictionary] = []
var blue_lake_active := false
var visual_mode := "Standard"
var scene_state := "gallery"
var mirror_solved := false
var window_inspected := false
var handle_found := false
var window_open := false
var transition_started := false
var tutorial_active := true
var chalk_hover_target := ""
var blue_lake_intro_started := false
var blue_lake_intro_ready := false
var blue_lake_transform_completed := false
var space_prompt_visible := false
var blue_lake_trigger_position := Vector2(360, 420)
var dialogue_label: Label
var status_label: Label
var mode_label: Label
var objective_label: Label
var interaction_hint_label: Label
var s06_take_button: Button
var s06_leave_button: Button
var chalk_cursor: Control
var transition
var blue_lake_transform: Control
var theater_nodes: Node2D
var gallery_bodies: Array[StaticBody2D] = []
var window_node: Node2D
var mirror_node: Node2D
var painting_node: Node2D
var gate_body: StaticBody2D
var west_exit_body: StaticBody2D
var interactables: Array[Dictionary] = []

func _ready() -> void:
	chapter_state = ChapterStateScript.new()
	_setup_input_map()
	_build_ui()
	_build_gallery()
	_build_player()
	_build_cursor()
	_build_transition()
	_build_blue_lake_transform()
	if LEGACY_PROTOTYPE_FLOW_ENABLED:
		_show_dialogue("蓝湖：这里像是一座美术馆。\n格雷汉·斯蒂尔：先找出口。")
		var tutorial_timer := get_tree().create_timer(6.0)
		tutorial_timer.timeout.connect(_hide_tutorial)
	else:
		_show_dialogue("旧照片把你带进了真理美术馆。")
		objective_label.text = "WASD / 方向键：移动"
		chapter_state.set_blue_lake_state(&"uninitialized")
		chapter_state.set_map_state(&"Museum_S01_Initial")
		chapter_state.mark_story_event(&"s01_started")
		chapter_state.set_player_goal(&"none")

func _process(delta: float) -> void:
	queue_redraw()
	_update_chalk_hover()
	_update_interaction_hint()
	_update_s01(delta)
	_update_s02_loop_trigger()
	_update_route_transitions()
	if s06_chase_active and s06_active and scene_state == "gallery" and player:
		s06_guard_chase_x = move_toward(s06_guard_chase_x, player.position.x - 44.0, delta * 105.0)
	if LEGACY_PROTOTYPE_FLOW_ENABLED and not blue_lake_intro_started and player and scene_state == "gallery" and player.position.distance_to(blue_lake_trigger_position) <= 125.0:
		_start_blue_lake_intro()

func _hide_tutorial() -> void:
	tutorial_active = false
	if objective_label:
		objective_label.hide()

func _setup_input_map() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E], "blue_lake": [KEY_SPACE]
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)
	var background := ColorRect.new()
	background.color = Color("#101827")
	background.position = Vector2(0, 0)
	background.size = Vector2(1152, 58)
	layer.add_child(background)
	var title := Label.new()
	title.text = "BLUE LAKE  /  " + ("PROTOTYPE 0.2" if LEGACY_PROTOTYPE_FLOW_ENABLED else "CHAPTER 1")
	title.position = Vector2(24, 12)
	title.add_theme_color_override("font_color", Color("#bfe8ff"))
	title.add_theme_font_size_override("font_size", 20)
	layer.add_child(title)
	status_label = Label.new()
	status_label.position = Vector2(24, 70)
	status_label.add_theme_color_override("font_color", Color("#d9e6f2"))
	status_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(status_label)
	mode_label = Label.new()
	mode_label.position = Vector2(850, 12)
	mode_label.add_theme_color_override("font_color", Color("#ffffff"))
	mode_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(mode_label)
	objective_label = Label.new()
	objective_label.position = Vector2(24, 608)
	objective_label.add_theme_color_override("font_color", Color("#b3c4d6"))
	objective_label.text = "WASD / 方向键：移动    E：互动"
	layer.add_child(objective_label)
	interaction_hint_label = Label.new()
	interaction_hint_label.position = Vector2.ZERO
	interaction_hint_label.add_theme_color_override("font_color", Color("#dff5ff"))
	interaction_hint_label.add_theme_color_override("font_shadow_color", Color("#0b1521"))
	interaction_hint_label.add_theme_constant_override("shadow_offset_x", 2)
	interaction_hint_label.add_theme_constant_override("shadow_offset_y", 2)
	interaction_hint_label.add_theme_font_size_override("font_size", 15)
	interaction_hint_label.text = "E 互动"
	interaction_hint_label.hide()
	layer.add_child(interaction_hint_label)
	dialogue_label = Label.new()
	dialogue_label.position = Vector2(230, 505)
	dialogue_label.size = Vector2(700, 86)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.add_theme_color_override("font_color", Color("#ffffff"))
	dialogue_label.add_theme_color_override("font_shadow_color", Color("#000000"))
	dialogue_label.add_theme_constant_override("shadow_offset_x", 2)
	dialogue_label.add_theme_constant_override("shadow_offset_y", 2)
	dialogue_label.add_theme_font_size_override("font_size", 19)
	layer.add_child(dialogue_label)
	s06_take_button = Button.new()
	s06_take_button.text = "拿走原件"
	s06_take_button.position = Vector2(430, 466)
	s06_take_button.size = Vector2(130, 38)
	s06_take_button.hide()
	s06_take_button.pressed.connect(_choose_take_sensor)
	layer.add_child(s06_take_button)
	s06_leave_button = Button.new()
	s06_leave_button.text = "留下展品"
	s06_leave_button.position = Vector2(585, 466)
	s06_leave_button.size = Vector2(130, 38)
	s06_leave_button.hide()
	s06_leave_button.pressed.connect(_choose_leave_sensor)
	layer.add_child(s06_leave_button)
	_update_ui()

func _build_gallery() -> void:
	var room := Node2D.new()
	room.name = "TruthGallery"
	add_child(room)
	# Outer walls.
	_add_wall(Vector2(576, 94), Vector2(1088, 20))
	_add_wall(Vector2(576, 590), Vector2(1088, 20))
	# The left boundary is the visible, collision-backed gate; the right boundary
	# is aligned to the visible dead-end wall instead of leaving a side gap.
	_add_wall(Vector2(1098, 342), Vector2(26, 496))
	# The S01 gate is the door at the far end of the first hall; this keeps the
	# space behind it closed until the entrance observations are done.
	gate_body = _add_wall(Vector2(1050, 315), Vector2(24, 410))
	west_exit_body = _add_wall(Vector2(32, 315), Vector2(24, 410))
	# Objects are simple drawn nodes with interaction rectangles.
	mirror_node = _make_object("Mirror", Vector2(1010, 410), Color("#426b82"), "镜子")
	painting_node = _make_object("Painting", Vector2(710, 205), Color("#b17c52"), "画作展厅")
	window_node = _make_object("Window", Vector2(840, 462), Color("#5ca8c7"), "《窗》")
	interactables = [
		{"name":"Mirror", "position":Vector2(1010,520), "radius":96.0},
		{"name":"Painting", "position":Vector2(710,205), "radius":90.0},
		{"name":"Window", "position":Vector2(840,520), "radius":105.0}
	]
	s01_interactables = [
		# Each sits under its wall exhibit; hint_y puts the E hint just below the title card.
		{"name":"EntrancePhoto", "position":Vector2(180,440), "radius":55.0, "hint_y":376.0},
		{"name":"CommunityMap", "position":Vector2(310,440), "radius":45.0, "hint_y":376.0},
		{"name":"ClockBack", "position":Vector2(470,440), "radius":40.0, "hint_y":376.0},
		{"name":"ClockForward", "position":Vector2(585,440), "radius":40.0, "hint_y":376.0},
		{"name":"ExitDoor", "position":Vector2(720,440), "radius":45.0, "hint_y":376.0},
		{"name":"NotAnEye", "position":Vector2(910,440), "radius":55.0, "hint_y":376.0}
	]
	s02_interactables = [
		# Left to right: 《镜中镜》, 《光》, guard, 《机械维纳斯》, then the dead-end mirror.
		# Each piece hints at this hall's puzzle (mirrors, split light, what is missing).
		{"name":"MirrorInMirror", "position":Vector2(260,440), "radius":50.0, "hint_y":376.0},
		{"name":"SculptureLight", "position":Vector2(420,440), "radius":35.0, "hint_y":398.0},
		{"name":"SecurityGuard", "position":Vector2(545,440), "radius":35.0, "hint_y":258.0},
		{"name":"SculptureVenus", "position":Vector2(700,440), "radius":40.0, "hint_y":398.0},
		{"name":"DeadEnd", "position":Vector2(983,440), "radius":38.0, "hint_y":398.0}
	]
	# S03 happens in the same hall as S02; the dead-end mirror is now the puzzle.
	s03_interactables = []
	for item in s02_interactables:
		var s03_item: Dictionary = item.duplicate()
		if s03_item.name == "DeadEnd":
			s03_item.name = "Mirror"
		s03_interactables.append(s03_item)
	s04_interactables = [
		# Graham enters from the right (she walked left through the S03 wall), so right to left:
		# visitor, 《窗》, lamp, switch, restorer, pigment station beside the restorer.
		{"name":"Visitor", "position":Vector2(740,440), "radius":45.0, "hint_y":258.0},
		{"name":"BlockedWindow", "position":Vector2(590,440), "radius":45.0, "hint_y":376.0},
		{"name":"Lamp", "position":Vector2(500,440), "radius":28.0, "hint_y":376.0},
		{"name":"LightSwitch", "position":Vector2(440,440), "radius":25.0, "hint_y":376.0},
		{"name":"PigmentStation", "position":Vector2(340,440), "radius":35.0, "hint_y":398.0},
		{"name":"Restorer", "position":Vector2(255,440), "radius":40.0, "hint_y":258.0},
		# Exhibits of this room: the restorer studies 《星空下的神经》; the visitor's side has
		# the face that changes (《戴珍珠耳机的少女》) and the pair's own work (《双生》).
		{"name":"StarryNerves", "position":Vector2(150,440), "radius":45.0, "hint_y":376.0},
		{"name":"PearlHeadphones", "position":Vector2(870,440), "radius":40.0, "hint_y":376.0},
		{"name":"SculptureTwins", "position":Vector2(950,440), "radius":28.0, "hint_y":398.0}
	]
	s05_interactables = [
		{"name":"Window", "position":Vector2(590,440), "radius":60.0, "hint_y":376.0}
	]
	s06_interactables = [
		# Left to right: 《盲》, 《凝视》, the 《看见》 platform, and 《窗》 on the wall (where Graham came in).
		{"name":"Blind", "position":Vector2(180,440), "radius":35.0, "hint_y":398.0},
		{"name":"Gaze", "position":Vector2(330,440), "radius":40.0, "hint_y":398.0},
		{"name":"CentralPlatform", "position":Vector2(560,440), "radius":60.0, "hint_y":398.0},
		{"name":"EscapeWindow", "position":Vector2(900,440), "radius":50.0, "hint_y":376.0}
	]
	# S07 items belong to one of the two revisited rooms.
	s07_interactables = [
		{"name":"ReturnWindow", "position":Vector2(590,440), "radius":60.0, "hint_y":376.0, "room":"gallery"},
		{"name":"ReturnMirror", "position":Vector2(983,440), "radius":38.0, "hint_y":398.0, "room":"hall"}
	]
	for item in s02_interactables:
		if item.name != "DeadEnd":
			var s07_item: Dictionary = item.duplicate()
			s07_item["room"] = "hall"
			s07_interactables.append(s07_item)
	for item in s04_interactables:
		if item.name in ["StarryNerves", "PearlHeadphones", "SculptureTwins"]:
			var s07_gallery_item: Dictionary = item.duplicate()
			s07_gallery_item["room"] = "gallery"
			s07_interactables.append(s07_gallery_item)
	s08_interactables = [
		{"name":"FinalWindow", "position":Vector2(590,440), "radius":60.0, "hint_y":376.0}
	]
	queue_redraw()

func _draw() -> void:
	if scene_state == "gallery":
		_draw_gallery(self)
	elif scene_state == "theater":
		_draw_theater(self)

func _draw_gallery(room: Node2D) -> void:
	if scene_state != "gallery":
		return
	draw_rect(Rect2(0, 58, 1152, 590), Color("#202b3a"))
	draw_rect(Rect2(62, 120, 980, 408), Color("#344354"))
	draw_rect(Rect2(84, 140, 936, 368), Color("#2b3747"))
	# Floor: Graham walks here, below the hung exhibits (player.ground_top keeps her off the wall).
	draw_rect(Rect2(84, 372, 936, 136), Color("#333f4c"))
	draw_rect(Rect2(1085, 112, 26, 408), Color("#202c3a"), true)
	if LEGACY_PROTOTYPE_FLOW_ENABLED:
		draw_string(ThemeDB.fallback_font, Vector2(108, 175), "镜子展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#98aabd"))
		draw_string(ThemeDB.fallback_font, Vector2(610, 175), "画作展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#98aabd"))
	if LEGACY_PROTOTYPE_FLOW_ENABLED and blue_lake_active:
		if not mirror_solved and chalk_hover_target == "Mirror":
			draw_circle(Vector2(205, 230), 62.0, Color(0.55, 0.88, 1.0, 0.13))
			draw_arc(Vector2(205, 230), 62.0, 0.0, TAU, 32, Color("#bfe8ff"), 2.0)
		if mirror_solved:
			draw_dashed_line(Vector2(375, 250), Vector2(470, 250), Color("#bfe8ff"), 3.0, 8.0)
			draw_string(ThemeDB.fallback_font, Vector2(360, 230), "镜中隐藏的门", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#bfe8ff"))
		if mirror_solved and not handle_found and chalk_hover_target == "Window":
			draw_circle(Vector2(840, 205), 68.0, Color(0.4, 0.85, 1.0, 0.12))
			draw_arc(Vector2(840, 205), 68.0, 0.0, TAU, 32, Color("#bfe8ff"), 2.0)
		if mirror_solved and handle_found and not window_open:
			draw_string(ThemeDB.fallback_font, Vector2(748, 330), "这里可以打开", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f6e5a7"))
	# Subtle blue traces lead from the starting side toward the first-intervention area.
	if LEGACY_PROTOTYPE_FLOW_ENABLED:
		var guide_alpha := 0.10 + (sin(Time.get_ticks_msec() * 0.003) + 1.0) * 0.035
		draw_line(Vector2(640, 420), blue_lake_trigger_position, Color(0.45, 0.82, 0.95, guide_alpha), 3.0)
		draw_circle(blue_lake_trigger_position, 20.0 + (sin(Time.get_ticks_msec() * 0.003) + 1.0) * 3.0, Color(0.45, 0.82, 0.95, guide_alpha))
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S01_ENABLED and s01_active:
		_draw_s01_gallery()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S02_ENABLED and s02_active:
		_draw_s02_gallery()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S03_ENABLED and s03_active:
		_draw_s03_gallery()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S04_ENABLED and s04_active:
		_draw_s04_gallery()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S05_ENABLED and s05_active:
		_draw_s05_gallery()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S06_ENABLED and s06_active:
		_draw_s06_gallery()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S07_ENABLED and s07_active:
		_draw_s07_gallery()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S08_ENABLED and s08_active:
		_draw_s08_gallery()
	if window_open:
		draw_rect(Rect2(800, 165, 80, 80), Color("#8cdcff"), true)
		draw_circle(Vector2(840, 205), 50, Color(0.8, 0.95, 1.0, 0.35))
	if LEGACY_PROTOTYPE_FLOW_ENABLED:
		_draw_object(mirror_node, "Mirror", Color("#426b82"), "镜子展厅")
		_draw_object(painting_node, "Painting", Color("#b17c52"), "画作展厅")
		_draw_object(window_node, "Window", Color("#5ca8c7"), "《窗》")

func _draw_s01_gallery() -> void:
	# The entrance hall is the warm, old end of the gallery (plan B: warm and worn at the
	# entrance, colder and emptier deeper in). Ceiling lights, a runner carpet.
	draw_rect(Rect2(84, 140, 936, 232), Color(0.32, 0.24, 0.16, 0.55), true)
	draw_rect(Rect2(84, 372, 936, 136), Color(0.26, 0.19, 0.13, 0.6), true)
	draw_rect(Rect2(120, 404, 880, 66), Color("#5e2a26"), true)
	draw_rect(Rect2(126, 409, 868, 56), Color("#c19a5b"), false, 2.0)
	for x in [180.0, 310.0, 525.0, 910.0]:
		draw_rect(Rect2(x - 10.0, 142, 20, 7), Color("#b9a27a"), true)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6.0, 149), Vector2(x + 6.0, 149), Vector2(x + 70.0, 330), Vector2(x - 70.0, 330)]), Color(1.0, 0.86, 0.6, 0.05))
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "入口大厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d8c7a8"))
	_draw_s01_photo()
	_draw_s01_map()
	_draw_s01_clocks()
	_draw_s01_door()
	_draw_s01_not_an_eye()
	draw_string(ThemeDB.fallback_font, Vector2(112, 492), "入口", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#a8957a"))

func _draw_s01_figure(at: Vector2, body: Color, scale_factor: float = 1.0) -> void:
	draw_circle(at, 3.2 * scale_factor, Color("#d9c3a5"))
	draw_rect(Rect2(at.x - 3.5 * scale_factor, at.y + 3.0 * scale_factor, 7.0 * scale_factor, 11.0 * scale_factor), body, true)

func _draw_s01_photo() -> void:
	var r := S01_PHOTO_RECT
	draw_rect(r, Color("#c9ae78"), true)
	var inner := r.grow(-8.0)
	var tone: Color = [Color("#8a7350"), Color("#a9bac4"), Color("#5f6466")][s01_era]
	draw_rect(inner, tone, true)
	# The photographed hall is this hall: the same door, the same hook.
	var door := Rect2(inner.position + Vector2(52, 28), Vector2(20, 34))
	draw_rect(door, Color("#7a4a30") if s01_era == 2 else Color("#2c3640"), true)
	var hook := door.position + Vector2(10, -6)
	draw_line(hook, hook + Vector2(0, 3), Color("#2a2a2a"), 1.5)
	var floor_y := inner.end.y - 10.0
	draw_line(Vector2(inner.position.x, floor_y + 4.0), Vector2(inner.end.x, floor_y + 4.0), tone.darkened(0.3), 1.0)
	if s01_era == 0:
		# Opening day: the guard hangs the keys by the door; the restorer and the visitor are in the crowd.
		draw_circle(hook + Vector2(0, 5), 2.2, Color("#f0cf6a"))
		_draw_s01_figure(Vector2(door.end.x + 9.0, floor_y - 14.0), Color("#566b7a"))
		_draw_s01_figure(Vector2(inner.position.x + 14.0, floor_y - 14.0), Color("#b26b5e"))
		_draw_s01_figure(Vector2(inner.position.x + 30.0, floor_y - 14.0), Color("#6c8290"))
		for i in range(3):
			_draw_s01_figure(Vector2(inner.end.x - 28.0 + i * 9.0, floor_y - 13.0), Color("#7a6a5a"), 0.9)
		draw_string(ThemeDB.fallback_font, inner.position + Vector2(4, 12), "OPENING", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.95, 0.8, 0.8))
	elif s01_era == 1:
		# Winter: snow outside a high window, coats, and someone up a ladder fixing the ceiling light.
		var win := Rect2(inner.position + Vector2(8, 8), Vector2(22, 16))
		draw_rect(win, Color("#dfe9ef"), true)
		for i in range(6):
			draw_circle(win.position + Vector2(3 + (i * 7) % 20, 3 + (i * 5) % 13), 1.2, Color.WHITE)
		var ladder_x := inner.end.x - 22.0
		draw_line(Vector2(ladder_x, floor_y + 3.0), Vector2(ladder_x + 6.0, inner.position.y + 20.0), Color("#5b4a3a"), 1.5)
		draw_line(Vector2(ladder_x + 10.0, floor_y + 3.0), Vector2(ladder_x + 12.0, inner.position.y + 20.0), Color("#5b4a3a"), 1.5)
		draw_rect(Rect2(ladder_x + 2.0, inner.position.y + 4.0, 12, 4), Color("#f4e7b8"), true)
		_draw_s01_figure(Vector2(ladder_x + 8.0, inner.position.y + 14.0), Color("#4b79a8"), 0.9)
		_draw_s01_figure(Vector2(inner.position.x + 20.0, floor_y - 14.0), Color("#3b3f46"))
	else:
		# Many years later: nobody, dust, a cobweb in the corner.
		for i in range(14):
			draw_circle(inner.position + Vector2((i * 37) % int(inner.size.x), (i * 23) % int(inner.size.y)), 0.9, Color(1, 1, 1, 0.35))
		draw_line(inner.position, inner.position + Vector2(16, 0), Color(1, 1, 1, 0.3), 1.0)
		draw_line(inner.position, inner.position + Vector2(0, 14), Color(1, 1, 1, 0.3), 1.0)
		draw_line(inner.position, inner.position + Vector2(12, 10), Color(1, 1, 1, 0.3), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 2, 340), "《美术馆开幕日》", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))

func _draw_s01_map() -> void:
	var r := S01_MAP_RECT
	draw_rect(r, Color("#8a6f4a"), true)
	draw_rect(r.grow(-4.0), Color("#d8cfb5"), true)
	# The Truth Community seen from above, shaped like a brain; "you are here" at the back of the head.
	var c := r.get_center() + Vector2(0, 2)
	var pts := PackedVector2Array()
	for i in range(28):
		var a := TAU * i / 28.0
		var rr := 30.0 + 3.0 * sin(a * 5.0)
		pts.append(c + Vector2(cos(a) * rr, sin(a) * rr * 0.72))
	pts.append(pts[0])
	draw_polyline(pts, Color("#6b5a44"), 1.5)
	draw_line(c + Vector2(-4, -20), c + Vector2(2, 18), Color("#6b5a44"), 1.0)
	draw_arc(c + Vector2(-12, -2), 8.0, 0.5, 2.6, 8, Color("#6b5a44"), 1.0)
	draw_arc(c + Vector2(12, 4), 8.0, 3.6, 5.8, 8, Color("#6b5a44"), 1.0)
	draw_circle(c + Vector2(26, 6), 3.0, Color("#c4372f"))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 2, 340), "导览图", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))

func _draw_s01_clock_eye(center: Vector2, turns: int, melt: int) -> void:
	if melt >= 3:
		# The right eye is gone: an empty, dark socket and a long dried trail.
		draw_circle(center, 15.0, Color("#3d4441"))
		return
	# Every eye in this painting is already sagging; the right one gets worse each turn past the last era.
	var drip := 26.0 + melt * 22.0
	draw_colored_polygon(PackedVector2Array([center + Vector2(-13, 4), center + Vector2(13, 4), center + Vector2(4, drip), center + Vector2(0, drip + 5.0), center + Vector2(-4, drip)]), Color("#ece6d6"))
	draw_circle(center, 15.0, Color("#ece6d6"))
	draw_arc(center, 15.0, 0.0, TAU, 24, Color("#8f8a7c"), 1.0)
	# The pupil is a clock: two hands.
	var a := -PI / 2.0 + turns * 0.9
	draw_line(center, center + Vector2(cos(a), sin(a)) * 11.0, Color("#2b2b2b"), 2.0)
	draw_line(center, center + Vector2(cos(a * 3.0), sin(a * 3.0)) * 7.0, Color("#2b2b2b"), 2.5)
	draw_circle(center, 2.0, Color("#2b2b2b"))

func _draw_s01_clocks() -> void:
	var r := S01_CLOCKS_RECT
	draw_rect(r, Color("#c7a56f"), true)
	var inner := r.grow(-8.0)
	draw_rect(inner, Color("#7d8776"), true)
	draw_rect(Rect2(inner.position.x, inner.end.y - 26.0, inner.size.x, 26.0), Color("#a48d68"), true)
	draw_line(Vector2(inner.position.x + 60, inner.end.y - 26), Vector2(inner.position.x + 120, inner.position.y + 30), Color("#4f5d60"), 5.0)
	_draw_s01_clock_eye(S01_CLOCK_BACK, -(1 - s01_era) if s01_era <= 1 else 0, 0)
	_draw_s01_clock_eye(S01_CLOCK_FORWARD, s01_era + s01_melt, s01_melt)
	if s01_melt >= 1:
		# It runs out of the frame and down the wall.
		var top := Vector2(S01_CLOCK_FORWARD.x, r.end.y)
		var bottom := Vector2(S01_CLOCK_FORWARD.x + 2.0, minf(r.end.y + 30.0 * s01_melt, 378.0))
		draw_line(top, bottom, Color("#ece6d6"), 4.0)
	if s01_melt >= 2:
		draw_set_transform(Vector2(S01_CLOCK_FORWARD.x + 4.0, 384), 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, 14.0 + s01_melt * 7.0, Color("#e2dccb"))
		draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 44, 318), "《观看的永恒》", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))

func _draw_s01_door() -> void:
	var r := S01_DOOR_RECT
	draw_rect(r, Color("#445866"), true)
	var inner := r.grow_individual(-8, -8, -8, 0)
	if s01_gate_open:
		draw_rect(inner, Color("#0e1620"), true)
		draw_colored_polygon(PackedVector2Array([inner.position + Vector2(0, inner.size.y), inner.end, inner.end + Vector2(18, 40), Vector2(inner.position.x - 18.0, inner.end.y + 40.0)]), Color(0.75, 0.85, 0.95, 0.10))
	else:
		draw_rect(inner, Color("#1c2934"), true)
		draw_circle(Vector2(inner.end.x - 8.0, inner.get_center().y + 6.0), 3.5, Color("#d9c997"))
	if s01_melt >= 2:
		for i in range(5 + s01_melt * 3):
			var p := inner.position + Vector2(fmod(i * 23.0, inner.size.x), fmod(i * 31.0, inner.size.y))
			draw_circle(p, 3.0 + (i % 3), Color(0.55, 0.3, 0.16, 0.85))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 26, r.position.y + 20), "出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#d9d4b6"))
	# The hook sits between the two eyes, where a nose would be.
	draw_line(S01_HOOK + Vector2(-5, -4), S01_HOOK + Vector2(5, -4), Color("#8d7b5c"), 2.0)
	draw_arc(S01_HOOK + Vector2(0, 2), 4.0, 0.0, PI, 8, Color("#b59f73"), 2.0)
	if s01_key_on_hook and not s01_gate_open:
		draw_circle(S01_HOOK + Vector2(0, 9), 4.0, Color("#f0cf6a"))
		draw_line(S01_HOOK + Vector2(0, 12), S01_HOOK + Vector2(0, 22), Color("#f0cf6a"), 2.5)
		draw_line(S01_HOOK + Vector2(0, 20), S01_HOOK + Vector2(4, 20), Color("#f0cf6a"), 2.0)

func _draw_s01_not_an_eye() -> void:
	var r := S01_EYE_RECT
	draw_rect(r, Color("#c7a56f"), true)
	draw_rect(r.grow(-8.0), Color("#777f78"), true)
	var c := S01_EYE_CENTER
	if s01_eyelid_closed:
		draw_line(c + Vector2(-34, 0), c + Vector2(34, 0), Color("#2b2b2b"), 2.0)
		draw_arc(c + Vector2(0, -30), 45.0, 0.75, PI - 0.75, 16, Color("#cdb99c"), 3.0)
	else:
		draw_set_transform(c, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, 34.0, Color("#ece6d6"))
		draw_set_transform(Vector2.ZERO)
		# It follows Graham; when she is stuck it looks at what she has missed.
		var to := s01_eye_look - c
		var pupil := c + to.normalized() * minf(to.length() * 0.06, 13.0) * Vector2(1.0, 0.55) if to.length() > 0.1 else c
		draw_circle(pupil, 10.0, Color("#55718a"))
		draw_circle(pupil, 4.5, Color("#151a1f"))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 22, r.end.y - 14), "这不是一只眼睛", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8e2d0"))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x - 6, 318), "《这不是一只眼睛》", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))

func _draw_s02_gallery() -> void:
	# One continuous hall, left to right: entrance, 《镜中镜》, 《光》, guard, 《机械维纳斯》, dead-end mirror.
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "第二展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	# The hall's own entrance: the loop keeps returning Graham to this doorway.
	draw_rect(Rect2(92, 262, 50, 110), Color("#445866"), true)
	draw_rect(Rect2(99, 270, 36, 102), Color("#0e1620"), true)
	draw_string(ThemeDB.fallback_font, Vector2(98, 392), "入口", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#8fa1af"))
	# 《镜中镜》: a painted mirror whose reflection has one more door than the room.
	draw_rect(Rect2(210, 230, 100, 100), Color("#b49464"), true)
	draw_rect(Rect2(218, 238, 84, 84), Color("#66747a"), true)
	draw_rect(Rect2(240, 252, 40, 56), Color("#426b82"), true)
	draw_rect(Rect2(250, 264, 20, 32), Color("#5d8aa2"), true)
	draw_rect(Rect2(255, 278, 10, 18), Color(0.85, 0.94, 1.0, 0.75), true)
	draw_string(ThemeDB.fallback_font, Vector2(228, 352), "《镜中镜》", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	# Sculptures stand on pedestals against the wall; titles sit on the floor edge in front.
	draw_rect(Rect2(400, 326, 40, 46), Color("#4b5966"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(420, 290), Vector2(437, 324), Vector2(403, 324)]), Color("#c9dff0"))
	draw_line(Vector2(437, 312), Vector2(458, 300), Color(0.95, 0.6, 0.6, 0.7), 2.0)
	draw_line(Vector2(437, 314), Vector2(460, 310), Color(0.6, 0.9, 0.6, 0.7), 2.0)
	draw_line(Vector2(437, 316), Vector2(458, 320), Color(0.6, 0.7, 1.0, 0.7), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(402, 392), "《光》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	# The guard stands at the back of the floor and points right, toward the dead end.
	draw_circle(Vector2(545, 322), 16.0, Color("#bba88c"))
	draw_rect(Rect2(528, 338, 34, 60), Color("#566b7a"), true)
	draw_line(Vector2(562, 352), Vector2(592, 340), Color("#bba88c"), 5.0)
	draw_string(ThemeDB.fallback_font, Vector2(526, 290), "保安 →", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	draw_rect(Rect2(680, 326, 40, 46), Color("#4b5966"), true)
	draw_circle(Vector2(700, 272), 12.0, Color("#9aa6ab"))
	draw_circle(Vector2(704, 270), 3.0, Color("#1b2633"))
	draw_rect(Rect2(690, 284, 20, 42), Color("#9aa6ab"), true)
	draw_rect(Rect2(710, 288, 8, 20), Color("#9aa6ab"), true)
	draw_string(ThemeDB.fallback_font, Vector2(658, 392), "《机械维纳斯》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	# The far right is where the guard sends you; past the sculptures the floor loops back.
	draw_rect(Rect2(930, 372, 90, 136), Color("#2c3845"), true)
	# The end wall carries a full-length mirror, not an invisible barrier.
	draw_rect(Rect2(950, 200, 66, 172), Color("#c2a875"), true)
	draw_rect(Rect2(957, 207, 52, 158), Color("#426b82"), true)
	draw_line(Vector2(962, 230), Vector2(1004, 340), Color(0.8, 0.95, 1.0, 0.5), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(947, 392), "尽头的镜子", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))

func _draw_s03_gallery() -> void:
	# Same hall as S02. The mirror reflects it reversed: its far (left) wall has a door reality lacks.
	_draw_s02_gallery()
	draw_rect(Rect2(989, 300, 12, 34), Color(0.75, 0.9, 1.0, 0.35), false, 2.0)
	if blue_lake_active and not s03_mirror_intervened:
		var glow := 0.75 if chalk_hover_target == "Mirror" else 0.4
		draw_circle(S03_MIRROR_CENTER, 55.0, Color(0.55, 0.88, 1.0, 0.11))
		draw_arc(S03_MIRROR_CENTER, 55.0, 0.0, TAU, 32, Color(0.75, 0.91, 1.0, glow), 2.0)
		draw_rect(Rect2(987, 298, 16, 38), Color("#bfe8ff"), false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(770, 196), "镜中有门，现实中没有。", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#bfe8ff"))
	if s03_mirror_intervened:
		# The chalk copies the mirrored door onto the real left wall.
		var pulse := 0.5 + (sin(Time.get_ticks_msec() * 0.004) + 1.0) * 0.2
		draw_rect(Rect2(62, 262, 22, 110), Color(0.75, 0.92, 1.0, 0.18), true)
		draw_rect(Rect2(62, 262, 22, 110), Color(0.75, 0.92, 1.0, pulse), false, 3.0)
		draw_line(Vector2(240, 470), Vector2(160, 470), Color(0.85, 0.95, 1.0, 0.6), 3.0)
		draw_line(Vector2(160, 470), Vector2(176, 460), Color(0.85, 0.95, 1.0, 0.6), 3.0)
		draw_line(Vector2(160, 470), Vector2(176, 480), Color(0.85, 0.95, 1.0, 0.6), 3.0)

func _draw_s04_gallery() -> void:
	# Right to left: arrival wall, visitor, 《窗》, lamp + switch, restorer, pigment station.
	draw_string(ThemeDB.fallback_font, Vector2(640, 175), "画作展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	draw_string(ThemeDB.fallback_font, Vector2(200, 175), "修复区", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	# The chalk door Graham came through, now on this room's right wall.
	draw_rect(Rect2(998, 262, 22, 110), Color(0.75, 0.92, 1.0, 0.35), false, 2.0)
	# 《窗》 hangs between the visitor and the restorer.
	draw_rect(Rect2(540, 225, 100, 120), Color("#c7a56f"), true)
	draw_rect(Rect2(549, 234, 82, 102), Color("#725e50"), true)
	if s04_lights_off:
		draw_rect(Rect2(555, 240, 70, 90), Color("#182633"), true)
	else:
		draw_circle(Vector2(590, 285), 20.0, Color("#d9b575"))
		draw_line(Vector2(562, 318), Vector2(618, 252), Color("#b6a280"), 6.0)
	if not (s05_active or s08_active):
		# In S05/S08 the operable 《窗》 is drawn over this one with its own title.
		draw_string(ThemeDB.fallback_font, Vector2(570, 362), "《窗》", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))
	# The sensor lamp is a wall spotlight aimed at 《窗》; the switch sits beside it.
	draw_rect(Rect2(490, 316, 20, 6), Color("#8796a2"), true)
	draw_line(Vector2(500, 316), Vector2(500, 306), Color("#b8c7d4"), 3.0)
	draw_circle(S04_LAMP_CENTER, 11.0, Color("#e5d9ae"))
	if not s04_lights_off:
		draw_colored_polygon(PackedVector2Array([Vector2(506, 294), Vector2(512, 306), Vector2(560, 300), Vector2(552, 250)]), Color(1.0, 0.95, 0.75, 0.12))
	draw_string(ThemeDB.fallback_font, Vector2(479, 362), "感应灯", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	draw_rect(Rect2(430, 296, 20, 30), Color("#5e6b73"), true)
	draw_circle(Vector2(440, 306), 4.0, Color("#d1c49d"))
	draw_string(ThemeDB.fallback_font, Vector2(427, 362), "灯控", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b8c7d4"))
	if blue_lake_active and not s04_lamp_observed:
		var glow := 0.8 if chalk_hover_target == "Lamp" else 0.4
		draw_circle(S04_LAMP_CENTER, 32.0, Color(0.45, 0.85, 1.0, 0.14))
		draw_arc(S04_LAMP_CENTER, 32.0, 0.0, TAU, 24, Color(0.75, 0.91, 1.0, glow), 2.0)
	# Visitor first: she studies 《窗》, then steps aside once she recognizes Graham.
	var visitor_x := 772.0 if s04_visitor_moved else 708.0
	draw_circle(Vector2(visitor_x, 322), 16.0, Color("#d3b28e"))
	draw_rect(Rect2(visitor_x - 18.0, 338, 36, 60), Color("#6c8290"), true)
	draw_circle(Vector2(visitor_x - 6.0, 319), 2.5, Color("#5a6670"))
	draw_circle(Vector2(visitor_x + 6.0, 319), 2.5, Color("#5a6670"))
	draw_string(ThemeDB.fallback_font, Vector2(visitor_x - 20.0, 290), "参观者", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	# 《星空下的神经》: the painting the restorer keeps studying.
	draw_rect(Rect2(100, 230, 100, 100), Color("#b49464"), true)
	draw_rect(Rect2(108, 238, 84, 84), Color("#66747a"), true)
	draw_arc(Vector2(150, 280), 26.0, 0.0, 5.2, 24, Color("#c8c1a8"), 3.0)
	draw_arc(Vector2(150, 280), 13.0, 1.0, 6.0, 18, Color("#c8c1a8"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(105, 352), "《星空下的神经》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	# The restorer faces it, brush raised; the pigment station stands right beside her.
	draw_circle(Vector2(255, 322), 16.0, Color("#cba98a"))
	draw_rect(Rect2(237, 338, 36, 60), Color("#b26b5e"), true)
	draw_rect(Rect2(243, 352, 24, 10), Color("#e3c77d"), true)
	draw_line(Vector2(237, 350), Vector2(216, 330), Color("#bfe8ff"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(235, 290), "修复师", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	draw_rect(Rect2(312, 340, 56, 32), Color("#665d50"), true)
	draw_rect(Rect2(316, 332, 48, 10), Color("#c8b98d"), true)
	draw_circle(Vector2(340, 324), 7.0, Color("#bfe8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(316, 392), "荧光剂台", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	# 《戴珍珠耳机的少女》 and 《双生》 on the visitor's side of the room.
	draw_rect(Rect2(825, 240, 90, 90), Color("#b49464"), true)
	draw_rect(Rect2(832, 247, 76, 76), Color("#66747a"), true)
	draw_circle(Vector2(870, 280), 14.0, Color("#c9bda1"))
	draw_circle(Vector2(883, 282), 4.0, Color("#e8e2d0"))
	draw_string(ThemeDB.fallback_font, Vector2(816, 352), "《戴珍珠耳机的少女》", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))
	draw_rect(Rect2(930, 326, 40, 46), Color("#4b5966"), true)
	draw_circle(Vector2(942, 304), 12.0, Color("#b9aa8d"))
	draw_circle(Vector2(958, 304), 12.0, Color("#b9aa8d"))
	draw_string(ThemeDB.fallback_font, Vector2(932, 392), "《双生》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	if s04_visitor_observed and not s04_visitor_recognized:
		draw_string(ThemeDB.fallback_font, Vector2(visitor_x - 42.0, 236), "她仍在寻找你。", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#d6e8f0"))
	if s04_lights_off:
		# Lights out: the room goes dark, only the fluorescent traces keep shining.
		draw_rect(Rect2(84, 140, 936, 368), Color(0.02, 0.04, 0.08, 0.55), true)
		draw_circle(Vector2(590, 285), 26.0, Color(0.52, 0.9, 0.98, 0.72))
		draw_arc(Vector2(590, 285), 38.0, 0.0, TAU, 32, Color("#bfe8ff"), 3.0)
	if s04_active and s04_pigment_applied:
		draw_arc(Vector2(player.position.x, player.position.y - 4.0), 23.0, 0.0, TAU, 24, Color("#bfe8ff"), 2.0)
	if s04_active and s04_visitor_moved:
		draw_string(ThemeDB.fallback_font, Vector2(540, 205), "这幅画里有光。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))

func _draw_s05_gallery() -> void:
	# S05 is the first authored intervention: a painting becomes operable as a window.
	# It is the same 《窗》 that hung between the visitor and the restorer in S04, on the wall.
	var w := S05_WINDOW_CENTER
	_draw_s04_gallery()
	var original_window_position := window_node.position
	window_node.position = w
	_draw_object(window_node, "Window", Color("#5ca8c7"), "《窗》")
	window_node.position = original_window_position
	if s05_window_observed and not s05_window_handle_found:
		draw_string(ThemeDB.fallback_font, w + Vector2(75, -30), "它看起来像一幅画。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#aab8c2"))
	if blue_lake_active and not s05_window_open:
		var glow := 0.8 if chalk_hover_target == "Window" else 0.4
		draw_circle(w, 66.0, Color(0.4, 0.85, 1.0, 0.11))
		draw_arc(w, 66.0, 0.0, TAU, 32, Color(0.75, 0.91, 1.0, glow), 2.0)
	if s05_window_handle_found and not s05_window_open:
		draw_circle(w + Vector2(34, 0), 8.0, Color("#f6e5a7"))
		draw_arc(w + Vector2(34, 0), 18.0, 0.0, TAU, 24, Color("#bfe8ff"), 2.0)
		draw_string(ThemeDB.fallback_font, w + Vector2(75, -30), "把手显现了。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d6e8f0"))
	if s05_window_open:
		draw_rect(Rect2(w - Vector2(58, 58), Vector2(116, 116)), Color("#8cdcff"), true)
		draw_rect(Rect2(w - Vector2(48, 48), Vector2(96, 96)), Color("#172c3c"), true)
		draw_circle(w, 42.0, Color(0.25, 0.72, 0.95, 0.24))
		draw_string(ThemeDB.fallback_font, w + Vector2(75, -30), "窗后的空间通向中央展台。", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#bfe8ff"))
		draw_string(ThemeDB.fallback_font, w + Vector2(75, -5), "这不是出口。", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f6e5a7"))

func _draw_s06_gallery() -> void:
	# S06 starts with an empty platform. Two ways of seeing, laid on top of each other, reveal it.
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "中央展台", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	# 《窗》 seen from behind: Graham came through it from the gallery.
	var w := S06_WINDOW_CENTER
	draw_rect(Rect2(w - Vector2(58, 58), Vector2(116, 116)), Color("#d2b46e"), true)
	draw_rect(Rect2(w - Vector2(48, 48), Vector2(96, 96)), Color("#172c3c"), true)
	draw_circle(w, 40.0, Color(0.25, 0.72, 0.95, 0.22))
	draw_string(ThemeDB.fallback_font, w + Vector2(-20, 82), "《窗》", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))
	# 《盲》: a figure without eyes.
	draw_rect(Rect2(160, 326, 40, 46), Color("#4b5966"), true)
	draw_circle(Vector2(180, 300), 16.0, Color("#79868b"))
	draw_rect(Rect2(170, 314, 20, 12), Color("#79868b"), true)
	draw_string(ThemeDB.fallback_font, Vector2(165, 392), "《盲》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	# 《凝视》: the mechanical eye; its pupil shows where it is looking.
	var eye := S06_GAZE_EYE
	var gaze_target := _s06_gaze_target()
	var look := (gaze_target - eye).normalized()
	draw_rect(Rect2(eye.x - 20.0, 326, 40, 46), Color("#4b5966"), true)
	draw_circle(eye, 24.0, Color("#64747b"))
	draw_circle(eye + look * 9.0, 11.0, Color("#172431"))
	draw_string(ThemeDB.fallback_font, Vector2(eye.x - 21.0, 392), "《凝视》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	# 《看见》: an empty plinth; the plaque reads "看见即存在".
	var c := S06_PLATFORM_CENTER
	draw_rect(Rect2(c.x - 66.0, 310, 132, 8), Color("#566674"), true)
	draw_rect(Rect2(c.x - 60.0, 318, 120, 54), Color("#3a4654"), true)
	draw_string(ThemeDB.fallback_font, Vector2(c.x - 35.0, 350), "看见即存在", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d6c79f"))
	draw_string(ThemeDB.fallback_font, Vector2(c.x - 21.0, 392), "《看见》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	if blue_lake_active and not s06_sensor_revealed:
		# Blue Lake can see 《凝视》's line of sight; it turns warm when it lands on the platform.
		var on_platform := s06_gaze_index == 3
		var beam := Color(0.96, 0.85, 0.55, 0.65) if on_platform else Color(0.75, 0.91, 1.0, 0.35)
		draw_line(eye + look * 24.0, gaze_target, beam, 3.0)
		var eye_glow := 0.8 if chalk_hover_target == "Gaze" else 0.4
		draw_arc(eye, 34.0, 0.0, TAU, 28, Color(0.75, 0.91, 1.0, eye_glow), 2.0)
		if not s06_contour_seen:
			var glow := 0.8 if chalk_hover_target == "Sensor" else 0.4
			draw_circle(c, 48.0, Color(0.35, 0.82, 0.96, 0.10))
			draw_arc(c, 48.0, 0.0, TAU, 32, Color(0.75, 0.91, 1.0, glow), 2.0)
	if not s06_sensor_revealed:
		if s06_contour_seen:
			# Blue Lake's layer: outline only.
			draw_arc(c, 22.0, 0.0, TAU, 32, Color("#bfe8ff"), 2.0)
			draw_arc(c, 10.0, 0.0, TAU, 24, Color("#bfe8ff"), 1.5)
		if s06_gaze_index == 3:
			# 《凝视》's layer: colour only.
			draw_circle(c, 20.0, Color(0.95, 0.72, 0.45, 0.30))
		var note := "普通视角：展台是空的。"
		if s06_contour_seen and s06_gaze_index != 3:
			note = "只有轮廓。还差一层。"
		elif s06_gaze_index == 3 and not s06_contour_seen:
			note = "《凝视》只看见一团颜色。"
		elif blue_lake_active:
			note = "蓝湖视角：空白处好像有东西。"
		draw_string(ThemeDB.fallback_font, Vector2(c.x - 90.0, 214), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff") if blue_lake_active or s06_contour_seen else Color("#aab8c2"))
	else:
		draw_circle(c, 22.0, Color("#6ec9e8"))
		draw_circle(c, 10.0, Color("#dff8ff"))
		draw_arc(c, 32.0, -0.7, 2.9, 24, Color("#bfe8ff"), 3.0)
		draw_rect(Rect2(c.x - 14.0, c.y + 22.0, 28, 6), Color("#8796a2"), true)
		if not s06_stolen:
			draw_string(ThemeDB.fallback_font, Vector2(c.x - 40.0, 214), "看见即存在。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))
	if s06_chase_active:
		draw_circle(Vector2(s06_guard_chase_x, 392), 16.0, Color("#bba88c"))
		draw_rect(Rect2(s06_guard_chase_x - 17.0, 408, 34, 56), Color("#566b7a"), true)
		draw_string(ThemeDB.fallback_font, Vector2(s06_guard_chase_x - 28.0, 368), "保安追来", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f0c6a5"))

## Where 《凝视》 is looking right now.
func _s06_gaze_target() -> Vector2:
	match s06_gaze_index:
		0:
			return S06_GAZE_EYE + Vector2(30, -110)
		1:
			return Vector2(196, 300)
		2:
			return S06_GAZE_EYE + Vector2(60, 150)
		_:
			return S06_PLATFORM_CENTER

func _draw_s07_gallery() -> void:
	# S07 walks back through the real rooms; each keeps a second layer only Blue Lake can read.
	if s07_room == "hall":
		_draw_s02_gallery()
		draw_rect(Rect2(62, 262, 22, 110), Color(0.75, 0.92, 1.0, 0.35), false, 2.0)
		if blue_lake_active and not s07_mirror_trace_found:
			var glow := 0.8 if chalk_hover_target == "ReturnMirror" else 0.4
			draw_circle(S03_MIRROR_CENTER, 55.0, Color(0.55, 0.88, 1.0, 0.11))
			draw_arc(S03_MIRROR_CENTER, 55.0, 0.0, TAU, 32, Color(0.75, 0.91, 1.0, glow), 2.0)
		if s07_mirror_trace_found:
			for i in range(3):
				var y := 240.0 + i * 36.0
				draw_line(Vector2(962, y), Vector2(1004, y + 14.0), Color("#dff5ff"), 2.0)
			draw_string(ThemeDB.fallback_font, Vector2(770, 196), "镜面上留着第二层痕迹。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))
	else:
		_draw_s04_gallery()
		var w := S05_WINDOW_CENTER
		if blue_lake_active and s07_mirror_trace_found and not s07_window_trace_found:
			var glow := 0.8 if chalk_hover_target == "ReturnWindow" else 0.4
			draw_circle(w, 66.0, Color(0.4, 0.85, 1.0, 0.11))
			draw_arc(w, 66.0, 0.0, TAU, 32, Color(0.75, 0.91, 1.0, glow), 2.0)
		if s07_window_trace_found:
			draw_line(w + Vector2(-50, -20), w + Vector2(50, -20), Color("#dff5ff"), 3.0)
			draw_line(w + Vector2(-50, 20), w + Vector2(50, 20), Color("#dff5ff"), 3.0)
			draw_string(ThemeDB.fallback_font, w + Vector2(75, -30), "《窗》回应了第二次观看。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))

func _draw_s08_gallery() -> void:
	# The true exit is the same 《窗》 on the same wall, now opening outward.
	var w := S05_WINDOW_CENTER
	_draw_s04_gallery()
	var original_window_position := window_node.position
	window_node.position = w
	_draw_object(window_node, "Window", Color("#5ca8c7"), "《窗》")
	window_node.position = original_window_position
	if blue_lake_active and not s08_window_open:
		var glow := 0.8 if chalk_hover_target == "FinalWindow" else 0.4
		draw_circle(w, 66.0, Color(0.4, 0.85, 1.0, 0.11))
		draw_arc(w, 66.0, 0.0, TAU, 32, Color(0.75, 0.91, 1.0, glow), 2.0)
	if not s08_window_open:
		draw_string(ThemeDB.fallback_font, w + Vector2(75, -30), "窗的边界已经不一样。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d6e8f0"))
	else:
		draw_rect(Rect2(w - Vector2(58, 58), Vector2(116, 116)), Color("#cdefff"), true)
		draw_rect(Rect2(w - Vector2(48, 48), Vector2(96, 96)), Color("#8bcfe9"), true)
		draw_circle(w, 46.0, Color(0.96, 0.99, 1.0, 0.46))
		draw_string(ThemeDB.fallback_font, w + Vector2(75, -30), "外部的光从窗后进来。", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f6e5a7"))

func _make_object(kind: String, pos: Vector2, color: Color, label: String) -> Node2D:
	var node := Node2D.new()
	node.name = kind
	node.position = pos
	add_child(node)
	return node

func _draw_object(node: Node2D, kind: String, color: Color, label: String) -> void:
	if scene_state != "gallery":
		return
	if kind == "Mirror":
		draw_set_transform(node.position)
		draw_rect(Rect2(-55, -72, 110, 144), Color("#172431"), true)
		draw_rect(Rect2(-47, -64, 94, 128), color, true)
		draw_line(Vector2(-40, -50), Vector2(40, 50), Color(0.8, 0.95, 1.0, 0.32), 4.0)
	elif kind == "Painting":
		draw_set_transform(node.position)
		draw_rect(Rect2(-68, -54, 136, 108), Color("#c8a46d"), true)
		draw_rect(Rect2(-58, -44, 116, 88), color, true)
		draw_circle(Vector2(-18, -6), 16, Color("#d2c59e"))
		draw_line(Vector2(-45, 28), Vector2(42, -24), Color("#5b3a37"), 8.0)
	elif kind == "Window":
		draw_set_transform(node.position)
		draw_rect(Rect2(-58, -58, 116, 116), Color("#d2b46e"), true)
		draw_rect(Rect2(-48, -48, 96, 96), color, true)
		draw_line(Vector2(0, -48), Vector2(0, 48), Color("#d7f3ff"), 4.0)
		draw_line(Vector2(-48, 0), Vector2(48, 0), Color("#d7f3ff"), 4.0)
	draw_circle(Vector2(39, 0), 4.0, Color("#f6e5a7"))
	draw_string(ThemeDB.fallback_font, Vector2(-42, 82), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#e9eef4"))
	draw_set_transform(Vector2.ZERO)

func _build_player() -> void:
	player = GrahamSteel.new()
	player.name = "GrahamSteel"
	player.position = Vector2(190, 430)
	add_child(player)

func _add_wall(pos: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	gallery_bodies.append(body)
	return body

func _build_cursor() -> void:
	chalk_cursor = CursorScript.new()
	add_child(chalk_cursor)

func _build_transition() -> void:
	transition = TransitionScript.new()
	transition.finished.connect(_finish_transition)
	add_child(transition)

func _build_blue_lake_transform() -> void:
	blue_lake_transform = BlueLakeTransformScript.new()
	blue_lake_transform.finished.connect(_finish_blue_lake_transformation)
	add_child(blue_lake_transform)

func _start_blue_lake_intro() -> void:
	blue_lake_intro_started = true
	player.input_locked = true
	_show_dialogue("Blue Lake：\n……等等。")
	await get_tree().create_timer(0.75).timeout
	_show_dialogue("Blue Lake：\n这里有东西。")
	await get_tree().create_timer(0.85).timeout
	_show_dialogue("Blue Lake：\n你看不见。")
	await get_tree().create_timer(0.85).timeout
	blue_lake_intro_ready = true
	player.input_locked = false
	_show_space_prompt()

func _show_space_prompt() -> void:
	if not interaction_hint_label:
		return
	space_prompt_visible = true
	interaction_hint_label.text = "SPACE  使用蓝湖"
	interaction_hint_label.position = Vector2(500, 455)
	interaction_hint_label.show()
	var prompt_timer := get_tree().create_timer(4.0)
	prompt_timer.timeout.connect(_hide_space_prompt)

func _hide_space_prompt() -> void:
	space_prompt_visible = false
	if interaction_hint_label and not blue_lake_active:
		interaction_hint_label.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not LEGACY_PROTOTYPE_FLOW_ENABLED:
		if event.is_action_pressed("blue_lake"):
			if S03_ENABLED and s03_active:
				_try_toggle_s03_blue_lake()
				return
			if S04_ENABLED and s04_active:
				_try_toggle_s04_blue_lake()
				return
			if S05_ENABLED and s05_active:
				_try_toggle_s05_blue_lake()
				return
			if S06_ENABLED and s06_active:
				_try_toggle_s06_blue_lake()
				return
			if S07_ENABLED and s07_active:
				_try_toggle_s07_blue_lake()
				return
			if S08_ENABLED and s08_active:
				_try_toggle_s08_blue_lake()
				return
		if event.is_action_pressed("interact"):
			if S01_ENABLED and s01_active:
				_try_s01_interact()
			elif S02_ENABLED and s02_active:
				_try_s02_interact()
			elif S03_ENABLED and s03_active:
				_try_s03_interact()
			elif S04_ENABLED and s04_active:
				_try_s04_interact()
			elif S05_ENABLED and s05_active:
				_try_s05_interact()
			elif S06_ENABLED and s06_active:
				_try_s06_interact()
			elif S07_ENABLED and s07_active:
				_try_s07_interact()
			elif S08_ENABLED and s08_active:
				_try_s08_interact()
		return
	if event.is_action_pressed("blue_lake"):
		if not blue_lake_active and not blue_lake_intro_ready and not blue_lake_transform_completed:
			return
		if not blue_lake_active and not blue_lake_transform_completed:
			_start_blue_lake_transformation()
			return
		blue_lake_active = not blue_lake_active
		chalk_cursor.set_active(blue_lake_active)
		visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
		_show_dialogue("蓝湖模式：" + ("开启。你现在看见蓝湖所看到的世界。" if blue_lake_active else "关闭。"))
		_update_ui()
	if event.is_action_pressed("interact"):
		_try_interact()

func _start_blue_lake_transformation() -> void:
	blue_lake_intro_ready = false
	player.input_locked = true
	_hide_space_prompt()
	_show_dialogue("Blue Lake：\n看。")
	blue_lake_transform.play()

func _finish_blue_lake_transformation() -> void:
	blue_lake_active = true
	blue_lake_transform_completed = true
	blue_lake_intro_ready = true
	visual_mode = "Chalk Interaction"
	chalk_cursor.set_active(true)
	player.input_locked = false
	if s03_active:
		_show_dialogue("Blue Lake：现在，把粉笔移到镜子上，点左键。")
	elif s04_active:
		_show_dialogue("Blue Lake：用荧光照一下那盏灯。")
	elif s05_active:
		_show_dialogue("Blue Lake：现在，把粉笔移到《窗》上，点左键。")
	elif s06_active:
		_show_dialogue("Blue Lake：现在，" + _s06_chalk_hint())
	elif s07_active:
		_show_dialogue("Blue Lake：同一个地方，第二次看会不一样。" + _s07_chalk_hint())
	elif s08_active:
		_show_dialogue("Blue Lake：这次不一样。把粉笔移到《窗》上，点左键。")
	else:
		_show_dialogue("Blue Lake 已经变成粉笔。")
	_update_ui()
	queue_redraw()

func _try_toggle_s03_blue_lake() -> void:
	if not s03_mirror_observed:
		_show_dialogue("Blue Lake：先看清楚。镜子里的东西还没有被你确认。")
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_show_dialogue("Blue Lake：看。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_show_dialogue("Blue Lake：" + ("把粉笔移到镜子上，点左键，描出镜中的门。" if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _try_toggle_s04_blue_lake() -> void:
	if not s04_pigment_applied:
		_show_dialogue("Blue Lake：先向修复师借一点荧光剂。")
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("Blue Lake：让我看看那盏灯。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_show_dialogue("Blue Lake：" + ("把 Chalk Cursor 移到灯上，再点击。" if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not blue_lake_active or transition_started:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if LEGACY_PROTOTYPE_FLOW_ENABLED:
			_try_chalk_interaction()
		elif S03_ENABLED and s03_active:
			_try_s03_chalk_interaction()
		elif S04_ENABLED and s04_active:
			_try_s04_chalk_interaction()
		elif S05_ENABLED and s05_active:
			_try_s05_chalk_interaction()
		elif S06_ENABLED and s06_active:
			_try_s06_chalk_interaction()
		elif S07_ENABLED and s07_active:
			_try_s07_chalk_interaction()
		elif S08_ENABLED and s08_active:
			_try_s08_chalk_interaction()

func _try_interact() -> void:
	if scene_state != "gallery" or transition_started:
		return
	var nearest := ""
	var best := 99999.0
	for item in interactables:
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item.name
	if nearest == "Mirror":
		if blue_lake_active:
			_show_dialogue("移动 Chalk Cursor 到镜子的特殊区域，再点击左键。")
		else:
			_interact_mirror()
	elif nearest == "Painting":
		_interact_painting()
	elif nearest == "Window":
		if blue_lake_active:
			_show_dialogue("移动 Chalk Cursor 到《窗》的特殊区域，再点击左键。")
		else:
			_interact_window()
	else:
		_show_dialogue("这里没有可以调查的东西。")

func _try_s01_interact() -> void:
	if not s01_active or scene_state != "gallery" or transition_started or s01_eyelid_closed:
		return
	var nearest := _get_nearest_s01_interactable()
	if nearest.is_empty():
		return
	s01_idle_time = 0.0
	var object_name: String = nearest.get("name", "")
	if object_name == "EntrancePhoto":
		chapter_state.mark_event(&"s01_photo_observed")
		_show_dialogue(_s01_photo_text())
	elif object_name == "CommunityMap":
		chapter_state.mark_event(&"s01_map_observed")
		_show_dialogue("真理社区导览图。整个社区的轮廓……像一颗大脑。\n“你在这里”的红点，在后脑勺的位置。")
	elif object_name == "ClockBack" or object_name == "ClockForward":
		_s01_turn_clock(object_name == "ClockForward")
	elif object_name == "ExitDoor":
		_s01_use_door()
	elif object_name == "NotAnEye":
		_s01_look_at_eye()

func _s01_photo_text() -> String:
	if s01_era == 0:
		return "照片回到了真正的开幕日。人很多。\n一位保安正把一串钥匙挂到门边的钩子上。人群里还有一位拿着画笔的修复师，和一位一直盯着画看的参观者。"
	if s01_era == 1:
		var first := "" if chapter_state.has_story_event(&"s01_saw_self_in_photo") else "\n梯子上修顶灯的那个人……是我？那年冬天，我在这里修过灯。"
		chapter_state.mark_story_event(&"s01_saw_self_in_photo")
		return "《美术馆开幕日》。照片里的大厅，和这里一模一样。我们就是从照片里进来的。\n……可照片里在下雪。" + first
	return "多年以后。照片里的大厅空了，到处是灰。\n门边的钩子上什么也没有。"

func _s01_turn_clock(forward: bool) -> void:
	if not s01_clocks_seen:
		s01_clocks_seen = true
		chapter_state.mark_event(&"s01_clocks_observed")
		_show_dialogue("《观看的永恒》：融化的不是时钟，而是眼球。两只眼球的瞳孔，都是钟表的指针。\n说明牌写着：时间在此失去意义。（指针好像拨得动。）")
		return
	if not forward:
		if s01_era == 0:
			_show_dialogue("左边那只眼睛的指针拨不动了。\n再往前，这里还不存在。")
			return
		s01_era -= 1
		var text := "左边那只眼睛里，指针往回走了一格。\n旧照片里的光变了。"
		if s01_melt > 0:
			text += "\n可右边那只眼睛……倒不回去了。"
		_show_dialogue(text)
	else:
		if s01_era < 2:
			s01_era += 1
			_show_dialogue("右边那只眼睛里，指针往前走了一格。\n旧照片里的光变了。")
		else:
			s01_melt += 1
			chapter_state.mark_event(StringName("s01_melt_%d" % s01_melt))
			if s01_melt == 1:
				_show_dialogue("指针转不动了，可你还在拨。\n右边的眼球开始往下淌。")
			elif s01_melt == 2:
				_show_dialogue("眼球滴到了地上。\n门上的铁件，生出了锈。")
			else:
				_show_dialogue("眼球化成了地上的一滩。\n门……锈穿了。")
				_complete_s01("future")
	s01_key_on_hook = s01_era == 0 and not s01_gate_open
	if s01_key_on_hook:
		chapter_state.mark_event(&"s01_key_appeared")
	queue_redraw()

func _s01_use_door() -> void:
	chapter_state.mark_event(&"s01_exit_area_observed")
	if s01_gate_open:
		_enter_s02_after_s01()
		return
	if s01_key_on_hook:
		_complete_s01("past")
		return
	if s01_melt >= 1:
		_show_dialogue("门还锁着。门上的锈越来越多了。")
	elif chapter_state.has_story_event(&"s01_door_tried"):
		_show_dialogue("门锁着。门边的钩子是空的。\nBlue Lake：照片里的大厅和这里一模一样……照片里的钥匙呢？")
	else:
		chapter_state.mark_story_event(&"s01_door_tried")
		_show_dialogue("出口。门锁着。\n门边有一个空钩子。格雷汉：钥匙本该挂在这里。")

func _s01_look_at_eye() -> void:
	s01_eye_visits += 1
	chapter_state.mark_event(&"s01_second_exhibit_observed")
	if s01_eye_visits == 1:
		_show_dialogue("《这不是一只眼睛》：画面是一只眼睛，说明牌却说“这不是一只眼睛”。\n……它在看我。")
	elif s01_eye_visits == 2:
		_show_dialogue("它的目光" + ("跟着你走。" if s01_idle_time < S01_HINT_AFTER else "落在别处。") + "\n画框的边上，好像能摸到一片薄薄的眼皮。")
	else:
		s01_eye_visits = 1
		_s01_close_eyelid()

## Easter egg: pull the eyelid shut and the whole gallery goes dark; only the clock-eyes tick.
func _s01_close_eyelid() -> void:
	s01_eyelid_closed = true
	player.input_locked = true
	chapter_state.mark_story_event(&"s01_easter_eyelid")
	if not is_instance_valid(s01_dark_overlay):
		s01_dark_overlay = ColorRect.new()
		s01_dark_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
		s01_dark_overlay.size = Vector2(1152, 648)
		s01_dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var layer := dialogue_label.get_parent()
		layer.add_child(s01_dark_overlay)
		layer.move_child(s01_dark_overlay, dialogue_label.get_index())
	s01_dark_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(s01_dark_overlay, "modulate:a", 0.97, 0.6)
	_show_dialogue("（你伸手，把它的眼皮拉了下来。）\n……滴答。")
	await get_tree().create_timer(1.6).timeout
	_show_dialogue("……滴答。……滴答。\n整座美术馆都闭上了眼睛。")
	await get_tree().create_timer(1.8).timeout
	var back := create_tween()
	back.tween_property(s01_dark_overlay, "modulate:a", 0.0, 0.7)
	await back.finished
	s01_eyelid_closed = false
	player.input_locked = false
	_show_dialogue("它又睁开了，像什么都没发生过。")

func _update_s01(delta: float) -> void:
	if not s01_active or not player or scene_state != "gallery":
		return
	s01_idle_time += delta
	var target := player.position
	if s01_idle_time >= S01_HINT_AFTER and not s01_completion_started:
		target = _s01_hint_target()
	s01_eye_look = s01_eye_look.lerp(target, minf(1.0, delta * 3.0))
	# Step back to the far left and the wall reads as a face.
	if not s01_face_noticed and player.position.x <= 250.0 and s01_clocks_seen and s01_eye_visits > 0 and chapter_state.has_event(&"s01_exit_area_observed"):
		s01_face_noticed = true
		chapter_state.mark_story_event(&"s01_face_noticed")
		_show_dialogue("Blue Lake：退远一点看——那两幅画是一双眼睛，钩子是鼻子，门是嘴。\n这面墙在看我们。")

## Where 《这不是一只眼睛》 looks when Graham is stuck.
func _s01_hint_target() -> Vector2:
	if s01_key_on_hook:
		return S01_HOOK
	if not chapter_state.has_event(&"s01_photo_observed"):
		return S01_PHOTO_RECT.get_center()
	if not s01_clocks_seen:
		return S01_CLOCKS_RECT.get_center()
	if s01_melt > 0:
		return S01_DOOR_RECT.get_center()
	return S01_CLOCK_BACK if s01_era > 0 else S01_PHOTO_RECT.get_center()

## The door opens one of two ways: the opening-day key (past) or rusted through (future).
func _complete_s01(route: String) -> void:
	if s01_completion_started:
		return
	s01_completion_started = true
	s01_exit_route = route
	s01_key_on_hook = false
	chapter_state.mark_event(&"s01_no_obvious_exit_recognized")
	chapter_state.mark_event(StringName("s01_exit_by_" + route))
	chapter_state.learn(&"s01_need_to_leave")
	chapter_state.set_player_goal(&"find_a_way_out")
	chapter_state.complete_slice(ChapterState.Slice.S01_ENTER)
	s01_gate_open = true
	if is_instance_valid(gate_body):
		gate_body.collision_layer = 0
		gate_body.collision_mask = 0
	if route == "past":
		_show_dialogue("格雷汉从钩子上取下钥匙，插进锁孔。门开了。\n这里没有一个正常的出口。我要继续往里面走。")
	else:
		_show_dialogue("眼球化成了地上的一滩。门锁锈穿了，一推就开。\n格雷汉：时间在这里真的没有意义。……我要继续往里面走。")
	objective_label.text = "我要出去。"
	_update_ui()
	queue_redraw()

func _enter_s02_after_s01() -> void:
	if not s01_completion_started or s02_active:
		return
	s01_active = false
	s02_active = true
	s02_loop_count = 0
	s02_loop_triggered = false
	chapter_state.advance_to(ChapterState.Slice.S02_LOST)
	chapter_state.set_map_state(&"Museum_S02_Loop")
	chapter_state.set_player_goal(&"explore_the_gallery")
	chapter_state.mark_story_event(&"s02_started")
	# Through the S01 door Graham arrives at this hall's entrance, on the left.
	player.position.x = 120.0
	objective_label.text = "继续探索美术馆"
	_show_dialogue("蓝湖：往里面走吧。保安应该在前面。")
	_update_ui()
	queue_redraw()

func _try_s02_interact() -> void:
	if not s02_active or scene_state != "gallery" or transition_started:
		return
	var nearest := _get_nearest_s02_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	if object_name == "SecurityGuard":
		chapter_state.mark_event(&"s02_guard_observed")
		chapter_state.mark_event(&"s02_guard_directed_right")
		if s02_loop_count > 0:
			_show_dialogue("保安再次指向最右侧。\n格雷汉：你刚才也是这么说的。我们已经回来过一次了。")
		else:
			_show_dialogue("保安指向最右侧。\n保安：一直往最右边走，就能找到出口。")
	elif object_name == "DeadEnd":
		chapter_state.mark_event(&"s02_dead_end_observed")
		_show_dialogue("右边的通路明明能走到尽头。\n尽头的墙上挂着一面镜子。")
	else:
		_describe_exhibit(object_name)
	_try_complete_s02()

## Paintings and sculptures read the same wherever they are (re)visited.
func _describe_exhibit(object_name: String) -> void:
	if object_name == "MirrorInMirror":
		_show_dialogue("《镜中镜》：画里挂着一面镜子。\n镜子里映出的房间，比画外的房间多一扇门。")
	elif object_name == "PearlHeadphones":
		_show_dialogue("《戴珍珠耳机的少女》：机器人少女戴着耳机。\n换一个角度，她的脸就变了。")
	elif object_name == "StarryNerves":
		_show_dialogue("《星空下的神经》：漩涡不是星云，而是传导中的神经纤维。")
	elif object_name == "SculptureGaze":
		_show_dialogue("《凝视》：巨大的机械眼球追随着展厅里的动静。")
	elif object_name == "SculptureVenus":
		_show_dialogue("《机械维纳斯》：她缺少一只手臂和一只眼睛。\n格雷汉：……有点像阿姨。")
	elif object_name == "SculptureTwins":
		_show_dialogue("《双生》：两个头颅背对着彼此。说明牌写着共同创作者。")
	elif object_name == "SculptureLight":
		_show_dialogue("《光》：棱镜把一道白光拆成不同颜色。")
	elif object_name == "SculptureBlind":
		_show_dialogue("《盲》：没有眼睛的人像，安静地面对展厅。\n格雷汉：阿姨缺的，也是看东西的那一部分。")

func _try_s03_interact() -> void:
	if not s03_active or scene_state != "gallery" or transition_started:
		return
	var nearest := _get_nearest_s03_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	if object_name == "SecurityGuard":
		_show_dialogue("保安指向最右边：一直往右走，就能找到出口。")
	elif object_name != "Mirror":
		_describe_exhibit(object_name)
	elif not s03_mirror_observed:
		s03_mirror_observed = true
		chapter_state.mark_event(&"s03_mirror_observed")
		_show_dialogue("镜子里倒映着整个展厅。最左边那面墙上，镜子里多了一扇门。\nBlue Lake：现实里那里没有门……按 Space，让我来看。")
		_show_space_prompt()
	elif not s03_mirror_intervened:
		_show_dialogue("Blue Lake：按 Space，用我的眼睛看镜子。")
		_show_space_prompt()
	else:
		_show_dialogue("Blue Lake：反过来走。背对镜子，走到最左边的墙。")
	queue_redraw()

func _try_s03_chalk_interaction() -> void:
	if chalk_hover_target != "Mirror" or s03_mirror_intervened:
		return
	s03_mirror_intervened = true
	_hide_space_prompt()
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Mirror Layer"
	chapter_state.mark_event(&"s03_mirror_structure_revealed")
	# The chalk copies the mirrored door onto the real left wall, which now lets Graham through.
	if is_instance_valid(west_exit_body):
		west_exit_body.collision_layer = 0
		west_exit_body.collision_mask = 0
	_show_dialogue("格雷汉：也许要相信镜子里的，而不是眼睛看到的。\nBlue Lake：反过来走？")
	objective_label.text = "背对镜子，走到最左边的墙"
	_update_ui()
	queue_redraw()

func _try_s04_interact() -> void:
	if not s04_active or scene_state != "gallery" or transition_started:
		return
	var nearest := _get_nearest_s04_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	if object_name == "Visitor":
		if not s04_visitor_observed:
			s04_visitor_observed = true
			chapter_state.mark_event(&"s04_visitor_observed")
			_show_dialogue("参观者：很高兴认识你。\n（她继续看着展品，似乎没有认出你。）")
		elif not s04_visitor_recognized and s04_pigment_applied and s04_lamp_observed:
			s04_visitor_recognized = true
			chapter_state.mark_event(&"s04_visitor_recognized_by_light")
			_show_dialogue("参观者：你是光，老朋友。\n啊，是你！我刚才没认出来。")
		elif s04_visitor_recognized:
			if not s04_visitor_moved:
				s04_visitor_moved = true
				_show_dialogue("参观者：我和修复师一起创作了《双生》。她负责轮廓，我负责色彩。\n这幅画里有光。让我挪开，你看看。")
			else:
				_show_dialogue("参观者：修复师负责轮廓，我负责色彩。\n她正在那边修复作品。")
		else:
			_show_dialogue("参观者：很高兴认识你。\n她又把你当成第一次见面的人。")
	elif object_name == "Restorer":
		if not s04_visitor_observed:
			# The visitor is met first; until then the restorer stays bent over her work.
			_show_dialogue("修复师盯着《星空下的神经》，没有抬头。")
		elif not s04_restorer_observed:
			s04_restorer_observed = true
			chapter_state.mark_event(&"s04_restorer_observed")
			_show_dialogue("修复师：我和那位参观者共同创作了《双生》。\n我负责轮廓，她负责色彩。她有脸盲，记人靠别的线索。")
		elif not s04_pigment_borrowed:
			s04_pigment_borrowed = true
			chapter_state.mark_event(&"s04_fluorescent_pigment_borrowed")
			_show_dialogue("修复师：借你一点荧光剂。涂在身上，蓝湖也许能看见它。")
		else:
			_show_dialogue("修复师：荧光剂可以帮助你被她认出来。")
	elif object_name == "PigmentStation":
		if not s04_pigment_borrowed:
			_show_dialogue("先问修复师借荧光剂。")
		else:
			s04_pigment_applied = true
			chapter_state.mark_event(&"s04_pigment_applied")
			_show_dialogue("你把荧光剂涂在了身上。按 Space 使用蓝湖，观察那盏灯。")
			_show_space_prompt()
	elif object_name == "Lamp":
		if not s04_pigment_applied:
			_show_dialogue("感应灯。我修过这套灯，它会跟着观众的视线变亮。")
		elif not s04_lamp_observed:
			_show_dialogue("灯本身看不出什么。\nBlue Lake：按 Space 让我来看，再用粉笔点一下灯。")
			_show_space_prompt()
		else:
			_show_dialogue("灯边有荧光的痕迹。旁边的灯控可以把它关掉。")
	elif object_name == "LightSwitch":
		if not s04_lamp_observed:
			_show_dialogue("先用蓝湖观察灯具，再操作灯控。")
		elif not s04_lights_off:
			s04_lights_off = true
			chapter_state.mark_event(&"s04_lights_turned_off")
			_show_dialogue("灯光熄灭了。画面里有一处仍在发亮。")
		else:
			s04_lights_off = false
			_show_dialogue("灯光重新亮起，画作恢复了普通颜色。")
	elif object_name == "BlockedWindow":
		if not s04_visitor_moved:
			_show_dialogue("参观者还站在《窗》前。")
		elif not s04_lights_off:
			_show_dialogue("灯亮着时，它只是一幅普通的画。")
		else:
			chapter_state.mark_event(&"s04_window_unblocked")
			chapter_state.learn(&"s04_seeing_is_not_objective")
			chapter_state.complete_slice(ChapterState.Slice.S04_VISITOR)
			_show_dialogue("参观者：这幅画里有光。你可以看看它。\nBlue Lake：原来认出一个人，不一定要看见他的脸。")
			objective_label.text = "调查《窗》"
			_enter_s05_after_s04()
	elif object_name in ["StarryNerves", "PearlHeadphones", "SculptureTwins"]:
		_describe_exhibit(object_name)
	queue_redraw()

func _try_s04_chalk_interaction() -> void:
	if chalk_hover_target != "Lamp" or not s04_pigment_applied:
		return
	s04_lamp_observed = true
	_hide_space_prompt()
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Lamp Layer"
	chapter_state.mark_event(&"s04_lamp_observed_in_blue_lake")
	_show_dialogue("Blue Lake：灯边有荧光的痕迹。把灯关掉，再看那幅画。")
	_update_ui()
	queue_redraw()

func _try_s05_interact() -> void:
	if not s05_active or scene_state != "gallery" or transition_started:
		return
	var nearest := _get_nearest_s05_interactable()
	if nearest.is_empty():
		return
	if not s05_window_observed:
		s05_window_observed = true
		chapter_state.mark_event(&"s05_window_observed")
		_show_dialogue("这是一幅画。……可它看起来太像一扇真正的窗。\nBlue Lake：按 Space，让我来看。")
		_show_space_prompt()
	elif not blue_lake_active and not s05_window_open:
		_show_dialogue("Blue Lake：你把它看成一幅画。可它不只是一幅画。\n按 Space，用粉笔碰一碰它。")
		_show_space_prompt()
	else:
		_show_dialogue("Blue Lake：你把它看成一幅画。可它不只是一幅画。")
	queue_redraw()

func _try_toggle_s05_blue_lake() -> void:
	if not s05_window_observed:
		_show_dialogue("Blue Lake：先看清楚《窗》。")
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("Blue Lake：看。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_show_dialogue("Blue Lake：" + (("把粉笔移到《窗》上，点左键，打开它。" if s05_window_handle_found else "把粉笔移到《窗》上，点左键。") if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _try_s05_chalk_interaction() -> void:
	if chalk_hover_target != "Window" or s05_window_open:
		return
	if not s05_window_handle_found:
		s05_window_handle_found = true
		blue_lake_active = false
		chalk_cursor.set_active(false)
		visual_mode = "Window Handle Layer"
		chapter_state.mark_event(&"s05_window_handle_found")
		_show_dialogue("Blue Lake：把手一直在那里。只是你以前看不见。\n再按 Space，用粉笔打开它。")
		_show_space_prompt()
		_update_ui()
		queue_redraw()
		return
	s05_window_open = true
	_hide_space_prompt()
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Window Open Layer"
	chapter_state.mark_event(&"s05_window_opened")
	chapter_state.learn(&"s05_blue_lake_can_change_the_world")
	chapter_state.set_player_goal(&"understand_the_window")
	chapter_state.complete_slice(ChapterState.Slice.S05_WINDOW)
	_show_dialogue("Blue Lake：你把一幅画……打开了。\n这不是出口。")
	objective_label.text = "《窗》打开了。它为什么带我们来这里？"
	_update_ui()
	queue_redraw()
	await get_tree().create_timer(1.0).timeout
	_enter_s06_after_s05()

func _enter_s05_after_s04() -> void:
	if s05_active:
		return
	s04_active = false
	s05_active = true
	s05_window_observed = false
	s05_window_handle_found = false
	s05_window_open = false
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	chapter_state.advance_to(ChapterState.Slice.S05_WINDOW)
	chapter_state.set_map_state(&"Museum_S05_Window")
	chapter_state.set_player_goal(&"find_the_window")
	chapter_state.mark_story_event(&"s05_started")
	objective_label.text = "寻找《窗》"
	_show_dialogue("蓝湖：我们是不是该去看看那扇窗？")
	_update_ui()
	queue_redraw()

func _try_s06_interact() -> void:
	if not s06_active or scene_state != "gallery" or transition_started:
		return
	var nearest := _get_nearest_s06_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	if object_name == "EscapeWindow":
		if s06_chase_active:
			s06_stolen = true
			chapter_state.mark_event(&"s06_sensor_taken")
			_show_dialogue("格雷汉：从窗户出去！\nBlue Lake：快，幕布要落下了。")
			_start_transition()
			return
		_show_dialogue("《窗》的背面。我们就是从这里进来的。")
	elif object_name == "Gaze":
		_show_dialogue("《凝视》：巨大的机械眼球追随着展厅里的动静。\n它现在看着" + S06_GAZE_PLACES[s06_gaze_index] + "。")
	elif object_name == "Blind":
		_describe_exhibit("SculptureBlind")
	elif not s06_platform_observed:
		s06_platform_observed = true
		chapter_state.mark_event(&"s06_platform_observed")
		_show_dialogue("《看见》：空展台。说明牌上写着“看见即存在”。\nBlue Lake：可这里什么都没有……按 Space，让我来看。")
		_show_space_prompt()
	elif s06_sensor_revealed:
		if s06_choice_visible or s06_stolen:
			return
		_show_dialogue("格雷汉：这种型号早就停产了，我找了好几年。阿姨正缺这个。\n错过这次，可能再也找不到了……可它是展品。")
		s06_choice_visible = true
		s06_take_button.show()
		s06_leave_button.show()
	elif not s06_contour_seen:
		_show_dialogue("Blue Lake：按 Space，用我的眼睛看展台。")
		_show_space_prompt()
	else:
		_show_dialogue("Blue Lake：我只看见轮廓。这间展厅里还有别的眼睛——《凝视》在看哪里？")
	queue_redraw()

## What Blue Lake says once the Chalk is out in S06, depending on which layer is still missing.
func _s06_chalk_hint() -> String:
	if not s06_contour_seen:
		return "把粉笔移到展台上，点左键。"
	return "只有轮廓还不够。把粉笔移到《凝视》的眼睛上，点左键，让它转过来。"

func _try_toggle_s06_blue_lake() -> void:
	if not s06_platform_observed:
		_show_dialogue("Blue Lake：先观察中央展台。")
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("Blue Lake：看中央展台的空白处。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_show_dialogue("Blue Lake：" + (_s06_chalk_hint() if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _try_s06_chalk_interaction() -> void:
	if s06_sensor_revealed:
		return
	if chalk_hover_target == "Sensor":
		if not s06_contour_seen:
			s06_contour_seen = true
			chapter_state.mark_event(&"s06_contour_seen")
		if s06_gaze_index == 3:
			_reveal_s06_sensor()
			return
		_show_dialogue("Blue Lake：只有一圈轮廓……一种看法还不够，还差一层。\n《凝视》也在看这间展厅。把粉笔移到它的眼睛上。")
	elif chalk_hover_target == "Gaze":
		# Each touch of the Chalk turns the mechanical eye one step.
		s06_gaze_index = (s06_gaze_index + 1) % S06_GAZE_PLACES.size()
		if s06_gaze_index == 3 and s06_contour_seen:
			_reveal_s06_sensor()
			return
		if s06_gaze_index == 3:
			_show_dialogue("《凝视》转向了展台。\nBlue Lake：它只看见一团颜色……用我也看看展台。")
		else:
			_show_dialogue("《凝视》转向了" + S06_GAZE_PLACES[s06_gaze_index] + "。")
	queue_redraw()

func _reveal_s06_sensor() -> void:
	# The mechanical eye and Blue Lake look at the same empty place: outline + colour = the part.
	s06_sensor_revealed = true
	_hide_space_prompt()
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Sensor Layer"
	chapter_state.mark_event(&"s06_visual_sensor_revealed")
	chapter_state.mark_event(&"s06_kent_optical_part_revealed")
	_show_dialogue("Blue Lake：两双眼睛看着同一个地方……这里刚才明明什么都没有。\n格雷汉：等等。这个型号，和阿姨坏掉的那只一模一样。")
	objective_label.text = "再看看展台上的东西"
	_update_ui()
	queue_redraw()

func _choose_take_sensor() -> void:
	if not s06_active or not s06_sensor_revealed:
		return
	s06_choice_visible = false
	s06_take_button.hide()
	s06_leave_button.hide()
	s06_chase_active = true
	s06_stolen = true
	s06_guard_chase_x = maxf(120.0, player.position.x - 250.0)
	chapter_state.mark_event(&"s06_sensor_taken")
	_show_dialogue("格雷汉拿走了原件。保安发现后追了过来！\nBlue Lake：翻窗逃跑！")
	objective_label.text = "跑到窗边"
	queue_redraw()

func _choose_leave_sensor() -> void:
	if not s06_active:
		return
	s06_choice_visible = false
	s06_take_button.hide()
	s06_leave_button.hide()
	chapter_state.mark_event(&"s06_sensor_left_in_place")
	chapter_state.learn(&"s06_invisible_does_not_mean_nonexistent")
	chapter_state.set_player_goal(&"return_and_reobserve")
	chapter_state.complete_slice(ChapterState.Slice.S06_PLATFORM)
	_show_dialogue("格雷汉：……先让它留在这里。\nBlue Lake：同一个地方，可以再看一次。")
	await get_tree().create_timer(0.8).timeout
	_enter_s07_after_s06()

func _enter_s06_after_s05() -> void:
	if s06_active:
		return
	s05_active = false
	s06_active = true
	s06_platform_observed = false
	s06_sensor_revealed = false
	s06_contour_seen = false
	s06_gaze_index = 0
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	# Graham steps through the opened 《窗》 and arrives in front of its back side.
	player.position.x = S06_WINDOW_CENTER.x
	chapter_state.advance_to(ChapterState.Slice.S06_PLATFORM)
	chapter_state.set_map_state(&"Museum_S06_CentralPlatform")
	chapter_state.set_player_goal(&"observe_the_platform")
	chapter_state.mark_story_event(&"s06_started")
	objective_label.text = "观察中央展台"
	_show_dialogue("蓝湖：这不是出口。\n那它为什么带我们来这里？")
	_update_ui()
	queue_redraw()

func _try_s07_interact() -> void:
	if not s07_active or scene_state != "gallery" or transition_started:
		return
	var nearest := _get_nearest_s07_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	if object_name == "ReturnMirror":
		if not s07_mirror_observed:
			s07_mirror_observed = true
			chapter_state.mark_event(&"s07_mirror_area_revisited")
			_show_dialogue("这里我们已经来过。\nBlue Lake：同一个地方，换一种看法会留下不同的痕迹。按 Space。")
			_show_space_prompt()
		elif s07_mirror_trace_found:
			_show_dialogue("镜面上的痕迹已经显现。回《窗》那里去。")
		else:
			_show_dialogue("Blue Lake：按 Space，用我的眼睛再看一次镜子。")
			_show_space_prompt()
	elif object_name == "ReturnWindow":
		if not s07_mirror_trace_found:
			_show_dialogue("Blue Lake：先别急着看《窗》。尽头的镜子那里还有没读完的东西。\n穿过右边的粉笔门。")
			return
		if not s07_window_observed:
			s07_window_observed = true
			chapter_state.mark_event(&"s07_window_area_revisited")
			_show_dialogue("《窗》还是原来的《窗》。\nBlue Lake：但它记得你已经看过一次。按 Space。")
			_show_space_prompt()
		else:
			_show_dialogue("Blue Lake：这一次，你已经知道该看哪里了。")
	else:
		_describe_exhibit(object_name)
	queue_redraw()

## What Blue Lake says once the Chalk is out in S07, depending on the room and progress.
func _s07_chalk_hint() -> String:
	if s07_room == "hall":
		if s07_mirror_trace_found:
			return "镜子已经读完了。回《窗》那里。"
		return "把粉笔移到镜子上，点左键。"
	if s07_mirror_trace_found:
		return "把粉笔移到《窗》上，点左键。"
	return "这里暂时没有新的痕迹。先去尽头的镜子。"

func _try_toggle_s07_blue_lake() -> void:
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("Blue Lake：再看一次。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_show_dialogue("Blue Lake：" + (_s07_chalk_hint() if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _try_s07_chalk_interaction() -> void:
	if chalk_hover_target == "ReturnMirror" and not s07_mirror_trace_found:
		s07_mirror_trace_found = true
		_hide_space_prompt()
		blue_lake_active = false
		chalk_cursor.set_active(false)
		visual_mode = "Return Mirror Layer"
		chapter_state.mark_event(&"s07_mirror_trace_found")
		_show_dialogue("Blue Lake：你漏掉的不是一个物件，是另一种看法。\n回《窗》那里去。")
		objective_label.text = "穿过左边的粉笔门，回到《窗》前"
		_update_ui()
		queue_redraw()
		return
	if chalk_hover_target == "ReturnWindow" and s07_mirror_trace_found and not s07_window_trace_found:
		s07_window_trace_found = true
		_hide_space_prompt()
		blue_lake_active = false
		chalk_cursor.set_active(false)
		visual_mode = "Return Window Layer"
		chapter_state.mark_event(&"s07_window_trace_found")
		chapter_state.learn(&"s07_same_world_can_be_reinterpreted")
		chapter_state.set_player_goal(&"return_to_the_window")
		chapter_state.complete_slice(ChapterState.Slice.S07_RETURN)
		_show_dialogue("Blue Lake：我们是不是该再去看看那扇窗？")
		objective_label.text = "我们是不是该再去看看那扇窗？"
		_update_ui()
		queue_redraw()
		await get_tree().create_timer(0.8).timeout
		_enter_s08_after_s07()

func _try_s08_interact() -> void:
	if not s08_active or scene_state != "gallery" or transition_started:
		return
	var nearest := _get_nearest_s08_interactable()
	if nearest.is_empty():
		return
	if not s08_window_observed:
		s08_window_observed = true
		chapter_state.mark_event(&"s08_window_reobserved")
		_show_dialogue("这次不一样。《窗》已经不像一幅画了。\nBlue Lake：按 Space。")
		_show_space_prompt()
	else:
		_show_dialogue("Blue Lake：你已经知道该怎么打开它。")
	queue_redraw()

func _try_toggle_s08_blue_lake() -> void:
	if not s08_window_observed:
		_show_dialogue("Blue Lake：先再看一次《窗》。")
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("Blue Lake：这次，别只看它。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_show_dialogue("Blue Lake：" + ("把粉笔移到《窗》上，点左键，打开它。" if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _try_s08_chalk_interaction() -> void:
	if chalk_hover_target != "FinalWindow" or s08_window_open or s08_exit_started:
		return
	s08_window_open = true
	s08_exit_started = true
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "True Exit Layer"
	chapter_state.mark_event(&"s08_window_opened")
	chapter_state.learn(&"s08_understands_the_rule")
	chapter_state.complete_slice(ChapterState.Slice.S08_TRUE_EXIT)
	chapter_state.set_player_goal(&"leave_the_gallery")
	_show_dialogue("Blue Lake：看来我们终于看见出口了。")
	objective_label.text = "离开真理美术馆"
	_update_ui()
	queue_redraw()
	# The opened Window hands off to the curtain transition; the gallery becomes the theater.
	await get_tree().create_timer(1.0).timeout
	_start_transition()

func _enter_s08_after_s07() -> void:
	if s08_active:
		return
	s07_active = false
	s08_active = true
	s08_window_observed = false
	s08_window_open = false
	s08_exit_started = false
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	player.position.x = S05_WINDOW_CENTER.x
	chapter_state.advance_to(ChapterState.Slice.S08_TRUE_EXIT)
	chapter_state.set_map_state(&"Museum_S08_TrueExit")
	chapter_state.set_player_goal(&"reopen_the_window")
	chapter_state.mark_story_event(&"s08_started")
	objective_label.text = "再次打开《窗》"
	_show_dialogue("蓝湖：我们是不是该再去看看那扇窗？")
	_update_ui()
	queue_redraw()

func _enter_s07_after_s06() -> void:
	if s07_active:
		return
	s06_active = false
	s07_active = true
	s07_mirror_observed = false
	s07_mirror_trace_found = false
	s07_window_observed = false
	s07_window_trace_found = false
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	# Back through the opened 《窗》 into its room; the lights are on again.
	s07_room = "gallery"
	s04_lights_off = false
	# S07 walks through the hall's chalk door on the left wall; it has been open since S03.
	if is_instance_valid(west_exit_body):
		west_exit_body.collision_layer = 0
		west_exit_body.collision_mask = 0
	player.position.x = S05_WINDOW_CENTER.x
	chapter_state.advance_to(ChapterState.Slice.S07_RETURN)
	chapter_state.set_map_state(&"Museum_S07_Return")
	chapter_state.set_player_goal(&"reobserve_old_areas")
	chapter_state.mark_story_event(&"s07_started")
	objective_label.text = "穿过右边的粉笔门，回到尽头的镜子"
	_show_dialogue("蓝湖：我们是不是漏掉了什么？\n回尽头的镜子那里，再看一次。")
	_update_ui()
	queue_redraw()

func _enter_s04_after_s03() -> void:
	if s04_active:
		return
	s03_active = false
	s04_active = true
	s04_visitor_observed = false
	s04_restorer_observed = false
	s04_pigment_borrowed = false
	s04_pigment_applied = false
	s04_lamp_observed = false
	s04_lights_off = false
	s04_visitor_recognized = false
	s04_visitor_moved = false
	# Through the chalk door Graham steps in at the right wall, walking left.
	player.position.x = 975.0
	chapter_state.advance_to(ChapterState.Slice.S04_VISITOR)
	chapter_state.set_map_state(&"Museum_S04_Visitor")
	chapter_state.set_player_goal(&"recognize_the_visitor")
	chapter_state.mark_story_event(&"s04_started")
	objective_label.text = "观察参观者"
	_show_dialogue("Blue Lake：你刚才相信了一个眼睛看不到的东西。")
	_update_ui()
	queue_redraw()

func _update_s02_loop_trigger() -> void:
	if not s02_active or s02_loop_triggered or scene_state != "gallery" or transition_started:
		return
	if not chapter_state.has_event(&"s02_guard_observed"):
		return
	# Walking on past the sculptures toward the dead end (x >= 945) loops back to the entrance.
	if absf(player.position.x - 975.0) > 30.0:
		return
	s02_loop_triggered = true
	s02_loop_count += 1
	player.position.x = 120.0
	if s02_loop_count == 1:
		_show_dialogue("格雷汉：……这里是入口。\n我们是不是走回来了？")
	else:
		_show_dialogue("格雷汉：又回来了。保安刚才说的还是同一句。\n蓝湖：这已经不是普通的迷路了。")
		_try_complete_s02()
	await get_tree().create_timer(0.8).timeout
	s02_loop_triggered = false

func _try_complete_s02() -> void:
	if s02_completion_started:
		return
	if s02_loop_count < 2:
		return
	if not chapter_state.has_event(&"s02_guard_observed"):
		return
	s02_completion_started = true
	chapter_state.mark_event(&"s02_space_loop_recognized")
	chapter_state.learn(&"s02_space_has_a_problem")
	chapter_state.set_player_goal(&"understand_the_space")
	chapter_state.complete_slice(ChapterState.Slice.S02_LOST)
	objective_label.text = "这里的空间有问题。"
	_update_ui()
	_enter_s03_after_s02()

func _update_route_transitions() -> void:
	if not player or scene_state != "gallery":
		return
	# S07: the chalk doors join the 《窗》 room (right wall) and the hall (left wall).
	if s07_active:
		if s07_room == "gallery" and player.position.x >= 1000.0:
			s07_room = "hall"
			player.position.x = 90.0
			queue_redraw()
		elif s07_room == "hall" and player.position.x <= 50.0:
			s07_room = "gallery"
			player.position.x = 985.0
			queue_redraw()
		return
	# PDF puzzle 1: turn your back on the mirror and walk through the wall that has no door.
	if s03_active and s03_mirror_intervened and not s03_mirror_crossed and player.position.x <= 50.0:
		s03_mirror_crossed = true
		chapter_state.mark_event(&"s03_mirror_crossed")
		chapter_state.learn(&"s03_visual_is_not_reality")
		chapter_state.complete_slice(ChapterState.Slice.S03_MIRROR)
		_enter_s04_after_s03()

func _enter_s03_after_s02() -> void:
	if s03_active:
		return
	s02_active = false
	s03_active = true
	s03_mirror_observed = false
	s03_mirror_intervened = false
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	chapter_state.advance_to(ChapterState.Slice.S03_MIRROR)
	chapter_state.set_map_state(&"Museum_S03_Mirror")
	chapter_state.set_player_goal(&"observe_the_mirror")
	chapter_state.mark_story_event(&"s03_started")
	player.position.x = 120.0
	objective_label.text = "观察镜子"
	_show_dialogue("蓝湖：\n我们又回到了这里。\n……看镜子。")
	_update_ui()
	queue_redraw()

func _get_nearest_s02_interactable() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s02_interactables:
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest

func _get_nearest_s03_interactable() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s03_interactables:
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest

func _get_nearest_s04_interactable() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s04_interactables:
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest

func _get_nearest_s05_interactable() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s05_interactables:
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest

func _get_nearest_s06_interactable() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s06_interactables:
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest

func _get_nearest_s07_interactable() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s07_interactables:
		if item.get("room", "") != s07_room:
			continue
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest

func _get_nearest_s08_interactable() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s08_interactables:
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest

func _try_chalk_interaction() -> void:
	if chalk_hover_target == "Mirror" and not mirror_solved:
		visual_mode = "Mirror Layer"
		mirror_solved = true
		_show_dialogue("粉笔触碰了镜面。镜中隐藏的门显现出来。")
		_update_ui()
		queue_redraw()
		return
	if chalk_hover_target == "Window" and mirror_solved and not handle_found:
		visual_mode = "Window Handle Layer"
		handle_found = true
		_show_dialogue("粉笔沿着窗框划过，把手显现出来。")
		_update_ui()
		queue_redraw()
		return
	if chalk_hover_target == "Window" and mirror_solved and handle_found and not window_open:
		visual_mode = "Open Window Layer"
		window_open = true
		_show_dialogue("粉笔确认了窗的开合线。窗可以打开。")
		_update_ui()
		queue_redraw()
		await get_tree().create_timer(1.0).timeout
		_start_transition()
		return

func _interact_mirror() -> void:
	_show_dialogue("镜子里的展厅方向不对。也许需要用另一种工具观察。")

func _interact_painting() -> void:
	if not blue_lake_active:
		_show_dialogue("一幅画。画中的东西像是在等待另一种看法。")
	else:
		_show_dialogue("蓝湖在画面上留下了粉笔痕迹。附近的《窗》似乎不再只是画。")

func _interact_window() -> void:
	if not blue_lake_active:
		_show_dialogue("《窗》：关闭的窗户。画框很重，无法打开。")
		return
	if not handle_found:
		visual_mode = "Wide View"
		handle_found = true
		_show_dialogue("蓝湖显现出窗框边缘的把手。原来它一直在那里。")
		_update_ui()
		return
	if handle_found and not window_open:
		visual_mode = "High Contrast"
		window_open = true
		_show_dialogue("蓝湖让窗户的开合状态变得明确。它可以被打开。")
		queue_redraw()
		_update_ui()
		await get_tree().create_timer(1.0).timeout
		_start_transition()
		return
	_show_dialogue("进入 Blue Lake 后，再次调查《窗》，继续发现它的另一种可能。")

func _start_transition() -> void:
	if transition_started:
		return
	transition_started = true
	player.input_locked = true
	_show_dialogue("窗后的空间正在改变……")
	transition.begin()

func _finish_transition() -> void:
	# Both ways out of the gallery (S08's reopened Window, S06's escape through the window)
	# end the same way: the curtain opens on the Truth Theater stage.
	scene_state = "theater"
	var gallery := get_node_or_null("TruthGallery")
	if gallery:
		gallery.hide()
	for body in gallery_bodies:
		if is_instance_valid(body):
			body.hide()
			body.collision_layer = 0
			body.collision_mask = 0
	blue_lake_active = false
	visual_mode = "Standard"
	chalk_cursor.set_active(false)
	_build_theater()
	player.position = Vector2(576, 430)
	player.input_locked = false
	if s08_active:
		chapter_state.set_map_state(&"Theater_Stage_Entrance")
		chapter_state.mark_story_event(&"s08_true_exit_reached")
		chapter_state.mark_story_event(&"theater_entered")
		objective_label.text = "真理美术馆 · 完"
		_show_dialogue("窗帘被风吹动，拉了上来。不，不是窗帘——是幕布。\n灯光亮起。你站在舞台上。")
	elif s06_stolen:
		s06_chase_active = false
		chapter_state.set_map_state(&"Theater_Stage_Entrance")
		chapter_state.mark_story_event(&"s06_escaped_with_original")
		chapter_state.mark_story_event(&"theater_entered")
		objective_label.text = "真理美术馆 · 完"
		_show_dialogue("格雷汉带着原件翻出窗户。身后的窗帘落下——不，是幕布。\n灯光亮起。你站在舞台上。")
	else:
		_show_dialogue("真理剧院：幕布落下，又打开了。你已经进入另一种空间。\nPrototype 0.2 检查流程完成。")
	_update_ui()

func _build_theater() -> void:
	theater_nodes = Node2D.new()
	theater_nodes.name = "TruthTheater"
	add_child(theater_nodes)
	theater_nodes.queue_redraw()

func _draw_theater(node: Node2D) -> void:
	draw_rect(Rect2(0, 58, 1152, 590), Color("#17131d"))
	draw_rect(Rect2(80, 120, 992, 400), Color("#281a2b"))
	draw_rect(Rect2(145, 180, 862, 280), Color("#3d2539"))
	draw_rect(Rect2(205, 235, 742, 225), Color("#172235"))
	draw_circle(Vector2(576, 280), 75, Color(0.3, 0.65, 0.9, 0.16))
	draw_string(ThemeDB.fallback_font, Vector2(435, 405), "真理剧院", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("#f0d6a1"))
	# Stage floor and the spotlight that follows Graham: she arrives being watched.
	draw_rect(Rect2(80, 460, 992, 60), Color("#4a3426"))
	if player:
		var spot_x := player.position.x
		draw_colored_polygon(PackedVector2Array([Vector2(spot_x - 18.0, 120), Vector2(spot_x + 18.0, 120), Vector2(spot_x + 70.0, 515), Vector2(spot_x - 70.0, 515)]), Color(1.0, 0.94, 0.75, 0.16))
		draw_circle(Vector2(spot_x, 505), 62.0, Color(1.0, 0.94, 0.75, 0.14))

func _show_dialogue(text: String) -> void:
	if dialogue_label:
		dialogue_label.text = text

func _update_ui() -> void:
	if not status_label:
		return
	if not LEGACY_PROTOTYPE_FLOW_ENABLED:
		var slice_id := "S08" if s08_active else ("S07" if s07_active else ("S06" if s06_active else ("S05" if s05_active else ("S04" if s04_active else ("S03" if s03_active else ("S02" if s02_active else "S01"))))))
		mode_label.text = "CHAPTER 1 / " + slice_id
		if scene_state == "theater":
			status_label.text = "真理剧院 / 舞台"
		elif s08_active:
			status_label.text = "真理美术馆 / 真正出口"
		elif s07_active:
			status_label.text = "真理美术馆 / 重新观看"
		elif s06_active:
			status_label.text = "真理美术馆 / 看见与存在"
		elif s05_active:
			status_label.text = "真理美术馆 / 观看 → 改变"
		elif s04_active:
			status_label.text = "真理美术馆 / 不同的视觉经验"
		elif s03_active:
			status_label.text = "真理美术馆 / 视觉 ≠ 现实"
		elif s02_active:
			status_label.text = "真理美术馆 / 空间与方向"
		else:
			status_label.text = "真理美术馆 / 进入与观看"
		return
	var blue_text := "ON" if blue_lake_active else "OFF"
	mode_label.text = "BLUE LAKE: " + blue_text
	if scene_state == "theater":
		status_label.text = "真理剧院 / 到达"
	elif not mirror_solved:
		status_label.text = "真理美术馆 / 用 Chalk Cursor 调查镜子"
	elif not handle_found:
		status_label.text = "真理美术馆 / 用 Chalk Cursor 调查《窗》"
	elif not window_open:
		status_label.text = "真理美术馆 / 再次点击《窗》的特殊区域"
	else:
		status_label.text = "真理美术馆 / 窗已打开，幕布正在到来"

func _update_interaction_hint() -> void:
	if not interaction_hint_label or not player or scene_state != "gallery" or transition_started or (not LEGACY_PROTOTYPE_FLOW_ENABLED and not S01_ENABLED):
		if interaction_hint_label:
			interaction_hint_label.hide()
		return
	if blue_lake_active:
		if chalk_hover_target == "":
			interaction_hint_label.hide()
			return
		interaction_hint_label.text = "左键 使用蓝湖"
		interaction_hint_label.position = get_viewport().get_mouse_position() + Vector2(14, -22)
		interaction_hint_label.show()
		return
	if space_prompt_visible:
		interaction_hint_label.text = "SPACE  使用蓝湖"
		interaction_hint_label.position = Vector2(500, 455)
		interaction_hint_label.show()
		return
	var nearest := _get_nearest_interactable()
	if nearest.is_empty():
		interaction_hint_label.hide()
		return
	interaction_hint_label.text = "E 观察"
	if s01_active:
		var n: String = nearest.get("name", "")
		if s01_clocks_seen and n == "ClockBack":
			interaction_hint_label.text = "E 往回拨"
		elif s01_clocks_seen and n == "ClockForward":
			interaction_hint_label.text = "E 往前拨"
		elif n == "ExitDoor" and s01_gate_open:
			interaction_hint_label.text = "E 进门"
		elif n == "ExitDoor" and s01_key_on_hook:
			interaction_hint_label.text = "E 取钥匙开门"
	if s04_active and nearest.get("name", "") == "Restorer" and s04_restorer_observed and not s04_pigment_borrowed:
		interaction_hint_label.text = "E 借荧光剂"
	elif s04_active and nearest.get("name", "") == "PigmentStation":
		interaction_hint_label.text = "E 涂抹荧光剂" if s04_pigment_borrowed else "先向修复师借荧光剂"
	var hint_y: float = nearest.get("hint_y", nearest.position.y - nearest.radius * 0.55)
	interaction_hint_label.position = Vector2(nearest.position.x - 28.0, hint_y)
	interaction_hint_label.show()

func _update_chalk_hover() -> void:
	var previous := chalk_hover_target
	chalk_hover_target = ""
	if not blue_lake_active or scene_state != "gallery" or transition_started:
		if previous != "":
			queue_redraw()
		return
	var mouse_position := get_viewport().get_mouse_position()
	if S03_ENABLED and s03_active:
		if not s03_mirror_intervened and mouse_position.distance_to(S03_MIRROR_CENTER) <= 55.0:
			chalk_hover_target = "Mirror"
	elif S04_ENABLED and s04_active:
		if s04_pigment_applied and not s04_lamp_observed and mouse_position.distance_to(S04_LAMP_CENTER) <= 40.0:
			chalk_hover_target = "Lamp"
	elif S05_ENABLED and s05_active:
		if not s05_window_open and mouse_position.distance_to(S05_WINDOW_CENTER) <= 62.0:
			chalk_hover_target = "Window"
	elif S06_ENABLED and s06_active:
		if not s06_sensor_revealed:
			if mouse_position.distance_to(S06_PLATFORM_CENTER) <= 50.0:
				chalk_hover_target = "Sensor"
			elif mouse_position.distance_to(S06_GAZE_EYE) <= 36.0:
				chalk_hover_target = "Gaze"
	elif S07_ENABLED and s07_active:
		if s07_room == "hall" and not s07_mirror_trace_found and mouse_position.distance_to(S03_MIRROR_CENTER) <= 55.0:
			chalk_hover_target = "ReturnMirror"
		elif s07_room == "gallery" and s07_mirror_trace_found and not s07_window_trace_found and mouse_position.distance_to(S05_WINDOW_CENTER) <= 62.0:
			chalk_hover_target = "ReturnWindow"
	elif S08_ENABLED and s08_active:
		if not s08_window_open and mouse_position.distance_to(S05_WINDOW_CENTER) <= 62.0:
			chalk_hover_target = "FinalWindow"
	elif LEGACY_PROTOTYPE_FLOW_ENABLED:
		if not mirror_solved and mouse_position.distance_to(Vector2(205, 230)) <= 62.0:
			chalk_hover_target = "Mirror"
		elif mirror_solved and mouse_position.distance_to(Vector2(840, 205)) <= 68.0:
			chalk_hover_target = "Window"
	if previous != chalk_hover_target:
		queue_redraw()

func _get_nearest_interactable() -> Dictionary:
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S01_ENABLED:
		if s08_active:
			return _get_nearest_s08_interactable()
		if s07_active:
			return _get_nearest_s07_interactable()
		if s06_active:
			return _get_nearest_s06_interactable()
		if s05_active:
			return _get_nearest_s05_interactable()
		if s04_active:
			return _get_nearest_s04_interactable()
		if s03_active:
			return _get_nearest_s03_interactable()
		if s02_active:
			return _get_nearest_s02_interactable()
		return _get_nearest_s01_interactable()
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in interactables:
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest

func _get_nearest_s01_interactable() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s01_interactables:
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest
