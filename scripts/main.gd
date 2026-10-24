extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const CursorScript := preload("res://scripts/chalk_cursor.gd")
const TransitionScript := preload("res://scripts/transition_overlay.gd")
const BlueLakeTransformScript := preload("res://scripts/blue_lake_transform.gd")
const ChapterStateScript := preload("res://scripts/chapter_state.gd")

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
var s02_active := false
var s02_completion_started := false
var s02_loop_count := 0
var s02_loop_triggered := false
var s02_interactables: Array[Dictionary] = []
var s03_active := false
var s03_mirror_observed := false
var s03_mirror_intervened := false
var s03_mirror_crossed := false
var s03_return_guard_spoken := false
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
		# Each sits under its wall exhibit; hint_y puts "E 观察" just below the title card.
		{"name":"EntrancePhoto", "position":Vector2(170,440), "radius":70.0, "hint_y":376.0},
		{"name":"FirstExhibit", "position":Vector2(390,440), "radius":70.0, "hint_y":376.0},
		{"name":"SecondExhibit", "position":Vector2(608,440), "radius":70.0, "hint_y":376.0},
		{"name":"ExitSign", "position":Vector2(955,440), "radius":50.0, "hint_y":376.0}
	]
	s02_interactables = [
		{"name":"SecurityGuard", "position":Vector2(700,520), "radius":72.0},
		{"name":"DeadEnd", "position":Vector2(1010,520), "radius":96.0},
		{"name":"EternalGaze", "position":Vector2(590,520), "radius":62.0},
		{"name":"NotAnEye", "position":Vector2(640,520), "radius":62.0},
		{"name":"PearlHeadphones", "position":Vector2(760,520), "radius":62.0},
		{"name":"StarryNerves", "position":Vector2(820,520), "radius":62.0},
		{"name":"SculptureGaze", "position":Vector2(880,520), "radius":62.0},
		{"name":"SculptureVenus", "position":Vector2(920,520), "radius":62.0},
		{"name":"SculptureTwins", "position":Vector2(960,520), "radius":62.0},
		{"name":"SculptureLight", "position":Vector2(990,520), "radius":62.0},
		{"name":"SculptureBlind", "position":Vector2(1040,520), "radius":62.0}
	]
	s03_interactables = [
		{"name":"Mirror", "position":Vector2(1010,520), "radius":96.0},
		{"name":"SecurityGuard", "position":Vector2(700,520), "radius":72.0}
	]
	s04_interactables = [
		{"name":"Visitor", "position":Vector2(850,520), "radius":72.0},
		{"name":"Restorer", "position":Vector2(620,520), "radius":120.0},
		{"name":"PigmentStation", "position":Vector2(330,520), "radius":68.0},
		{"name":"Lamp", "position":Vector2(500,520), "radius":68.0},
		{"name":"LightSwitch", "position":Vector2(430,520), "radius":68.0},
		{"name":"BlockedWindow", "position":Vector2(980,520), "radius":76.0}
	]
	s05_interactables = [
		{"name":"Window", "position":Vector2(840,520), "radius":82.0}
	]
	s06_interactables = [
		{"name":"CentralPlatform", "position":Vector2(576,520), "radius":100.0},
		{"name":"EscapeWindow", "position":Vector2(980,520), "radius":82.0}
	]
	s07_interactables = [
		{"name":"ReturnMirror", "position":Vector2(205,520), "radius":82.0},
		{"name":"ReturnWindow", "position":Vector2(840,520), "radius":82.0}
	]
	s08_interactables = [
		{"name":"FinalWindow", "position":Vector2(840,520), "radius":82.0}
	]
	queue_redraw()

