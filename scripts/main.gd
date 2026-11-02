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

# S02 second hall, "表与里": the invisible mirror runs through 《机械维纳斯》 at this x.
# Left of it is the warm 表 (the S01 carpet continues), right of it the cold 里.
const S02_AXIS_X := 552.0
# The runner carpet slowly becomes a conveyor belt that runs back toward the entrance.
# Its pull grows from nothing at S02_BELT_START to Graham's full walking speed at S02_BELT_FULL.
const S02_BELT_START := 400.0                  # the carpet is still up to here (so the lamp and painting can be used)
const S02_BELT_FULL := 556.0
const S02_BELT_MIN_DRIFT := 45.0
const S02_DOOR_RECT := Rect2(92, 270, 52, 102)
const S02_GUARD_X := 190.0
const S02_NARCISSUS_RECT := Rect2(280, 215, 100, 96)
const S02_LIGHT_TOP := 170.0                   # the inverted prism's base (top edge)
const S02_LIGHT_HALF := 35.0
const S02_LIGHT_APEX_Y := 192.0
const S02_EYE := Vector2(552, 229)             # where the crossed beams meet: Venus's missing eyes
const S02_STALL_X := 525.0
const S02_FIGURE_AFTER := 5.0                  # seconds standing still before Blue Lake's figure shows
# S03: the picture lamp over 《那喀索斯》 and the real water at the bottom of the frame.
const S03_PICTURE_LAMP := Vector2(250, 200)
const S03_WATER_Y := 304.0
# Where the lamp's light lands on the water for each of its angles; only the last one reflects into the prism.
const S03_WATER_HITS := [296.0, 318.0, 342.0, 372.0]
const S03_LAMP_GOOD := 3
const S03_GUARD_AT_VENUS := 505.0
# Blue Lake riding the belt through the 里 side, and the bonsai pot it pushes onto the belt.
const S03_RIDE_SPEED := 45.0
const S03_POT_START := 914.0                   # = the guard's mirrored place
const S03_POT_STOP := 622.0                    # the chain stops it here, in the warm light from Venus's eye
# Borrowing Venus's eyes: what she shows Graham, then what the exhibits say to each other (first draft;
# the user will rewrite all dialogue).
const S03_POV_LINES := [
	"（维纳斯的视角。她站得高，展厅第一次亮了：在她眼里，冷的是表，暖的是里。）",
	"格雷汉：……看她的肩膀。\n保安戴着手套的手，叶子里那几根“手指”，正好接在她的两个断口上。",
	"少年：水里那个人，今天也很好看。",
	"维纳斯：从前这里没有水。",
	"少年：……那我一直在看什么？\n骷髅：在看我。",
	"维纳斯：我的左边不会老，右边一直在烂。你说，哪一边才是我？",
	"骷髅：烂的那边。不会老的东西，不是活的。",
	"维纳斯：那个人替我举着手，举了很多年。他以为我要指路。\n我只是想照一照镜子。"
]

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
var s02_guard_asked := false
var s02_belt_stalled := false
var s02_carried_back := false
var s02_idle_time := 0.0
var s02_figure_alpha := 0.0       # easter egg: Blue Lake's figure on the 里 side
var s02_interactables: Array[Dictionary] = []
var s03_active := false
var s03_busy := false               # a scripted moment is playing
var s03_lamp_fixed := false
var s03_lamp_angle := 0
var s03_eye_lit := false
var s03_pov_active := false        # looking through Venus's eye
var s03_pov_line := -1
var s03_pov_timer := 0.0
var s03_hands_seen := false
var s03_glove_off := false
var s03_guard_x := 190.0
var s03_guard_walking := false
var s03_arms_returned := false
var s03_mirror_held := false
var s03_crossed := false           # Graham has traded places with her reflection
var s03_ride_active := false       # Blue Lake (the reflection) is riding the belt through the 里 side
var s03_ride_x := 0.0
var s03_ride_done := false
var s03_pot_x := 914.0
var s03_pot_on_belt := false
var s03_leaves_fallen := false
var s03_left_arm_ready := false    # the guard has brought the marble arm to Venus
var s03_right_arm_ready := false   # the iron arm lies free in the bonsai by the chain
var s03_left_installed := false
var s03_right_installed := false
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
	_update_s02(delta)
	_update_s03(delta)
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
		# 表 side only (Graham cannot cross the belt): door, guard, 《那喀索斯》, 《光》, 《机械维纳斯》.
		# Their 里 counterparts hang or stand at the mirrored x on the right.
		{"name":"HallDoor", "position":Vector2(118,440), "radius":30.0, "hint_y":376.0},
		{"name":"SecurityGuard", "position":Vector2(S02_GUARD_X,440), "radius":45.0, "hint_y":258.0},
		{"name":"PictureLamp", "position":Vector2(S03_PICTURE_LAMP.x,440), "radius":20.0, "hint_y":376.0},
		{"name":"Narcissus", "position":Vector2(330,440), "radius":50.0, "hint_y":376.0},
		{"name":"SculptureLight", "position":Vector2(500,440), "radius":24.0, "hint_y":398.0},
		{"name":"SculptureVenus", "position":Vector2(S02_AXIS_X,440), "radius":30.0, "hint_y":398.0}
	]
	# Interim: S03 and S07 still use the old hall layout until S03 is rebuilt on 表与里.
	var legacy_hall_items: Array[Dictionary] = [
		# Left to right: 《镜中镜》, 《光》, guard, 《机械维纳斯》, then the dead-end mirror.
		{"name":"MirrorInMirror", "position":Vector2(260,440), "radius":50.0, "hint_y":376.0},
		{"name":"SculptureLight", "position":Vector2(420,440), "radius":35.0, "hint_y":398.0},
		{"name":"SecurityGuard", "position":Vector2(545,440), "radius":35.0, "hint_y":258.0},
		{"name":"SculptureVenus", "position":Vector2(700,440), "radius":40.0, "hint_y":398.0},
		{"name":"DeadEnd", "position":Vector2(983,440), "radius":38.0, "hint_y":398.0}
	]
	# S03 happens in the same hall as S02; the dead-end mirror is now the puzzle.
	# S03 happens in the same 表与里 hall as S02, with the same pieces.
	s03_interactables = s02_interactables.duplicate(true)
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
	for item in legacy_hall_items:
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
		_draw_s02_hall()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S03_ENABLED and s03_active:
		_draw_s02_hall()
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
		# Blue Lake was already here, years ago, in another form: a small girl with blue eyes in the crowd.
		_draw_s01_blue_lake_trace(Vector2(inner.position.x + 43.0, floor_y - 9.0), 0)
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
		# ...a white bear with blue eyes, left on the floor under the window.
		_draw_s01_blue_lake_trace(Vector2(inner.position.x + 40.0, floor_y), 1)
	else:
		# Many years later: nobody, dust, a cobweb in the corner.
		for i in range(14):
			draw_circle(inner.position + Vector2((i * 37) % int(inner.size.x), (i * 23) % int(inner.size.y)), 0.9, Color(1, 1, 1, 0.35))
		draw_line(inner.position, inner.position + Vector2(16, 0), Color(1, 1, 1, 0.3), 1.0)
		draw_line(inner.position, inner.position + Vector2(0, 14), Color(1, 1, 1, 0.3), 1.0)
		draw_line(inner.position, inner.position + Vector2(12, 10), Color(1, 1, 1, 0.3), 1.0)
		# ...a book with a blue cover and white pages, the only thing left in the empty hall.
		_draw_s01_blue_lake_trace(Vector2(inner.position.x + 30.0, floor_y + 1.0), 2)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 2, 340), "《美术馆开幕日》", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))

## Blue Lake hides in every chapter as something white-and-blue that can become something else.
## In the S01 photo: a blue-eyed girl (opening day), a white bear (winter), a blue book (years later).
## No dialogue points at them; they are there to be noticed, now or on a later visit.
func _draw_s01_blue_lake_trace(at: Vector2, form: int) -> void:
	var blue := Color("#2f86e0")
	if form == 0:
		draw_circle(at, 2.6, Color("#d9c3a5"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-2.5, 2.5), at + Vector2(2.5, 2.5), at + Vector2(4.0, 10.0), at + Vector2(-4.0, 10.0)]), Color("#f4f6f8"))
		draw_rect(Rect2(at + Vector2(-1.6, -0.6), Vector2(1.2, 1.2)), blue, true)
		draw_rect(Rect2(at + Vector2(0.6, -0.6), Vector2(1.2, 1.2)), blue, true)
	elif form == 1:
		draw_circle(at + Vector2(0, -3), 3.2, Color("#f4f6f8"))
		draw_circle(at + Vector2(-2.6, -6), 1.3, Color("#f4f6f8"))
		draw_circle(at + Vector2(2.6, -6), 1.3, Color("#f4f6f8"))
		draw_circle(at + Vector2(0, 1.5), 3.6, Color("#f4f6f8"))
		draw_rect(Rect2(at + Vector2(-1.8, -4.2), Vector2(1.1, 1.1)), blue, true)
		draw_rect(Rect2(at + Vector2(0.8, -4.2), Vector2(1.1, 1.1)), blue, true)
	else:
		draw_rect(Rect2(at + Vector2(-5, -3), Vector2(10, 4)), blue, true)
		draw_line(at + Vector2(-4, -1.5), at + Vector2(4, -1.5), Color("#f4f6f8"), 1.0)

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

func _s02_mx(x: float) -> float:
	return 2.0 * S02_AXIS_X - x

## 0 on the 表 side, 1 on the 里 side, blending across the axis over `half` pixels.
func _s02_k(x: float, half: float) -> float:
	return clampf((x - (S02_AXIS_X - half)) / (half * 2.0), 0.0, 1.0)

## How dark the second hall is for Graham. Only Venus's eye is lit until she holds the mirror.
func _s02_darkness() -> float:
	if s03_mirror_held:
		return 0.25
	return 0.86

func _draw_s02_hall() -> void:
	# 表与里: everything left of the axis has a counterpart at the mirrored x, made of something else.
	# The hall starts dark: in silhouette the 里 side reads as a reflection of the 表 side.
	var t := Time.get_ticks_msec() / 1000.0
	_draw_s02_room(t, false)
	var dark := _s02_darkness()
	_draw_s02_dark_overlay(dark)
	if dark > 0.5:
		_draw_s02_silhouettes()
	if s03_pot_on_belt and dark > 0.5:
		_draw_s02_bonsai()           # it rides into the warm light from Venus's eye
	_draw_s02_picture_lamps()
	if s03_eye_lit or s03_mirror_held:
		_draw_s02_light(t)
	if s03_mirror_held:
		_draw_s03_reflection()
	if blue_lake_active and s03_active and not s03_pov_active:
		_draw_s03_blue_lake_layer(t)
	_draw_s02_blue_lake_figure()
	if s03_pov_active:
		_draw_s03_venus_pov(t)

## The darkness, drawn in strips so that Blue Lake, riding the belt, carries a little light with it.
func _draw_s02_dark_overlay(dark: float) -> void:
	if not s03_ride_active:
		draw_rect(Rect2(84, 140, 936, 368), Color(0.02, 0.03, 0.05, dark), true)
		return
	var x := 84.0
	while x < 1020.0:
		var d := absf(x + 6.0 - s03_ride_x)
		var a := dark * clampf((d - 40.0) / 90.0, 0.25, 1.0)
		draw_rect(Rect2(x, 140, 12.6, 368), Color(0.02, 0.03, 0.05, a), true)
		x += 12.0

## The lit room. `pov` draws it the way Venus sees it (used inside her view).
func _draw_s02_room(t: float, _pov: bool) -> void:
	var left := 84.0
	var right := 1020.0
	var blend := 90.0
	var warm_wall := Color("#4a3628")
	var cold_wall := Color("#2c3b47")
	var warm_floor := Color("#3a2c22")
	var cold_floor := Color("#222c34")
	var steps := 24
	var w := (right - left) / steps
	for i in range(steps):
		var x0 := left + i * w
		var k := _s02_k(x0 + w * 0.5, blend)
		draw_rect(Rect2(x0, 140, w + 0.6, 232), warm_wall.lerp(cold_wall, k), true)
		draw_rect(Rect2(x0, 372, w + 0.6, 136), warm_floor.lerp(cold_floor, k), true)
	for x in range(int(left) + 6, int(S02_AXIS_X + blend), 12):
		draw_line(Vector2(x, 140), Vector2(x, 372), Color(1.0, 0.85, 0.6, 0.06 * (1.0 - _s02_k(x, blend))), 1.0)
	for x in range(int(S02_AXIS_X - blend), int(right), 26):
		draw_line(Vector2(x, 140), Vector2(x, 372), Color(0.8, 0.9, 1.0, 0.18 * _s02_k(x, blend)), 1.0)
		for y in range(152, 372, 26):
			draw_line(Vector2(x, y), Vector2(x + 26, y), Color(0.8, 0.9, 1.0, 0.18 * _s02_k(x + 13, blend)), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), "第二展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d8c7a8"))
	# Ceiling lights stay off until Venus holds the mirror.
	for lx in [250.0, 400.0]:
		for side in [0, 1]:
			var x: float = lx if side == 0 else _s02_mx(lx)
			draw_rect(Rect2(x - 10.0, 142, 20, 7), Color("#b9a27a") if side == 0 else Color("#8fa3b0"), true)
			if s03_mirror_held:
				var cone := Color(1.0, 0.86, 0.6, 0.06) if side == 0 else Color(0.7, 0.85, 1.0, 0.06)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 6.0, 149), Vector2(x + 6.0, 149), Vector2(x + 70.0, 340), Vector2(x - 70.0, 340)]), cone)
	_draw_s02_doors()
	_draw_s02_narcissus()
	_draw_s02_guard_and_bonsai()
	_draw_s02_runner(t)
	_draw_s02_venus()
	_draw_s02_stanchions()

## A person-shaped outline. The guard and the leafy bonsai share it, so in the dark they look like
## an object and its reflection.
func _draw_s02_person_shape(x: float, dir: float, col: Color) -> void:
	draw_circle(Vector2(x, 318), 15.0, col)
	draw_rect(Rect2(x - 16, 332, 32, 50), col, true)
	draw_rect(Rect2(x - 13, 382, 26, 16), col, true)
	draw_line(Vector2(x + dir * 14, 342), Vector2(x + dir * 50, 330), col, 7.0)

func _draw_s02_silhouettes() -> void:
	var rim := Color(0.55, 0.6, 0.66, 0.35)
	var body := Color(0.05, 0.06, 0.08, 1.0)
	if not s03_glove_off:
		_draw_s02_person_shape(s03_guard_x - 1.0, 1.0, rim)
		_draw_s02_person_shape(s03_guard_x, 1.0, body)
	if not s03_pot_on_belt and not s03_ride_active:
		_draw_s02_person_shape(s03_pot_x - 1.0, -1.0, rim)
		_draw_s02_person_shape(s03_pot_x, -1.0, body)
	for door in [S02_DOOR_RECT, Rect2(_s02_mx(S02_DOOR_RECT.end.x), S02_DOOR_RECT.position.y, S02_DOOR_RECT.size.x, S02_DOOR_RECT.size.y)]:
		draw_rect(door, rim, false, 1.5)
	for frame in [S02_NARCISSUS_RECT, Rect2(_s02_mx(S02_NARCISSUS_RECT.end.x), S02_NARCISSUS_RECT.position.y, S02_NARCISSUS_RECT.size.x, S02_NARCISSUS_RECT.size.y)]:
		draw_rect(frame, rim, false, 1.5)
	draw_circle(S02_EYE, 12.0, rim)
	draw_rect(Rect2(S02_AXIS_X - 25, 320, 50, 52), rim, false, 1.5)
	draw_line(Vector2(S02_AXIS_X, 240), Vector2(S02_AXIS_X, 320), rim, 18.0)
	var prism := PackedVector2Array([Vector2(S02_AXIS_X - S02_LIGHT_HALF, S02_LIGHT_TOP), Vector2(S02_AXIS_X + S02_LIGHT_HALF, S02_LIGHT_TOP), Vector2(S02_AXIS_X, S02_LIGHT_APEX_Y), Vector2(S02_AXIS_X - S02_LIGHT_HALF, S02_LIGHT_TOP)])
	draw_polyline(prism, rim, 1.5)

func _draw_s02_doors() -> void:
	# The entrance (S01's door seen from inside) and its 里 counterpart. The materials swap with S01's route.
	var future := s01_exit_route == "future"
	var r := S02_DOOR_RECT
	var r2 := Rect2(_s02_mx(r.end.x), r.position.y, r.size.x, r.size.y)
	_draw_s02_door(r, future)
	_draw_s02_door(r2, not future)
	draw_rect(r2, Color(0.4, 0.6, 0.8, 0.12), true)
	for door in [r, r2]:
		draw_string(ThemeDB.fallback_font, Vector2(door.position.x + 12, door.position.y - 6), "出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d9d4b6"))
	# An inventory tag hangs from the 里 door's handle. It carries Graham's name.
	var tag_at := Vector2(r2.position.x + 8.0, r2.get_center().y + 8.0)
	draw_line(tag_at, tag_at + Vector2(0, 8), Color("#9fb0bb"), 1.0)
	draw_rect(Rect2(tag_at + Vector2(-9, 8), Vector2(18, 10)), Color("#cfd6d8"), true)