func _draw() -> void:
	if scene_state == "gallery":
		_draw_gallery(self)
	elif scene_state == "theater":
		_draw_theater(self)
	elif scene_state == "outside":
		_draw_outside(self)

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
	if blue_lake_active:
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
	# The old left exit is a second real gate, opened after the guard is revisited.
	if is_instance_valid(west_exit_body) and west_exit_body.collision_layer > 0:
		draw_rect(Rect2(20, 112, 24, 408), Color("#202c3a"), true)
		draw_rect(Rect2(8, 356, 48, 164), Color("#445866"), true)
		draw_rect(Rect2(14, 366, 36, 154), Color("#1c2934"), true)
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
	# S01 only exposes the entrance and first viewing area. Later Slice objects stay hidden.
	# Exhibits hang on the wall at eye level; each one's E spot is the floor right below it.
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "入口大厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	draw_string(ThemeDB.fallback_font, Vector2(340, 175), "第一展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	# The old bar photograph is the visual anchor for how the player arrived.
	draw_rect(Rect2(114, 240, 112, 84), Color("#c9ae78"), true)
	draw_rect(Rect2(123, 249, 94, 66), Color("#667989"), true)
	draw_rect(Rect2(131, 258, 78, 48), Color("#8ca0a8"), true)
	draw_line(Vector2(138, 295), Vector2(201, 267), Color("#d5c38e"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(146, 352), "旧照片", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#e8dfc8"))
	# A quiet placeholder exhibit establishes that this is a gallery, not a menu room.
	draw_rect(Rect2(332, 214, 116, 116), Color("#c7a56f"), true)
	draw_rect(Rect2(342, 224, 96, 96), Color("#777f78"), true)
	draw_circle(Vector2(390, 264), 18.0, Color("#c9bda1"))
	draw_line(Vector2(363, 296), Vector2(433, 245), Color("#4f5d60"), 8.0)
	draw_string(ThemeDB.fallback_font, Vector2(337, 352), "《观看的永恒》", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))
	draw_rect(Rect2(552, 214, 112, 116), Color("#c7a56f"), true)
	draw_rect(Rect2(562, 224, 92, 96), Color("#777f78"), true)
	draw_circle(Vector2(608, 262), 19.0, Color("#c9bda1"))
	draw_string(ThemeDB.fallback_font, Vector2(546, 352), "《这不是一只眼睛》", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))
	# The exit door stands at the far end of the hall; it opens once the entrance has been read.
	draw_string(ThemeDB.fallback_font, Vector2(944, 212), "出口 →", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d9d4b6"))
	draw_rect(Rect2(938, 222, 84, 150), Color("#445866"), true)
	if not s01_gate_open:
		draw_rect(Rect2(947, 231, 66, 141), Color("#1c2934"), true)
		draw_circle(Vector2(1003, 305), 4.0, Color("#d9c997"))
	else:
		draw_rect(Rect2(947, 231, 66, 141), Color("#0e1620"), true)
		draw_colored_polygon(PackedVector2Array([Vector2(947, 372), Vector2(1013, 372), Vector2(1030, 420), Vector2(930, 420)]), Color(0.75, 0.85, 0.95, 0.10))
	draw_string(ThemeDB.fallback_font, Vector2(112, 480), "入口", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#8fa1af"))

func _draw_s02_gallery() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "画作与雕塑展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	draw_string(ThemeDB.fallback_font, Vector2(670, 175), "保安指向右侧通道", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	draw_circle(Vector2(700, 410), 20.0, Color("#bba88c"))
	draw_rect(Rect2(680, 432, 40, 68), Color("#566b7a"), true)
	draw_line(Vector2(720, 450), Vector2(760, 430), Color("#bba88c"), 5.0)
	draw_string(ThemeDB.fallback_font, Vector2(674, 505), "保安 →", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))
	var title_x := [180.0, 330.0, 480.0, 630.0]
	var artwork_titles := ["《戴珍珠耳机的少女》", "《星空下的神经》", "《镜中镜》", "《凝视》"]
	for index in range(title_x.size()):
		var x: float = title_x[index]
		draw_rect(Rect2(x, 205, 108, 104), Color("#b49464"), true)
		draw_rect(Rect2(x + 9.0, 214, 90, 86), Color("#66747a"), true)
		draw_circle(Vector2(x + 54.0, 247), 17.0, Color("#c9bda1"))
		draw_line(Vector2(x + 22.0, 282), Vector2(x + 86.0, 230), Color("#c8c1a8"), 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(x - 5.0, 333), artwork_titles[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	# Sculptures sit along the same public gallery floor; concise labels make the intended clues discoverable.
	draw_circle(Vector2(790, 260), 35.0, Color("#64747b"))
	draw_circle(Vector2(790, 260), 18.0, Color("#172431"))
	draw_string(ThemeDB.fallback_font, Vector2(750, 333), "《機械維納斯》", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	draw_circle(Vector2(900, 255), 24.0, Color("#b9aa8d"))
	draw_circle(Vector2(946, 255), 24.0, Color("#b9aa8d"))
	draw_string(ThemeDB.fallback_font, Vector2(870, 333), "《雙生》", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	draw_colored_polygon(PackedVector2Array([Vector2(1005, 222), Vector2(1030, 265), Vector2(980, 265)]), Color("#c9dff0"))
	draw_string(ThemeDB.fallback_font, Vector2(980, 333), "《光》", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	draw_circle(Vector2(1080, 260), 27.0, Color("#79868b"))
	draw_string(ThemeDB.fallback_font, Vector2(1050, 333), "《盲》", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	# The repeated lower-right route is a visible corridor, distinct from the guard's rightward direction.
	draw_rect(Rect2(750, 438, 310, 62), Color("#263542"), true)
	draw_line(Vector2(760, 438), Vector2(1060, 438), Color("#8196a0"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(810, 475), "右下展厅通道", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9eafb7"))
	# The end wall is physically backed and shown as a wall with a mirror, not an invisible barrier.
	draw_rect(Rect2(1010, 312, 78, 208), Color("#c2a875"), true)
	draw_rect(Rect2(1019, 321, 60, 190), Color("#426b82"), true)
	draw_line(Vector2(1024, 350), Vector2(1073, 478), Color(0.8, 0.95, 1.0, 0.5), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(1004, 540), "死路镜子", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))

func _draw_s03_gallery() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "镜子展厅尽头", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	draw_circle(Vector2(700, 410), 20.0, Color("#bba88c"))
	draw_rect(Rect2(680, 432, 40, 68), Color("#566b7a"), true)
	draw_line(Vector2(720, 450), Vector2(760, 430), Color("#bba88c"), 5.0)
	draw_string(ThemeDB.fallback_font, Vector2(674, 505), "保安 →", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))
	draw_rect(Rect2(964, 312, 92, 208), Color("#c2a875"), true)
	draw_rect(Rect2(974, 322, 72, 188), Color("#426b82"), true)
	draw_rect(Rect2(987, 376, 44, 35), Color("#c9ae78"), true)
	draw_rect(Rect2(992, 381, 34, 25), Color("#667989"), true)
	draw_line(Vector2(990, 402), Vector2(1027, 382), Color("#d5c38e"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(962, 540), "镜中倒映着入口", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))
	if s03_mirror_observed and blue_lake_active:
		draw_circle(Vector2(1010, 410), 65.0, Color(0.55, 0.88, 1.0, 0.11))
		draw_arc(Vector2(1010, 410), 65.0, 0.0, TAU, 32, Color("#bfe8ff"), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(865, 230), "镜中有门，现实中没有。", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#bfe8ff"))
	if s03_mirror_intervened:
		draw_rect(Rect2(968, 270, 84, 198), Color(0.45, 0.86, 1.0, 0.26), false, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(850, 260), "镜中的门已经显现", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#bfe8ff"))
	if s03_mirror_crossed:
		draw_string(ThemeDB.fallback_font, Vector2(116, 370), "你从镜子里回到了入口一侧。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d6e8f0"))

func _draw_s04_gallery() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "画作展厅与修复区", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	# Visitor and restorer are separated by the work area and remain busy with their own activities.
	var visitor_x := 760.0 if s04_visitor_moved else 875.0
	draw_circle(Vector2(visitor_x, 410), 22.0, Color("#d3b28e"))
	draw_rect(Rect2(visitor_x - 24.0, 434, 48, 66), Color("#6c8290"), true)
	draw_circle(Vector2(visitor_x - 8.0, 405), 3.0, Color("#5a6670"))
	draw_circle(Vector2(visitor_x + 8.0, 405), 3.0, Color("#5a6670"))
	draw_string(ThemeDB.fallback_font, Vector2(visitor_x - 34.0, 505), "參觀者", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))
	draw_circle(Vector2(620, 410), 22.0, Color("#cba98a"))
	draw_rect(Rect2(595, 434, 50, 66), Color("#b26b5e"), true)
	draw_rect(Rect2(603, 450, 30, 12), Color("#e3c77d"), true)
	draw_line(Vector2(651, 454), Vector2(684, 426), Color("#bfe8ff"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(592, 505), "修復師", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))
	# The lamp and switch belong to the physical room; the window painting starts in its normal colors.
	draw_rect(Rect2(292, 430, 76, 46), Color("#665d50"), true)
	draw_rect(Rect2(300, 422, 60, 12), Color("#c8b98d"), true)
	draw_circle(Vector2(330, 414), 8.0, Color("#bfe8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(292, 505), "荧光剂台", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))
	draw_rect(Rect2(465, 265, 72, 10), Color("#d9d1b5"), true)
	draw_line(Vector2(501, 275), Vector2(501, 315), Color("#b8c7d4"), 3.0)
	draw_circle(Vector2(501, 322), 12.0, Color("#e5d9ae"))
	draw_string(ThemeDB.fallback_font, Vector2(458, 350), "感應燈", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))
	draw_rect(Rect2(408, 410, 28, 40), Color("#5e6b73"), true)
	draw_circle(Vector2(422, 430), 5.0, Color("#d1c49d"))
	draw_string(ThemeDB.fallback_font, Vector2(390, 475), "燈控", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#b8c7d4"))
	draw_rect(Rect2(947, 356, 122, 164), Color("#c7a56f"), true)
	draw_rect(Rect2(958, 367, 100, 142), Color("#725e50"), true)
	if s04_lights_off:
		draw_rect(Rect2(966, 375, 84, 126), Color("#182633"), true)
		draw_circle(Vector2(1008, 438), 30.0, Color(0.52, 0.9, 0.98, 0.72))
		draw_arc(Vector2(1008, 438), 43.0, 0.0, TAU, 32, Color("#bfe8ff"), 3.0)
	else:
		draw_circle(Vector2(1008, 438), 24.0, Color("#d9b575"))
		draw_line(Vector2(975, 472), Vector2(1040, 403), Color("#b6a280"), 6.0)
	if blue_lake_active and chalk_hover_target == "Lamp":
		draw_circle(Vector2(501, 322), 26.0, Color(0.45, 0.85, 1.0, 0.16))
		draw_arc(Vector2(501, 322), 26.0, 0.0, TAU, 24, Color("#bfe8ff"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(970, 540), "《窗》", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))
	if s04_pigment_applied:
		draw_arc(Vector2(player.position.x, player.position.y - 28.0), 23.0, 0.0, TAU, 24, Color("#bfe8ff"), 2.0)
	if s04_visitor_observed and not s04_visitor_recognized:
		draw_string(ThemeDB.fallback_font, Vector2(532, 545), "她仍在尋找你。", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d6e8f0"))
	if s04_visitor_moved:
		draw_string(ThemeDB.fallback_font, Vector2(926, 545), "這幅畫裡有光。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))

func _draw_s05_gallery() -> void:
	# S05 is the first authored intervention: a painting becomes operable as a window.
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "中央展厅前室", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	draw_string(ThemeDB.fallback_font, Vector2(760, 175), "《窗》", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	_draw_object(window_node, "Window", Color("#5ca8c7"), "《窗》")
	if s05_window_observed and not s05_window_open:
		draw_string(ThemeDB.fallback_font, Vector2(690, 365), "它看起来像一幅画。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#aab8c2"))
	if blue_lake_active and chalk_hover_target == "Window" and not s05_window_open:
		draw_circle(Vector2(840, 462), 66.0, Color(0.4, 0.85, 1.0, 0.11))
		draw_arc(Vector2(840, 462), 66.0, 0.0, TAU, 32, Color("#bfe8ff"), 2.0)
	if s05_window_handle_found and not s05_window_open:
		draw_circle(Vector2(874, 462), 8.0, Color("#f6e5a7"))
		draw_arc(Vector2(874, 462), 18.0, 0.0, TAU, 24, Color("#bfe8ff"), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(690, 400), "把手显现了。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d6e8f0"))
	if s05_window_open:
		draw_rect(Rect2(782, 404, 116, 116), Color("#8cdcff"), true)
		draw_rect(Rect2(792, 414, 96, 96), Color("#172c3c"), true)
		draw_circle(Vector2(840, 462), 42.0, Color(0.25, 0.72, 0.95, 0.24))
		draw_string(ThemeDB.fallback_font, Vector2(660, 365), "窗后的空间通向中央展台。", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#bfe8ff"))
		draw_string(ThemeDB.fallback_font, Vector2(660, 400), "这不是出口。", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f6e5a7"))

func _draw_s06_gallery() -> void:
	# S06 starts with an empty platform. Blue Lake reveals what ordinary sight omits.
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "中央展台", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	draw_rect(Rect2(922, 404, 116, 116), Color("#c7a56f"), true)
	draw_rect(Rect2(932, 414, 96, 96), Color("#5ca8c7"), true)
	draw_line(Vector2(980, 414), Vector2(980, 510), Color("#d7f3ff"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(949, 540), "窗", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))
	draw_rect(Rect2(380, 235, 392, 128), Color("#252f3c"), true)
	draw_rect(Rect2(395, 250, 362, 98), Color("#566674"), false, 3.0)
	draw_line(Vector2(410, 330), Vector2(742, 330), Color("#9eafb7"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(478, 305), "看见即存在", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#d6c79f"))
	draw_string(ThemeDB.fallback_font, Vector2(462, 410), "普通视角：展台是空的。", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#aab8c2"))
	if s06_active and blue_lake_active and not s06_sensor_revealed:
		draw_circle(Vector2(576, 292), 54.0, Color(0.35, 0.82, 0.96, 0.10))
		draw_arc(Vector2(576, 292), 54.0, 0.0, TAU, 32, Color(0.55, 0.88, 1.0, 0.42), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(458, 450), "蓝湖视角：空白处有轮廓。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))
	if s06_sensor_revealed:
		draw_circle(Vector2(576, 292), 26.0, Color("#6ec9e8"))
		draw_circle(Vector2(576, 292), 12.0, Color("#dff8ff"))
		draw_arc(Vector2(576, 292), 42.0, -0.7, 2.9, 24, Color("#bfe8ff"), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(458, 450), "隐藏的 Kent 视觉传感器已显现。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))
	if s06_chase_active:
		draw_circle(Vector2(s06_guard_chase_x, 410), 20.0, Color("#bba88c"))
		draw_rect(Rect2(s06_guard_chase_x - 20.0, 432, 40, 68), Color("#566b7a"), true)
		draw_string(ThemeDB.fallback_font, Vector2(s06_guard_chase_x - 42.0, 505), "保安追来", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f0c6a5"))

func _draw_s07_gallery() -> void:
	# S07 reuses the old spaces and adds only a second layer of reading.
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "回访：镜子展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	draw_string(ThemeDB.fallback_font, Vector2(760, 175), "回访：《窗》", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	var original_mirror_position := mirror_node.position
	mirror_node.position = Vector2(205, 410)
	_draw_object(mirror_node, "Mirror", Color("#426b82"), "镜子")
	mirror_node.position = original_mirror_position
	_draw_object(window_node, "Window", Color("#5ca8c7"), "《窗》")
	draw_string(ThemeDB.fallback_font, Vector2(120, 390), "同一个地方，仍然有没读完的内容。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#aab8c2"))
	if s07_mirror_trace_found:
		draw_arc(Vector2(205, 410), 72.0, -2.6, 0.4, 24, Color("#bfe8ff"), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(120, 425), "镜后留下了回访的痕迹。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))
	if s07_window_trace_found:
		draw_line(Vector2(795, 410), Vector2(885, 410), Color("#bfe8ff"), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(720, 390), "《窗》回应了第二次观看。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))

func _draw_s08_gallery() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "真正出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	_draw_object(window_node, "Window", Color("#5ca8c7"), "《窗》")
	if not s08_window_open:
		draw_string(ThemeDB.fallback_font, Vector2(690, 365), "再次来到这里，窗的边界已经不一样。", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d6e8f0"))
	else:
		draw_rect(Rect2(782, 404, 116, 116), Color("#cdefff"), true)
		draw_rect(Rect2(792, 414, 96, 96), Color("#8bcfe9"), true)
		draw_circle(Vector2(840, 462), 46.0, Color(0.96, 0.99, 1.0, 0.46))
		draw_string(ThemeDB.fallback_font, Vector2(675, 365), "外部的光从窗后进来。", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f6e5a7"))

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
		_show_dialogue("Blue Lake：现在，用我去看镜子。")
	elif s04_active:
		_show_dialogue("Blue Lake：用荧光照一下那盏灯。")
	elif s05_active:
		_show_dialogue("Blue Lake：现在，用我去看《窗》。")
	elif s06_active:
		_show_dialogue("Blue Lake：现在，看中央展台的空白处。")
	elif s07_active:
		_show_dialogue("Blue Lake：同一个地方，在第二次观看时会留下不同的痕迹。")
	elif s08_active:
		_show_dialogue("Blue Lake：这次不一样。")
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
	_show_dialogue("Blue Lake：" + ("用粉笔描出镜中的门。" if blue_lake_active else "……先收起来。"))
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
	if not s01_active or scene_state != "gallery" or transition_started:
		return
	var nearest := _get_nearest_s01_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	if object_name == "EntrancePhoto":
		chapter_state.mark_event(&"s01_photo_observed")
		_show_dialogue("《美术馆开幕日》。\n这张照片里的大厅，和这里一模一样。我们就是从照片里进来的。")
	elif object_name == "FirstExhibit":
		chapter_state.mark_event(&"s01_first_exhibit_observed")
		_show_dialogue("《观看的永恒》：融化的不是时钟，而是眼球。\n说明牌写着：时间在此失去意义。")
	elif object_name == "SecondExhibit":
		_show_dialogue("《这不是一只眼睛》：画面是一只眼睛，说明牌却说“这不是一只眼睛”。")
	elif object_name == "ExitSign":
		chapter_state.mark_event(&"s01_exit_area_observed")
		_show_dialogue("出口指向展厅深处。\n格雷汉：这扇门现在打不开。")
	_try_complete_s01()

func _try_complete_s01() -> void:
	if s01_completion_started:
		return
	if not chapter_state.has_event(&"s01_photo_observed"):
		return
	if not chapter_state.has_event(&"s01_first_exhibit_observed"):
		return
	if not chapter_state.has_event(&"s01_exit_area_observed"):
		return
	s01_completion_started = true
	chapter_state.mark_event(&"s01_no_obvious_exit_recognized")
	chapter_state.learn(&"s01_need_to_leave")
	chapter_state.set_player_goal(&"find_a_way_out")
	chapter_state.complete_slice(ChapterState.Slice.S01_ENTER)
	s01_gate_open = true
	if is_instance_valid(gate_body):
		gate_body.collision_layer = 0
		gate_body.collision_mask = 0
	_show_dialogue("这里没有一个正常的出口。\n我要继续往里面走。")
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
	player.position.x = 560.0
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
		if s03_mirror_crossed and not s03_return_guard_spoken:
			s03_return_guard_spoken = true
			_show_dialogue("保安又指向最右侧。\n格雷汉：你刚才也是这么说的。我们明明从右下绕回来了。")
			if is_instance_valid(west_exit_body):
				west_exit_body.collision_layer = 0
				west_exit_body.collision_mask = 0
		else:
			chapter_state.mark_event(&"s02_guard_directed_right")
			if s02_loop_count > 0:
				_show_dialogue("保安再次指向最右侧。\n格雷汉：你刚才也是这么说的。我们已经回来过一次了。")
			else:
				_show_dialogue("保安指向最右侧。\n保安：一直往最右边走，就能找到出口。")
	elif object_name == "DeadEnd":
		chapter_state.mark_event(&"s02_dead_end_observed")
		_show_dialogue("右边的通路明明能走到尽头。\n尽头的墙上挂着一面镜子。")
	elif object_name == "EternalGaze":
		_show_dialogue("《观看的永恒》：融化的眼球浮在空荡的画面里。\n轮廓里藏着一句话：时间在此失去意义。")
	elif object_name == "NotAnEye":
		_show_dialogue("《这不是一只眼睛》：画着眼睛，下面却写着“这不是一只眼睛”。")
	elif object_name == "PearlHeadphones":
		_show_dialogue("《戴珍珠耳机的少女》：机器人少女戴着耳机。\n换一个角度，她的脸就变了。")
	elif object_name == "StarryNerves":
		_show_dialogue("《星空下的神经》：漩涡不是星云，而是传导中的神经纤维。")
	elif object_name == "SculptureGaze":
		_show_dialogue("《凝视》：巨大的机械眼球追随着展厅里的动静。")
	elif object_name == "SculptureVenus":
		_show_dialogue("《机械维纳斯》：她缺少一只手臂和一只眼睛。")
	elif object_name == "SculptureTwins":
		_show_dialogue("《双生》：两个头颅背对着彼此。说明牌写着共同创作者。")
	elif object_name == "SculptureLight":
		_show_dialogue("《光》：棱镜把一道白光拆成不同颜色。")
	elif object_name == "SculptureBlind":
		_show_dialogue("《盲》：没有眼睛的人像，安静地面对展厅。")
	_try_complete_s02()

func _try_s03_interact() -> void:
	if not s03_active or scene_state != "gallery" or transition_started:
		return
	var nearest := _get_nearest_s03_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	if object_name == "SecurityGuard":
		if s03_mirror_crossed and not s03_return_guard_spoken:
			s03_return_guard_spoken = true
			_show_dialogue("保安仍指向最右边。\n格雷汉：你刚才也是这么说的。我们从镜子回来了。")
			if is_instance_valid(west_exit_body):
				west_exit_body.collision_layer = 0
				west_exit_body.collision_mask = 0
		else:
			_show_dialogue("保安指向最右边：一直往右走，就能找到出口。")
	elif not s03_mirror_observed:
		s03_mirror_observed = true
		chapter_state.mark_event(&"s03_mirror_observed")
		_show_dialogue("镜子里倒映着入口。\nBlue Lake：镜子里有门，现实中没有……")
		_show_space_prompt()
	else:
		_show_dialogue("Blue Lake：反过来走，也许能找到它。")
	queue_redraw()

func _try_s03_chalk_interaction() -> void:
	if chalk_hover_target != "Mirror" or s03_mirror_intervened:
		return
	s03_mirror_intervened = true
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Mirror Layer"
	chapter_state.mark_event(&"s03_mirror_structure_revealed")
	_show_dialogue("Blue Lake：你刚才相信了一个眼睛看不到的东西。\n格雷汉：也许要相信镜子里的，而不是眼睛看到的。")
	objective_label.text = "走进死路尽头的镜子"
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
		if not s04_restorer_observed:
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
			_show_dialogue("灯光重新亮起，画作恢復了普通颜色。")
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
		_show_dialogue("这是一幅画。\n……可它看起来太像一扇真正的窗。")
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
	_show_dialogue("Blue Lake：" + ("用粉笔碰一碰窗框。" if blue_lake_active else "……先收起来。"))
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
		_show_dialogue("Blue Lake：把手一直在那里。只是你以前看不见。")
		_update_ui()
		queue_redraw()
		return
	s05_window_open = true
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
	if object_name == "EscapeWindow" and s06_chase_active:
		s06_stolen = true
		chapter_state.mark_event(&"s06_sensor_taken")
		_show_dialogue("格雷汉：从窗户出去！\nBlue Lake：快，幕布要落下了。")
		_start_transition()
		return
	if not s06_platform_observed:
		s06_platform_observed = true
		chapter_state.mark_event(&"s06_platform_observed")
		_show_dialogue("《看见》：空展台下写着“看见即存在”。")
		_show_space_prompt()
	elif s06_sensor_revealed:
		_show_dialogue("展台上的物件很像肯特阿姨缺失的光学零件。\n她们正缺少它……要拿走原件吗？")
		s06_choice_visible = true
		s06_take_button.show()
		s06_leave_button.show()
	else:
		_show_dialogue("展台仍然是空的。先用蓝湖观察它。")
	queue_redraw()

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
	_show_dialogue("Blue Lake：" + ("空白处有东西。用粉笔碰它。" if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _try_s06_chalk_interaction() -> void:
	if chalk_hover_target != "Sensor" or s06_sensor_revealed:
		return
	s06_sensor_revealed = true
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Sensor Layer"
	chapter_state.mark_event(&"s06_visual_sensor_revealed")
	chapter_state.mark_event(&"s06_kent_optical_part_revealed")
	_show_dialogue("Blue Lake：这里刚才明明什么都没有。\n格雷汉：这很像肯特阿姨的光学零件。她们正缺少它。")
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
	_show_dialogue("格雷汉：先让它留在这里。\nBlue Lake：同一个地方，可以再看一次。")
	await get_tree().create_timer(0.8).timeout
	_enter_s07_after_s06()

func _enter_s06_after_s05() -> void:
	if s06_active:
		return
	s05_active = false
	s06_active = true
	s06_platform_observed = false
	s06_sensor_revealed = false
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	player.position = Vector2(576, 430)
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
			_show_dialogue("这里我们已经来过。\nBlue Lake：同一个地方，在不同观察方式下会留下不同的痕迹。")
			_show_space_prompt()
		else:
			_show_dialogue("镜子后的痕迹已经显现。")
	elif object_name == "ReturnWindow":
		if not s07_mirror_trace_found:
			_show_dialogue("Blue Lake：先别急着看《窗》。镜子留下的东西还没有读完。")
			return
		if not s07_window_observed:
			s07_window_observed = true
			chapter_state.mark_event(&"s07_window_area_revisited")
			_show_dialogue("《窗》还是原来的《窗》。\nBlue Lake：但它记得你已经看过一次。")
			_show_space_prompt()
		else:
			_show_dialogue("Blue Lake：这一次，你已经知道该看哪里了。")
	queue_redraw()

func _try_toggle_s07_blue_lake() -> void:
	if not s07_mirror_observed and not s07_window_observed:
		_show_dialogue("Blue Lake：先重新观察一个你已经走过的地方。")
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("Blue Lake：再看一次。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_show_dialogue("Blue Lake：" + ("痕迹就在这里。用粉笔碰它。" if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _try_s07_chalk_interaction() -> void:
	if chalk_hover_target == "ReturnMirror" and not s07_mirror_trace_found:
		s07_mirror_trace_found = true
		blue_lake_active = false
		chalk_cursor.set_active(false)
		visual_mode = "Return Mirror Layer"
		chapter_state.mark_event(&"s07_mirror_trace_found")
		_show_dialogue("Blue Lake：你漏掉的不是一个物件，是另一种看法。")
		objective_label.text = "回到《窗》附近"
		_update_ui()
		queue_redraw()
		return
	if chalk_hover_target == "ReturnWindow" and s07_window_observed and not s07_window_trace_found:
		s07_window_trace_found = true
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
		_show_dialogue("这次不一样。\n《窗》已经不像一幅画了。")
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
	_show_dialogue("Blue Lake：" + ("用粉笔打开它。" if blue_lake_active else "……先收起来。"))
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
	player.position = Vector2(840, 430)
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
	player.position = Vector2(190, 430)
	chapter_state.advance_to(ChapterState.Slice.S07_RETURN)
	chapter_state.set_map_state(&"Museum_S07_Return")
	chapter_state.set_player_goal(&"reobserve_old_areas")
	chapter_state.mark_story_event(&"s07_started")
	objective_label.text = "重新观看旧区域"
	_show_dialogue("蓝湖：我们是不是漏掉了什么？")
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
	player.position = Vector2(80, 520)
	chapter_state.advance_to(ChapterState.Slice.S04_VISITOR)
	chapter_state.set_map_state(&"Museum_S04_Visitor")
	chapter_state.set_player_goal(&"recognize_the_visitor")
	chapter_state.mark_story_event(&"s04_started")
	objective_label.text = "观察参观者"
	_show_dialogue("格雷汉：我们回到最左边了。前面那扇门现在通了。")
	_update_ui()
	queue_redraw()

func _update_s02_loop_trigger() -> void:
	if not s02_active or s02_loop_triggered or scene_state != "gallery" or transition_started:
		return
	if not chapter_state.has_event(&"s02_guard_observed"):
		return
	if absf(player.position.x - 930.0) > 72.0:
		return
	s02_loop_triggered = true
	s02_loop_count += 1
	player.position = Vector2(560, 520)
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
	if s01_active and s01_completion_started and player.position.x >= 1012.0:
		_enter_s02_after_s01()
		return
	if s03_active and s03_mirror_intervened and not s03_mirror_crossed and player.position.x >= 1000.0:
		s03_mirror_crossed = true
		chapter_state.mark_event(&"s03_mirror_crossed")
		chapter_state.learn(&"s03_visual_is_not_reality")
		chapter_state.set_player_goal(&"return_to_the_entrance")
		chapter_state.complete_slice(ChapterState.Slice.S03_MIRROR)
		player.position = Vector2(548, 520)
		_show_dialogue("Blue Lake：反过来走？\n你穿过镜面，回到了入口一侧。")
		_update_ui()
		queue_redraw()
		return
	if s03_active and s03_mirror_crossed and s03_return_guard_spoken and player.position.x <= 50.0:
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
	player.position = Vector2(190, 430)
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
	if s06_chase_active and s06_stolen:
		scene_state = "outside"
		var gallery_exit := get_node_or_null("TruthGallery")
		if gallery_exit:
			gallery_exit.hide()
		for body in gallery_bodies:
			if is_instance_valid(body):
				body.hide()
				body.collision_layer = 0
				body.collision_mask = 0
		blue_lake_active = false
		chalk_cursor.set_active(false)
		player.position = Vector2(576, 430)
		player.input_locked = false
		chapter_state.set_map_state(&"Museum_S06_Escape")
		_show_dialogue("幕布落下，又在窗外打开。格雷汉带着原件逃出了美术馆。")
		_update_ui()
		return
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

func _draw_outside(node: Node2D) -> void:
	draw_rect(Rect2(0, 58, 1152, 590), Color("#b9d4d2"))
	draw_rect(Rect2(0, 360, 1152, 288), Color("#82999a"))
	draw_circle(Vector2(885, 170), 96.0, Color(1.0, 0.92, 0.67, 0.78))
	draw_rect(Rect2(118, 170, 360, 270), Color("#d6c9a6"), true)
	draw_rect(Rect2(142, 194, 312, 222), Color("#6f8587"), true)
	draw_rect(Rect2(190, 230, 216, 186), Color("#b9e2e6"), true)
	draw_line(Vector2(298, 230), Vector2(298, 416), Color("#edf8f4"), 5.0)
	draw_string(ThemeDB.fallback_font, Vector2(540, 300), "美术馆外", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#243b47"))
	draw_string(ThemeDB.fallback_font, Vector2(500, 360), "你终于看见了出口。", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#314f5b"))

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
		if not s03_mirror_intervened and mouse_position.distance_to(Vector2(1010, 410)) <= 70.0:
			chalk_hover_target = "Mirror"
	elif S04_ENABLED and s04_active:
		if s04_pigment_applied and not s04_lamp_observed and mouse_position.distance_to(Vector2(501, 322)) <= 52.0:
			chalk_hover_target = "Lamp"
	elif S05_ENABLED and s05_active:
		if not s05_window_open and mouse_position.distance_to(Vector2(840, 462)) <= 68.0:
			chalk_hover_target = "Window"
	elif S06_ENABLED and s06_active:
		if not s06_sensor_revealed and mouse_position.distance_to(Vector2(576, 292)) <= 62.0:
			chalk_hover_target = "Sensor"
	elif S07_ENABLED and s07_active:
		if not s07_mirror_trace_found and mouse_position.distance_to(Vector2(205, 410)) <= 62.0:
			chalk_hover_target = "ReturnMirror"
		elif s07_window_observed and not s07_window_trace_found and mouse_position.distance_to(Vector2(840, 410)) <= 68.0:
			chalk_hover_target = "ReturnWindow"
	elif S08_ENABLED and s08_active:
		if not s08_window_open and mouse_position.distance_to(Vector2(840, 462)) <= 68.0:
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