func _draw_s02_door(r: Rect2, rusted: bool) -> void:
	if rusted:
		draw_rect(r, Color("#4b2c1d"), true)
		var inner := r.grow_individual(-6, -6, -6, 0)
		draw_rect(inner, Color("#6e3b22"), true)
		draw_rect(Rect2(inner.position + Vector2(9, 30), Vector2(20, 26)), Color("#0e1620"), true)
		for i in range(14):
			var p := inner.position + Vector2(fmod(i * 17.0, inner.size.x), fmod(i * 29.0, inner.size.y))
			draw_circle(p, 2.0 + (i % 3), Color(0.55, 0.3, 0.16, 0.9))
	else:
		draw_rect(r, Color("#5a3f2a"), true)
		var inner := r.grow_individual(-6, -6, -6, 0)
		draw_rect(inner, Color("#7a5536"), true)
		draw_rect(Rect2(inner.position + Vector2(6, 8), Vector2(inner.size.x - 12, 34)), Color("#6a472c"), false, 2.0)
		draw_rect(Rect2(inner.position + Vector2(6, 50), Vector2(inner.size.x - 12, 34)), Color("#6a472c"), false, 2.0)
		draw_circle(Vector2(inner.end.x - 7.0, inner.get_center().y + 4.0), 3.0, Color("#d9c997"))

func _draw_s02_narcissus() -> void:
	# 《那喀索斯》 split in two. The water at the bottom of the frame is real (and reflects).
	# 表: the boy bows over it. 里, at the mirrored place: a kneeling skeleton.
	var r := S02_NARCISSUS_RECT
	draw_rect(r, Color("#b49464"), true)
	var inner := r.grow(-7.0)
	draw_rect(inner, Color("#3a2e24"), true)
	var skin := Color("#d9b89a")
	draw_colored_polygon(PackedVector2Array([Vector2(310, 252), Vector2(336, 258), Vector2(340, 284), Vector2(312, 292)]), Color("#8a5a3c"))
	draw_circle(Vector2(345, 262), 7.0, skin)
	draw_line(Vector2(337, 266), Vector2(354, 294), skin, 3.0)
	draw_rect(Rect2(304, 286, 40, 8), Color("#5d4030"), true)
	_draw_s02_water(Rect2(inner.position.x, S03_WATER_Y - 3.0, inner.size.x, inner.end.y - S03_WATER_Y + 3.0), false)
	draw_rect(Rect2(r.position.x + 25, r.end.y + 8, 50, 12), Color("#b39552"), true)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 12, r.end.y + 38), "《那喀索斯》", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	var r2 := Rect2(_s02_mx(r.end.x), r.position.y, r.size.x, r.size.y)
	draw_rect(r2, Color("#6b6a64"), true)
	var inner2 := r2.grow(-7.0)
	draw_rect(inner2, Color("#1f272d"), true)
	var bone := Color("#d8d4c4")
	var skull := Vector2(_s02_mx(345), 262)
	draw_circle(skull, 7.0, bone)
	draw_circle(skull + Vector2(-2.5, -1), 1.6, Color("#1f272d"))
	draw_circle(skull + Vector2(2.0, -1), 1.6, Color("#1f272d"))
	draw_line(Vector2(_s02_mx(336), 260), Vector2(_s02_mx(318), 286), bone, 2.0)
	for i in range(4):
		var y := 262.0 + i * 6.0
		draw_line(Vector2(_s02_mx(336) - i * 1.5, y), Vector2(_s02_mx(320) + i * 1.0, y + 4.0), bone, 1.0)
	draw_line(Vector2(_s02_mx(337), 266), Vector2(_s02_mx(354), 294), bone, 1.5)
	draw_line(Vector2(_s02_mx(306), 292), Vector2(_s02_mx(342), 292), bone, 1.5)
	_draw_s02_water(Rect2(inner2.position.x, S03_WATER_Y - 3.0, inner2.size.x, inner2.end.y - S03_WATER_Y + 3.0), true)
	var tag := Rect2(r2.position.x + 30, r2.end.y + 8, 40, 14)
	draw_rect(tag, Color("#cfd6d8"), true)
	for i in range(8):
		draw_line(Vector2(tag.position.x + 4 + i * 4, tag.position.y + 3), Vector2(tag.position.x + 4 + i * 4, tag.end.y - 3), Color("#2a3238"), 1.0 + (i % 2))
	draw_string(ThemeDB.fallback_font, Vector2(tag.position.x + 2, tag.end.y + 12), "No.0332", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#9fb0bb"))

func _draw_s02_water(r: Rect2, cold: bool) -> void:
	var lit := s03_eye_lit or s03_mirror_held
	var base := Color(0.25, 0.42, 0.5, 0.9) if not cold else Color(0.2, 0.32, 0.42, 0.9)
	draw_rect(r, base, true)
	var t := Time.get_ticks_msec() / 1000.0
	for i in range(3):
		var y := r.position.y + 2.0 + i * 3.0
		var off := sin(t * 2.0 + i) * 4.0
		draw_line(Vector2(r.position.x + 4 + off, y), Vector2(r.end.x - 4 + off, y), Color(0.85, 0.95, 1.0, 0.25 + (0.35 if lit else 0.0)), 1.0)
	if lit and not cold:
		# The boy finally sees himself: his reflection, upside down in the water.
		draw_circle(Vector2(345, r.position.y + 5.0), 3.5, Color(0.85, 0.72, 0.6, 0.7))

func _draw_s02_picture_lamps() -> void:
	# A picture lamp on a long arm over each 《那喀索斯》. 表 warm, 里 cold; the 里 one mirrors the 表 one.
	for side in [0, 1]:
		var lamp := S03_PICTURE_LAMP if side == 0 else Vector2(_s02_mx(S03_PICTURE_LAMP.x), S03_PICTURE_LAMP.y)
		var mount := Vector2(S02_NARCISSUS_RECT.position.x + 10.0, S02_NARCISSUS_RECT.position.y)
		if side == 1:
			mount.x = _s02_mx(mount.x)
		draw_line(mount, lamp, Color("#8d7b5c") if side == 0 else Color("#6f7a80"), 2.0)
		draw_circle(lamp, 5.0, Color("#c8a35a") if side == 0 else Color("#8a969c"))
		if not s03_lamp_fixed:
			continue
		var beam := Color(1.0, 0.85, 0.55, 0.32) if side == 0 else Color(0.6, 0.8, 1.0, 0.32)
		var hit := _s03_water_hit(s03_lamp_angle)
		var end := _s03_reflection_end(s03_lamp_angle)
		if side == 1:
			hit.x = _s02_mx(hit.x)
			end.x = _s02_mx(end.x)
		draw_circle(lamp, 7.0, Color(beam.r, beam.g, beam.b, 0.8))
		draw_line(lamp, hit, beam, 3.0)
		draw_line(hit, end, beam, 3.0)
		draw_circle(hit, 4.0, Color(1, 1, 1, 0.5))
		draw_circle(end, 5.0, Color(beam.r, beam.g, beam.b, 0.5))

func _draw_s02_guard_and_bonsai() -> void:
	# The guard (long sleeves, gloves) has stood by the door for years, "pointing" across: he is
	# holding Venus's marble arm. In 里 a bonsai thick with rust-iron leaves holds her iron arm.
	var gx := s03_guard_x
	var uniform := Color("#566b7a")
	var marble := Color("#e8e4da")
	draw_circle(Vector2(gx, 318), 14.0, Color("#bba88c"))
	draw_rect(Rect2(gx - 14, 300, 28, 7), Color("#2d3a46"), true)
	draw_rect(Rect2(gx - 15, 332, 30, 50), uniform, true)
	draw_line(Vector2(gx - 7, 382), Vector2(gx - 7, 398), Color("#3a4a56"), 5.0)
	draw_line(Vector2(gx + 7, 382), Vector2(gx + 7, 398), Color("#3a4a56"), 5.0)
	if s03_left_installed:
		# Arm down at last.
		draw_line(Vector2(gx + 13, 340), Vector2(gx + 16, 372), uniform, 6.0)
		draw_circle(Vector2(gx + 16, 375), 3.5, Color("#bba88c"))
	elif s03_glove_off:
		# Holding the marble arm out (walking to Venus, then waiting beside her).
		draw_line(Vector2(gx + 13, 342), Vector2(gx + 26, 352), uniform, 6.0)
		draw_line(Vector2(gx + 24, 350), Vector2(gx + 52, 344), marble, 6.0)
		draw_circle(Vector2(gx + 54, 343), 4.0, marble)
	else:
		draw_line(Vector2(gx + 14, 342), Vector2(gx + 44, 331), uniform, 6.0)
		draw_circle(Vector2(gx + 49, 329), 5.0, Color("#d6d2c6"))
	if not s03_glove_off:
		draw_string(ThemeDB.fallback_font, Vector2(gx - 18, 290), "保安", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
	_draw_s02_bonsai()

func _draw_s02_bonsai() -> void:
	var bx := s03_pot_x
	var dy := 16.0 if s03_pot_on_belt else 0.0      # on the belt it sits a little forward
	var wood := Color("#6f6658")
	var wire := Color("#9a5a32")
	draw_colored_polygon(PackedVector2Array([Vector2(bx - 15, 382 + dy), Vector2(bx + 15, 382 + dy), Vector2(bx + 12, 398 + dy), Vector2(bx - 12, 398 + dy)]), Color("#56635f"))
	draw_line(Vector2(bx, 382 + dy), Vector2(bx, 330 + dy), wood, 5.0)
	draw_line(Vector2(bx - 2, 342 + dy), Vector2(bx - 44, 331 + dy), wood, 4.0)
	if not s03_leaves_fallen:
		# Rust-iron leaves in a person's outline; a few finger-like twigs stick out at the branch tip.
		var leaf := Color("#8a4b2a")
		for i in range(26):
			var a := i * 2.4
			var rr := 4.0 + fmod(i * 7.0, 11.0)
			draw_circle(Vector2(bx, 318 + dy) + Vector2(cos(a), sin(a)) * rr * 0.9, 4.0, leaf.darkened(fmod(i * 0.13, 0.4)))
		for i in range(40):
			var p := Vector2(bx - 14 + fmod(i * 7.3, 28.0), 334 + dy + fmod(i * 11.0, 48.0))
			draw_circle(p, 4.0, leaf.darkened(fmod(i * 0.07, 0.35)))
		for i in range(10):
			var p := Vector2(bx - 14 - i * 3.0, 340 + dy - i * 1.0)
			draw_circle(p, 3.5, leaf)
		for k in range(4):
			draw_line(Vector2(bx - 46, 331 + dy), Vector2(bx - 54, 326 + dy + k * 3.0), Color("#7c4a2c"), 1.5)
		for i in range(6):
			var p := Vector2(bx - 8 - i * 6, 339 + dy - i * 1.5)
			draw_line(p + Vector2(0, -3), p + Vector2(3, 3), wire, 1.2)
	else:
		# Bare: the leaves lie around the pot, the wire hangs loose.
		for i in range(14):
			draw_circle(Vector2(bx - 18 + fmod(i * 5.0, 36.0), 396 + dy), 2.5, Color("#6e3b22"))
		draw_line(Vector2(bx - 20, 336 + dy), Vector2(bx - 24, 350 + dy), wire, 1.2)
		if not s03_right_installed:
			# The iron arm, free in the branches.
			draw_line(Vector2(bx - 8, 340 + dy), Vector2(bx - 46, 334 + dy), Color("#7c4a2c"), 6.0)
			draw_circle(Vector2(bx - 48, 333 + dy), 4.0, Color("#6a3c22"))
	draw_line(Vector2(bx - 30, 335 + dy), Vector2(bx - 30, 343 + dy), Color("#9fb0bb"), 1.0)
	draw_rect(Rect2(bx - 40, 343 + dy, 22, 11), Color("#cfd6d8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(bx - 39, 352 + dy), "保安", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#2a3238"))

func _draw_s02_runner(t: float) -> void:
	var y0 := 392.0
	var h := 108.0
	var start := 100.0
	var end := 1012.0
	var half := 60.0
	var steps := 40
	var w := (end - start) / steps
	for i in range(steps):
		var x0 := start + i * w
		var k := _s02_k(x0 + w * 0.5, half)
		draw_rect(Rect2(x0, y0, w + 0.6, h), Color("#5e2a26").lerp(Color("#24292d"), k), true)
	draw_line(Vector2(start + 6, y0 + 5), Vector2(S02_AXIS_X - half, y0 + 5), Color("#c19a5b"), 2.0)
	draw_line(Vector2(start + 6, y0 + h - 5), Vector2(S02_AXIS_X - half, y0 + h - 5), Color("#c19a5b"), 2.0)
	for i in range(12):
		var x := S02_AXIS_X - half + i * 10.0
		var a := 1.0 - i / 12.0
		draw_line(Vector2(x, y0 + 5), Vector2(x + 10, y0 + 5), Color(0.76, 0.6, 0.36, a), 2.0)
		draw_line(Vector2(x, y0 + h - 5), Vector2(x + 10, y0 + h - 5), Color(0.76, 0.6, 0.36, a), 2.0)
	draw_line(Vector2(S02_AXIS_X - half, y0 + 1), Vector2(end, y0 + 1), Color(0.6, 0.66, 0.7, 0.5), 3.0)
	draw_line(Vector2(S02_AXIS_X - half, y0 + h - 1), Vector2(end, y0 + h - 1), Color(0.6, 0.66, 0.7, 0.5), 3.0)
	var speed: float = 0.0 if s03_crossed else (player.speed if player else 0.0)
	var offset := fmod(t * speed, 28.0)
	var x := S02_AXIS_X - half * 2.0 + 28.0 - offset
	while x < end:
		var k := _s02_k(x, half)
		if k > 0.0:
			draw_line(Vector2(x, y0 + 4), Vector2(x, y0 + h - 4), Color(0.05, 0.06, 0.07, 0.8 * k), 2.0)
		x += 28.0
	var arrow_offset := fmod(t * speed, 112.0)
	var ax := S02_AXIS_X - half + 112.0 - arrow_offset
	while ax < end - 10.0:
		var k := _s02_k(ax, half)
		if k > 0.0:
			draw_colored_polygon(PackedVector2Array([Vector2(ax, y0 + h * 0.5), Vector2(ax + 16, y0 + h * 0.5 - 9), Vector2(ax + 16, y0 + h * 0.5 + 9)]), Color(0.8, 0.78, 0.62, 0.45 * k))
		ax += 112.0

func _draw_s02_venus() -> void:
	# 《机械维纳斯》 on the axis: marble on the 表 side, rusted metal on the 里 side.
	var marble := Color("#cfc8b8")
	var rust := Color("#7c4a2c")
	var ax := S02_AXIS_X
	draw_rect(Rect2(ax - 25, 320, 25, 52), marble.darkened(0.15), true)
	draw_rect(Rect2(ax, 320, 25, 52), rust.darkened(0.15), true)
	var body_left := PackedVector2Array([Vector2(ax, 240), Vector2(ax - 6, 242), Vector2(ax - 16, 250), Vector2(ax - 18, 258), Vector2(ax - 13, 268), Vector2(ax - 11, 284), Vector2(ax - 19, 302), Vector2(ax - 16, 320), Vector2(ax, 320)])
	var body_right := PackedVector2Array()
	for p in body_left:
		body_right.append(Vector2(_s02_mx(p.x), p.y))
	draw_colored_polygon(body_left, marble)
	draw_colored_polygon(body_right, rust)
	var head_left := PackedVector2Array()
	var head_right := PackedVector2Array()
	for i in range(13):
		var a := PI * 0.5 + PI * i / 12.0
		head_left.append(S02_EYE + Vector2(cos(a), sin(a)) * 12.0)
		head_right.append(S02_EYE + Vector2(-cos(a), sin(a)) * 12.0)
	draw_colored_polygon(head_left, marble)
	draw_colored_polygon(head_right, rust)
	for i in range(7):
		var y := 246.0 + i * 11.0
		draw_line(Vector2(ax + 1, y), Vector2(ax - 4 - (i % 3) * 4, y + 6), Color(0.48, 0.29, 0.17, 0.75), 1.5)
		draw_circle(Vector2(ax + 3 + (i % 2) * 5, y + 3), 1.2, Color(0.8, 0.77, 0.7, 0.6))
	for i in range(6):
		draw_circle(Vector2(ax + 6 + fmod(i * 5.0, 12.0), 252 + i * 11.0), 1.8, Color("#5a2f1a"))
	draw_circle(S02_EYE + Vector2(-5, 0), 2.2, Color("#2a2420"))
	draw_circle(S02_EYE + Vector2(5, 0), 2.2, Color("#1c1410"))
	if s03_left_installed:
		draw_line(Vector2(ax - 17, 254), Vector2(ax - 26, 282), marble, 6.0)
		draw_line(Vector2(ax - 26, 282), Vector2(ax - 14, 292), marble, 5.0)
	if s03_right_installed:
		draw_line(Vector2(ax + 17, 254), Vector2(ax + 26, 282), rust, 6.0)
		draw_line(Vector2(ax + 26, 282), Vector2(ax + 14, 292), rust, 5.0)
	if s03_mirror_held:
		draw_set_transform(Vector2(ax, 290), 0.0, Vector2(0.55, 1.0))
		draw_circle(Vector2.ZERO, 20.0, Color("#b8a272"))
		draw_circle(Vector2.ZERO, 17.0, Color(0.75, 0.86, 0.95, 0.95))
		draw_set_transform(Vector2.ZERO)
		draw_line(Vector2(ax - 4, 278), Vector2(ax + 3, 300), Color(1, 1, 1, 0.7), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(ax - 44, 392), "《机械维纳斯》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))

func _draw_s02_stanchions() -> void:
	var lx := 500.0
	var rx := _s02_mx(lx)
	draw_line(Vector2(lx, 352), Vector2(lx, 398), Color("#c8a35a"), 4.0)
	draw_circle(Vector2(lx, 352), 4.0, Color("#d8b46a"))
	draw_line(Vector2(rx, 352), Vector2(rx, 398), Color("#7a4a2a"), 4.0)
	draw_circle(Vector2(rx, 352), 4.0, Color("#6a3c22"))
	var prev := Vector2(lx, 355)
	for i in range(1, 11):
		var u := i / 10.0
		var p := Vector2(lerpf(lx, S02_AXIS_X, u), 355.0 + sin(u * PI * 0.5) * 12.0)
		draw_line(prev, p, Color("#9c2f2a"), 3.0)
		prev = p
	for i in range(11):
		var u := i / 10.0
		var p := Vector2(lerpf(S02_AXIS_X, rx, u), 355.0 + cos(u * PI * 0.5) * 12.0)
		draw_arc(p, 2.4, 0.0, TAU, 8, Color("#8a5232"), 1.3)

func _draw_s02_light(t: float) -> void:
	# 《光》: the two reflected beams (warm from the boy's water, cold from the skeleton's) enter the
	# inverted prism and cross under its apex — at Venus's missing eyes — and land swapped.
	var ax := S02_AXIS_X
	var warm := Color(1.0, 0.78, 0.45, 0.2)
	var cold := Color(0.55, 0.78, 1.0, 0.2)
	var e := S02_EYE
	draw_colored_polygon(PackedVector2Array([Vector2(ax - 30, 173), Vector2(ax - 7, 188), Vector2(e.x + 1.5, e.y), Vector2(e.x - 1.5, e.y)]), warm)
	draw_colored_polygon(PackedVector2Array([Vector2(e.x - 1.5, e.y), Vector2(e.x + 1.5, e.y), Vector2(ax + 70, 372), Vector2(ax + 38, 372)]), warm)
	draw_colored_polygon(PackedVector2Array([Vector2(ax + 30, 173), Vector2(ax + 7, 188), Vector2(e.x - 1.5, e.y), Vector2(e.x + 1.5, e.y)]), cold)
	draw_colored_polygon(PackedVector2Array([Vector2(e.x + 1.5, e.y), Vector2(e.x - 1.5, e.y), Vector2(ax - 70, 372), Vector2(ax - 38, 372)]), cold)
	draw_set_transform(Vector2(ax + 54, 378), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22.0, Color(1.0, 0.8, 0.5, 0.18))
	draw_set_transform(Vector2(ax - 54, 378), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22.0, Color(0.6, 0.8, 1.0, 0.18))
	draw_set_transform(Vector2.ZERO)
	var prism := PackedVector2Array([Vector2(ax - S02_LIGHT_HALF, S02_LIGHT_TOP), Vector2(ax + S02_LIGHT_HALF, S02_LIGHT_TOP), Vector2(ax, S02_LIGHT_APEX_Y)])
	draw_colored_polygon(prism, Color(0.82, 0.92, 1.0, 0.45))
	draw_polyline(PackedVector2Array([prism[0], prism[1], prism[2], prism[0]]), Color(0.95, 0.98, 1.0, 0.8), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(ax - 78, 168), "《光》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	var pulse := 0.85 + sin(t * 2.0) * 0.1
	draw_set_transform(e, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.97, 0.88, 0.8 * pulse))
	draw_circle(Vector2.ZERO, 4.5, Color(0.25, 0.3, 0.4, 0.85))
	draw_set_transform(Vector2.ZERO)

func _draw_s03_reflection() -> void:
	# Venus's mirror gives Graham a reflection at her mirrored place on the 里 side (before she crosses),
	# or on the 表 side after (she and her reflection have traded places).
	if not player:
		return
	var at := Vector2(_s02_mx(player.position.x), player.position.y)
	var c := Color(0.75, 0.88, 1.0, 0.55)
	draw_circle(at + Vector2(0, -4), 15.0, Color(0.17, 0.21, 0.28, 0.6))
	draw_circle(at, 13.0, Color(0.95, 0.8, 0.7, 0.45))
	draw_rect(Rect2(at.x - 10, at.y + 7, 20, 18), Color(0.3, 0.47, 0.66, 0.55), true)
	draw_arc(at + Vector2(0, 4), 24.0, 0.0, TAU, 24, c, 1.0)

func _draw_s03_blue_lake_layer(t: float) -> void:
	# Blue Lake sees the mirror the hall is split by, and the threads joining each pair.
	var chalk := Color(0.75, 0.92, 1.0, 0.75)
	var y := 150.0
	while y < 500.0:
		draw_line(Vector2(S02_AXIS_X, y), Vector2(S02_AXIS_X, y + 10.0), chalk, 2.0)
		y += 18.0
	var pairs := [Vector2(S02_GUARD_X + 49, 329), S02_DOOR_RECT.get_center(), S02_NARCISSUS_RECT.get_center(), S03_PICTURE_LAMP]
	for p: Vector2 in pairs:
		var q := Vector2(_s02_mx(p.x), p.y)
		var dash := 0.0
		var seg_len := p.distance_to(q)
		while dash < seg_len:
			draw_line(p.lerp(q, dash / seg_len), p.lerp(q, minf(dash + 6.0, seg_len) / seg_len), Color(0.75, 0.92, 1.0, 0.35), 1.0)
			dash += 14.0
	if true:
		var glow := 0.85 if chalk_hover_target == "VenusEye" else 0.45 + sin(t * 3.0) * 0.1
		draw_arc(S02_EYE, 22.0, 0.0, TAU, 24, Color(0.75, 0.91, 1.0, glow), 2.0)

func _draw_s03_venus_pov(t: float) -> void:
	# Venus's view: she faces out, stands high, and is lit by the crossed beams. What is 表 to Graham is on
	# her right, 里 on her left, and in her eye the 里 is the warm side. Only from here do the guard's gloved
	# hand and the leaves' twig "fingers" sit exactly on her shoulders' broken ends.
	var r := Rect2(84, 140, 936, 368)
	draw_rect(r, Color("#0b0f14"), true)
	var warm := Color("#6b4a32")
	var cold := Color("#2f4250")
	var mid := r.get_center().x
	for i in range(24):
		var x0 := r.position.x + i * r.size.x / 24.0
		var k := clampf((x0 - (mid - 120.0)) / 240.0, 0.0, 1.0)
		draw_rect(Rect2(x0, r.position.y, r.size.x / 24.0 + 0.6, 170), warm.lerp(cold, k), true)
	# The floor seen from above, falling away under her: belt on her left, carpet on her right.
	draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, 310), Vector2(mid, 300), Vector2(mid, r.end.y), Vector2(r.position.x, r.end.y)]), Color("#2a2f33"))
	draw_colored_polygon(PackedVector2Array([Vector2(mid, 300), Vector2(r.end.x, 310), Vector2(r.end.x, r.end.y), Vector2(mid, r.end.y)]), Color("#5e2a26"))
	# Graham, small, far below, looking up.
	if player:
		draw_circle(Vector2(mid + 40, 400), 7.0, Color("#2b3547"))
		draw_rect(Rect2(mid + 35, 405, 10, 9), Color("#4b79a8"), true)
	# Periphery: the bonsai (her left) and the guard (her right), with the arms they hold.
	var stump_l := Vector2(r.position.x + 150, 470)
	var stump_r := Vector2(r.end.x - 150, 470)
	draw_circle(Vector2(r.position.x + 60, 250), 40.0, Color("#8a4b2a"))
	draw_rect(Rect2(r.position.x + 20, 280, 80, 130), Color("#7a4226"), true)
	draw_line(Vector2(r.position.x + 95, 330), stump_l + Vector2(-8, -40), Color("#6f6658"), 9.0)
	draw_circle(Vector2(r.end.x - 60, 250), 36.0, Color("#bba88c"))
	draw_rect(Rect2(r.end.x - 100, 284, 80, 130), Color("#566b7a"), true)
	draw_line(Vector2(r.end.x - 95, 330), stump_r + Vector2(8, -40), Color("#566b7a"), 12.0)
	draw_circle(stump_r + Vector2(4, -38), 9.0, Color("#d6d2c6"))
	for k in range(4):
		draw_line(stump_l + Vector2(-8, -40), stump_l + Vector2(-2 + k * 4, -30), Color("#7c4a2c"), 2.0)
	# Her own shoulders at the bottom corners: rust on her left, marble on her right.
	draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, r.end.y), Vector2(r.position.x, 470), stump_l + Vector2(-10, -12), stump_l + Vector2(30, 0), Vector2(r.position.x + 260, r.end.y)]), Color("#7c4a2c"))
	draw_colored_polygon(PackedVector2Array([Vector2(r.end.x, r.end.y), Vector2(r.end.x, 470), stump_r + Vector2(10, -12), stump_r + Vector2(-30, 0), Vector2(r.end.x - 260, r.end.y)]), Color("#cfc8b8"))
	# The hands meet the broken ends: chalk marks the fit.
	var pulse := 0.5 + sin(t * 3.0) * 0.25
	for s in [stump_l, stump_r]:
		draw_arc(s + Vector2(0, -20), 26.0, 0.0, TAU, 24, Color(0.75, 0.92, 1.0, pulse), 2.0)
	# The crossing light: the rim of her view.
	draw_rect(r, Color(1.0, 0.95, 0.8, 0.08), false, 6.0)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 16, r.position.y + 24), "维纳斯的视角", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))

func _draw_s02_blue_lake_figure() -> void:
	# Easter egg: if Graham stands still on the 表 side, Blue Lake's own figure develops at the
	# mirrored spot on the 里 side — half her height, white and blue. No words.
	if s02_figure_alpha <= 0.01 or not player or s03_mirror_held:
		return
	var a := s02_figure_alpha
	var base := Vector2(s03_ride_x if s03_ride_active else _s02_mx(player.position.x), player.position.y)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-3, 12), base + Vector2(3, 12), base + Vector2(6, 25), base + Vector2(-6, 25)]), Color(0.0, 0.47, 0.84, a))
	draw_circle(base + Vector2(0, 7), 5.0, Color(1.0, 1.0, 1.0, a))
	draw_circle(base + Vector2(-1.8, 6.5), 1.0, Color(0.0, 0.47, 0.84, a))
	draw_circle(base + Vector2(1.8, 6.5), 1.0, Color(0.0, 0.47, 0.84, a))

func _draw_legacy_hall() -> void:
	# Interim (S03/S07 until rebuilt). One continuous hall, left to right: entrance, 《镜中镜》, 《光》, guard, 《机械维纳斯》, dead-end mirror.
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

func _draw_s04_gallery() -> void:
	# Right to left: arrival wall, visitor, 《窗》, lamp + switch, restorer, pigment station.
	draw_string(ThemeDB.fallback_font, Vector2(640, 175), "画作展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	draw_string(ThemeDB.fallback_font, Vector2(200, 175), "修复区", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	# The door Graham came through is on the left wall. S07 still revisits by the old chalk door
	# on the right wall until S07 is redesigned for the 表与里 hall.
	if s07_active:
		draw_rect(Rect2(998, 262, 22, 110), Color(0.75, 0.92, 1.0, 0.35), false, 2.0)
	else:
		draw_rect(Rect2(62, 262, 22, 110), Color("#4b2c1d"), true)
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
		_draw_legacy_hall()
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
		_show_dialogue("蓝湖：这就是我看到的。把粉笔移到维纳斯的眼睛上，点左键。")
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
	s02_guard_asked = false
	s02_belt_stalled = false
	s02_carried_back = false
	s02_idle_time = 0.0
	s02_figure_alpha = 0.0
	chapter_state.advance_to(ChapterState.Slice.S02_LOST)
	chapter_state.set_map_state(&"Museum_S02_Loop")
	chapter_state.set_player_goal(&"explore_the_gallery")
	chapter_state.mark_story_event(&"s02_started")
	# Through the S01 door Graham arrives at this hall's entrance, on the left.
	player.position.x = 120.0
	objective_label.text = "继续探索美术馆"
	_show_dialogue("蓝湖：好暗……往里走走看。")
	_update_ui()
	queue_redraw()

func _try_s02_interact() -> void:
	if not s02_active or scene_state != "gallery" or transition_started or s02_completion_started:
		return
	var nearest := _get_nearest_s02_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	if object_name == "SecurityGuard":
		chapter_state.mark_event(&"s02_guard_observed")
		chapter_state.mark_event(&"s02_guard_directed_right")
		if s02_belt_stalled:
			_complete_s02_counterpart()
		elif s02_guard_asked:
			_show_dialogue("保安：出口在对面。\n他的手臂一直没有放下来过。")
		else:
			_show_dialogue("保安一动不动，长袖，戴着手套，手一直指着对面。\n保安：出口在对面。")
		s02_guard_asked = true
	else:
		_s02_describe(object_name)

## What the second hall's pieces say on E, in S02 and S03 (it depends on the light).
func _s02_describe(object_name: String) -> void:
	var lit := s03_eye_lit or s03_mirror_held
	if object_name == "HallDoor":
		if s01_exit_route == "future":
			_show_dialogue("我们进来时锈穿的那扇门。从里面看，门楣上写着“出口”。\n对面也有一扇门，也写着“出口”。")
		else:
			_show_dialogue("我们进来的门。从里面看，门楣上写着“出口”。\n对面也有一扇门，也写着“出口”。")
	elif object_name == "Narcissus":
		if lit:
			_show_dialogue("《那喀索斯》：画框下沿的水是真的。画灯一照，少年终于看见了水里的自己。\n对面同样的位置挂着另一幅：跪在水边的是一具骷髅。")
		else:
			_show_dialogue("《那喀索斯》：太暗了，只看得清少年低着头。\n画框下沿有什么在微微晃动……是水？")
	elif object_name == "PictureLamp":
		_show_dialogue("画框上伸出一盏画灯，没有亮。")
	elif object_name == "SculptureLight":
		if lit:
			_show_dialogue("《光》：两束光从左右射进倒三角的棱镜，在下面交叉。\n暖的落到右边，冷的落到左边。")
		else:
			_show_dialogue("《光》：一块倒三角的棱镜悬在半空。\n没有光，它只是一块玻璃。")
	elif object_name == "SculptureVenus":
		if s03_mirror_held:
			_show_dialogue("《机械维纳斯》：她托着一面镜子，用光的眼睛看着里面。")
		elif lit:
			_show_dialogue("《机械维纳斯》：没有手臂。光在她眼睛的位置交汇。\n左半身是大理石，右半身是锈。")
		else:
			_show_dialogue("《机械维纳斯》：黑暗里只看得出轮廓：没有手臂，也没有眼睛。\n格雷汉：……有点像阿姨。")

## In the dark the far figure strikes the guard's exact pose, like a reflection without Graham in it.
func _complete_s02_counterpart() -> void:
	if s02_completion_started:
		return
	s02_completion_started = true
	chapter_state.mark_event(&"s02_counterpart_noticed")
	_show_dialogue("保安：出口在对面。\n格雷汉望向对面：那边也站着一个人影，和你一个姿势。……可是镜子里没有我。")
	await get_tree().create_timer(2.6).timeout
	_show_dialogue("蓝湖：那不是镜子。\n这里的空间有问题。")
	await get_tree().create_timer(2.6).timeout
	chapter_state.mark_event(&"s02_space_loop_recognized")
	chapter_state.learn(&"s02_space_has_a_problem")
	chapter_state.set_player_goal(&"understand_the_space")
	chapter_state.complete_slice(ChapterState.Slice.S02_LOST)
	objective_label.text = "这里的空间有问题。"
	_update_ui()
	_enter_s03_after_s02()

## How hard the belt pulls Graham back toward the entrance at this x (pixels per second, leftward).
func _s02_belt_pull(x: float) -> float:
	if x <= S02_BELT_START:
		return 0.0
	var t := clampf((x - S02_BELT_START) / (S02_BELT_FULL - S02_BELT_START), 0.0, 1.0)
	return maxf(player.speed * pow(t, 2.2), S02_BELT_MIN_DRIFT)

func _update_s02(delta: float) -> void:
	if not player:
		return
	var in_hall := (s02_active or (s03_active and not s03_crossed)) and scene_state == "gallery" and not transition_started
	if not in_hall:
		if not s02_active and not s03_active:
			player.push_x = 0.0
		elif s03_crossed:
			player.push_x = 0.0
		return
	var x := player.position.x
	player.push_x = 0.0 if (s02_completion_started and s02_active) else -_s02_belt_pull(x)
	var moving := Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO
	if s02_active:
		# Walking right gets slower and slower; at the axis the floor runs back exactly as fast.
		if not s02_belt_stalled and x >= S02_STALL_X and Input.is_action_pressed("move_right"):
			s02_belt_stalled = true
			chapter_state.mark_event(&"s02_belt_stalled")
			objective_label.text = "出口在对面……可是过不去。"
			_show_dialogue("格雷汉：……我明明在往前走。\n脚下的地面在往回走。")
		if s02_belt_stalled and not s02_carried_back and x <= S02_BELT_START + 12.0 and not Input.is_action_pressed("move_left"):
			s02_carried_back = true
			chapter_state.mark_event(&"s02_carried_back")
			if not s02_completion_started:
				_show_dialogue("格雷汉：它把我送回来了。")
	# Easter egg: stand still on the 表 side and Blue Lake's figure develops at the mirrored spot.
	if moving or s03_pov_active:
		s02_idle_time = 0.0
	else:
		s02_idle_time += delta
	if s03_ride_active:
		return
	var target := 1.0 if s02_idle_time >= S02_FIGURE_AFTER and x < S02_AXIS_X - 20.0 and not s03_mirror_held else 0.0
	var rate := 0.35 if target > s02_figure_alpha else 3.0
	s02_figure_alpha = move_toward(s02_figure_alpha, target, delta * rate)
	if s02_figure_alpha > 0.6:
		chapter_state.mark_event(&"s02_blue_lake_figure_seen")

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
	if not s03_active or scene_state != "gallery" or transition_started or s03_busy:
		return
	if s03_ride_active:
		_s03_ride_interact()
		return
	var nearest := _get_nearest_s03_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	if object_name == "PictureLamp":
		_s03_use_picture_lamp()
	elif object_name == "SculptureVenus" and ((s03_left_arm_ready and not s03_left_installed) or (s03_right_arm_ready and not s03_right_installed)):
		_s03_install_arms()
	elif object_name == "SecurityGuard":
		if s03_left_installed:
			_show_dialogue("保安揉着肩膀：……我都忘了自己为什么举着它。")
		elif s03_left_arm_ready:
			_show_dialogue("保安捧着那条手臂，等你把它装回去。")
		elif s03_hands_seen and not blue_lake_active:
			_s03_guard_brings_arm()
		else:
			_show_dialogue("保安一动不动，手一直指着对面。\n保安：出口在对面。")
	elif object_name == "HallDoor":
		if s03_mirror_held and not s03_crossed:
			_s03_cross_by_reflection()
		else:
			_s02_describe("HallDoor")
	else:
		_s02_describe(object_name)
	queue_redraw()

## Where the picture lamp's light lands on the painted water for each of its angles.
func _s03_water_hit(angle: int) -> Vector2:
	return Vector2(S03_WATER_HITS[angle], S03_WATER_Y)

## The reflected ray off the water (angle of incidence = angle of reflection), clipped to the ceiling.
func _s03_reflection_end(angle: int) -> Vector2:
	var p := _s03_water_hit(angle)
	var d := Vector2(p.x - S03_PICTURE_LAMP.x, -(S03_WATER_Y - S03_PICTURE_LAMP.y))
	var to_prism := (S02_LIGHT_TOP + 2.0 - p.y) / d.y
	var at_prism := p + d * to_prism
	if absf(at_prism.x - S02_AXIS_X) <= S02_LIGHT_HALF:
		return at_prism
	return p + d * ((142.0 - p.y) / d.y)

func _s03_use_picture_lamp() -> void:
	if s03_eye_lit:
		_show_dialogue("画灯照着水面。少年一直看着水里的自己。")
		return
	if not s03_lamp_fixed:
		s03_lamp_fixed = true
		s03_lamp_angle = 0
		chapter_state.mark_event(&"s03_picture_lamp_fixed")
		_show_dialogue("画灯的灯泡松了。格雷汉顺手把它拧紧。\n灯亮了。画框下沿的水面反出一道光——打在墙上。")
		objective_label.text = "调整画灯的角度"
		return
	s03_lamp_angle = (s03_lamp_angle + 1) % S03_WATER_HITS.size()
	var end := _s03_reflection_end(s03_lamp_angle)
	if s03_lamp_angle == S03_LAMP_GOOD:
		_s03_light_the_eye()
	elif end.y <= 143.0:
		_show_dialogue("格雷汉把画灯扳了一格。\n反射的光打到了天花板上。")
	else:
		_show_dialogue("格雷汉把画灯扳了一格。")

func _s03_light_the_eye() -> void:
	s03_eye_lit = true
	s03_busy = true
	chapter_state.mark_event(&"s03_venus_eye_lit")
	_show_dialogue("水面亮了。少年第一次看见了水里的自己。\n反射的光射进棱镜——对面那幅画也亮了。两束光在棱镜里交叉，落在维纳斯的眼睛上。")
	await get_tree().create_timer(2.8).timeout
	s03_busy = false
	objective_label.text = "借维纳斯的眼睛"
	_show_dialogue("蓝湖：……她看得见了。\n按 Space，让我借她的眼睛看看。")
	_show_space_prompt()

func _s03_cross_by_reflection() -> void:
	var reflected_x := _s02_mx(player.position.x)
	if absf(reflected_x - (_s02_mx(S02_DOOR_RECT.get_center().x))) > 30.0:
		_show_dialogue("镜子里，你的倒影还没有站到对面那扇门前。")
		return
	s03_crossed = true
	s03_busy = true
	player.input_locked = true
	chapter_state.mark_event(&"s03_crossed_by_reflection")
	_show_dialogue("格雷汉推开门。\n镜子里，她推开的是对面那扇门。")
	await get_tree().create_timer(1.6).timeout
	player.position.x = reflected_x
	player.input_locked = false
	s03_busy = false
	objective_label.text = "从对面那扇门出去"
	_show_dialogue("蓝湖：出口在对面。他一直没说错。")

func _try_toggle_s03_blue_lake() -> void:
	if s03_busy:
		return
	if not s03_eye_lit:
		_show_dialogue("蓝湖：太暗了，我也看不清。先找到光。")
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("蓝湖：看。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	if not blue_lake_active and s03_pov_active:
		_s03_end_pov()
	_show_dialogue("蓝湖：" + ("把粉笔移到维纳斯的眼睛上，点左键。" if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _try_s03_chalk_interaction() -> void:
	if s03_pov_active:
		_s03_advance_pov()
		return
	if chalk_hover_target != "VenusEye":
		return
	s03_pov_active = true
	s03_pov_line = -1
	s03_pov_timer = 0.0
	player.input_locked = true
	player.visible = false          # inside her view Graham is the small figure far below
	chapter_state.mark_event(&"s03_venus_pov_borrowed")
	_s03_advance_pov()

func _s03_advance_pov() -> void:
	s03_pov_line += 1
	s03_pov_timer = 0.0
	if s03_pov_line >= S03_POV_LINES.size():
		_show_dialogue("蓝湖：……那个保安举着的，是她的手。另一只，在对面那盆树里。\n按 Space 收起蓝湖。")
		return
	if s03_pov_line == 1:
		s03_hands_seen = true
		chapter_state.mark_event(&"s03_hands_seen")
		_s03_update_objective()
	_show_dialogue(S03_POV_LINES[s03_pov_line])

func _s03_end_pov() -> void:
	s03_pov_active = false
	player.input_locked = false
	player.visible = true
	queue_redraw()

## E the guard once Venus's view has shown whose hand he holds: the glove comes off, he tells his story,
## and for the first time in years he walks — to Venus, holding her marble arm out for Graham to fit.
func _s03_guard_brings_arm() -> void:
	s03_busy = true
	player.input_locked = true
	s03_glove_off = true
	chapter_state.mark_event(&"s03_glove_removed")
	_show_dialogue("格雷汉：那不是你的手吧？\n她帮保安摘下手套。手套里是大理石。")
	await get_tree().create_timer(2.8).timeout
	_show_dialogue("保安：开幕那天，她的手臂断了。馆长说，看好展品。\n……我就一直举着。")
	await get_tree().create_timer(2.8).timeout
	_show_dialogue("保安第一次走动。")
	s03_guard_walking = true
	while s03_guard_x < S03_GUARD_AT_VENUS:
		await get_tree().process_frame
		s03_guard_x = minf(s03_guard_x + get_process_delta_time() * 140.0, S03_GUARD_AT_VENUS)
	s03_guard_walking = false
	s03_left_arm_ready = true
	chapter_state.mark_event(&"s03_marble_arm_brought")
	_show_dialogue("保安把手臂递到维纳斯身旁，等着。\n格雷汉：我来装。")
	_s03_update_objective()
	player.input_locked = false
	s03_busy = false

## Graham fits whichever arms have reached the middle. Both in place: Venus raises the mirror.
func _s03_install_arms() -> void:
	var fitted := ""
	if s03_left_arm_ready and not s03_left_installed:
		s03_left_installed = true
		chapter_state.mark_event(&"s03_marble_arm_installed")
		fitted += "格雷汉把大理石手臂接回维纳斯大理石的那一侧。"
	if s03_right_arm_ready and not s03_right_installed:
		s03_right_installed = true
		chapter_state.mark_event(&"s03_iron_arm_installed")
		if fitted != "":
			fitted += "\n"
		fitted += "她越过中线伸出手——指尖碰到镜子，凉的——把锈铁手臂接回锈的那一侧。"
	if s03_left_installed and s03_right_installed:
		s03_arms_returned = true
		chapter_state.mark_event(&"s03_arms_returned")
		_s03_mirror_appears(fitted)
	else:
		_show_dialogue(fitted + "\n" + ("另一只还在对面。" if s03_left_installed else "还差保安举着的那一只。"))
		_s03_update_objective()

func _s03_mirror_appears(fitted: String) -> void:
	s03_busy = true
	player.input_locked = true
	_show_dialogue(fitted)
	await get_tree().create_timer(2.8).timeout
	s03_mirror_held = true
	chapter_state.mark_event(&"s03_mirror_held")
	chapter_state.learn(&"s03_visual_is_not_reality")
	_show_dialogue("维纳斯托起了一面镜子。\n那面看不见的镜子，一直在等她的手。")
	await get_tree().create_timer(2.8).timeout
	_show_dialogue("蓝湖：镜子里有你。\n……对面那扇门，你的倒影够得着吗？")
	objective_label.text = "让镜子里的你站到对面那扇门前"
	player.input_locked = false
	s03_busy = false

func _s03_update_objective() -> void:
	if s03_mirror_held:
		return
	var need: Array[String] = []
	if not s03_left_arm_ready:
		need.append("保安举着的那只")
	if not s03_right_arm_ready:
		need.append("对面那盆树里的那只")
	if need.is_empty():
		objective_label.text = "在维纳斯身边装上手臂"
	else:
		objective_label.text = "把手臂带回维纳斯身边：" + "、".join(need)

## Things on the 里 side that Blue Lake can reach while the belt carries it (x, radius).
func _s03_ride_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = [
		{"name":"FarDoorTag", "x":_s02_mx(S02_DOOR_RECT.get_center().x), "radius":34.0},
		{"name":"SkeletonPainting", "x":_s02_mx(330.0), "radius":45.0}
	]
	if not s03_pot_on_belt:
		items.append({"name":"BonsaiPot", "x":s03_pot_x, "radius":40.0})
	return items

func _s03_nearest_ride_item() -> Dictionary:
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in _s03_ride_items():
		var d := absf(s03_ride_x - float(item.x))
		if d < float(item.radius) and d < best:
			best = d
			nearest = item
	return nearest

func _s03_ride_interact() -> void:
	var item := _s03_nearest_ride_item()
	if item.is_empty():
		return
	var n: String = item.name
	if n == "FarDoorTag":
		chapter_state.mark_event(&"s03_graham_tag_read")
		_show_dialogue("蓝湖：门把手上挂着一张资产标签。\n“No.0779 修理工 格雷汉·斯蒂尔”。")
	elif n == "SkeletonPainting":
		_show_dialogue("蓝湖：骷髅也在看水。\n它的水里映着的，是那个少年。")
	elif n == "BonsaiPot":
		s03_pot_on_belt = true
		chapter_state.mark_event(&"s03_bonsai_pushed")
		_show_dialogue("蓝湖用力一推，那盆树滑上了传送带。\n锈铁叶子沙沙作响，和它一起往中间去。")

func _s03_start_ride() -> void:
	s03_ride_active = true
	s03_ride_x = _s02_mx(player.position.x)
	s02_figure_alpha = 1.0
	player.input_locked = true
	chapter_state.mark_event(&"s03_blue_lake_ride")
	_show_dialogue("蓝湖：……我在对面。\n传送带推着我往中间走。经过什么的时候，按 E。")

func _s03_end_ride() -> void:
	s03_ride_active = false
	s02_figure_alpha = 0.0
	s02_idle_time = 0.0
	player.input_locked = false
	if s03_pot_on_belt:
		s03_ride_done = true
		_show_dialogue("蓝湖：我只能走到这里。门那边，我出不去。\n剩下的，交给你。")
	else:
		_show_dialogue("蓝湖：……那盆树过去了。\n再让我站到门口试一次。")

func _update_s03(delta: float) -> void:
	if not s03_active:
		return
	if s03_pov_active:
		s03_pov_timer += delta
		if s03_pov_timer >= 3.0 and s03_pov_line < S03_POV_LINES.size():
			_s03_advance_pov()
	# Standing at the entrance puts the reflection — Blue Lake — at the far door. Once Graham knows
	# whose arm the bonsai holds, the belt carries Blue Lake through the 里 side toward the middle.
	if not s03_ride_active and not s03_ride_done and s03_hands_seen and not s03_mirror_held and not s03_busy \
			and not blue_lake_active and s02_figure_alpha >= 0.95 \
			and absf(_s02_mx(player.position.x) - _s02_mx(S02_DOOR_RECT.get_center().x)) <= 30.0:
		_s03_start_ride()
	if s03_ride_active:
		s03_ride_x -= S03_RIDE_SPEED * delta
		if s03_ride_x <= S02_AXIS_X + 24.0:
			_s03_end_ride()
	if s03_pot_on_belt and s03_pot_x > S03_POT_STOP:
		s03_pot_x = maxf(s03_pot_x - S03_RIDE_SPEED * delta, S03_POT_STOP)
		if s03_pot_x <= S03_POT_STOP and not s03_leaves_fallen:
			# Stopped by the chain, in the warm light from Venus's eye: the rust leaves let go.
			s03_leaves_fallen = true
			s03_right_arm_ready = true
			chapter_state.mark_event(&"s03_rust_leaves_fallen")
			_s03_update_objective()
			if not s03_ride_active:
				_show_dialogue("暖光照在锈铁叶子上。叶子一片片落下，铁丝松开了。\n锈铁手臂露了出来。")

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
	# Through the 里 door of the second hall Graham steps in at the left wall, walking right.
	player.position.x = 100.0
	chapter_state.advance_to(ChapterState.Slice.S04_VISITOR)
	chapter_state.set_map_state(&"Museum_S04_Visitor")
	chapter_state.set_player_goal(&"recognize_the_visitor")
	chapter_state.mark_story_event(&"s04_started")
	objective_label.text = "观察参观者"
	_show_dialogue("Blue Lake：你刚才相信了一个眼睛看不到的东西。")
	_update_ui()
	queue_redraw()

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
	# S03: after trading places with her reflection, Graham leaves by the far (里) door on the right.
	if s03_active and s03_crossed and player.position.x >= 1005.0:
		chapter_state.mark_event(&"s03_exit_far_door")
		chapter_state.complete_slice(ChapterState.Slice.S03_MIRROR)
		_enter_s04_after_s03()

func _enter_s03_after_s02() -> void:
	if s03_active:
		return
	s02_active = false
	s03_active = true
	s03_busy = false
	s03_lamp_fixed = false
	s03_lamp_angle = 0
	s03_eye_lit = false
	s03_pov_active = false
	s03_hands_seen = false
	s03_glove_off = false
	s03_guard_x = S02_GUARD_X
	s03_arms_returned = false
	s03_mirror_held = false
	s03_crossed = false
	s03_ride_active = false
	s03_ride_done = false
	s03_pot_x = S03_POT_START
	s03_pot_on_belt = false
	s03_leaves_fallen = false
	s03_left_arm_ready = false
	s03_right_arm_ready = false
	s03_left_installed = false
	s03_right_installed = false
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	chapter_state.advance_to(ChapterState.Slice.S03_MIRROR)
	chapter_state.set_map_state(&"Museum_S03_Mirror")
	chapter_state.set_player_goal(&"find_the_light")
	chapter_state.mark_story_event(&"s03_started")
	objective_label.text = "找到光"
	_show_dialogue("蓝湖：太暗了，什么都看不清。\n……先找到光。")
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
		if item.name == "SecurityGuard":
			item["position"] = Vector2(s03_guard_x, item.position.y)
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
	if s03_active and s03_ride_active:
		var ride_item := _s03_nearest_ride_item()
		if ride_item.is_empty():
			interaction_hint_label.hide()
		else:
			interaction_hint_label.text = "E 推" if ride_item.name == "BonsaiPot" else "E 看"
			interaction_hint_label.position = Vector2(s03_ride_x - 20.0, 398.0)
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
	if s03_active:
		var n3: String = nearest.get("name", "")
		if n3 == "PictureLamp" and not s03_eye_lit:
			interaction_hint_label.text = "E 调角度" if s03_lamp_fixed else "E 修灯"
		elif n3 == "SecurityGuard" and s03_hands_seen and not s03_glove_off:
			interaction_hint_label.text = "E 那不是你的手吧"
		elif n3 == "SculptureVenus" and ((s03_left_arm_ready and not s03_left_installed) or (s03_right_arm_ready and not s03_right_installed)):
			interaction_hint_label.text = "E 装上手臂"
		elif n3 == "HallDoor" and s03_mirror_held and not s03_crossed:
			interaction_hint_label.text = "E 推门"
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
		if s03_eye_lit and not s03_pov_active and mouse_position.distance_to(S02_EYE) <= 30.0:
			chalk_hover_target = "VenusEye"
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
