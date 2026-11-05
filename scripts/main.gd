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
const S02_BELT_START := 560.0                  # the carpet is still up to just right of the axis (lamp, paintings, 《光》 and Venus all usable)
const S02_BELT_FULL := 690.0
const S02_BELT_MIN_DRIFT := 45.0
const S02_DOOR_RECT := Rect2(92, 270, 52, 102)
const S02_GUARD_X := 190.0
const S02_NARCISSUS_RECT := Rect2(280, 215, 100, 96)
const S02_LIGHT_TOP := 170.0                   # the inverted prism's base (top edge)
const S02_LIGHT_HALF := 35.0
const S02_LIGHT_APEX_Y := 192.0
const S02_EYE := Vector2(552, 229)             # where the crossed beams meet: Venus's missing eyes
const S02_STALL_X := 650.0
const S02_FIGURE_AFTER := 2.5                  # seconds standing still before Blue Lake's figure shows
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

# S04 "整间展厅是一只眼睛": 《窗》 is the pupil and the room's only light. Blue Lake (Space + Chalk)
# draws its curtain through three preset windows, like a radiologist switching window width/level:
#   cone = 全开: narrow window, high level — bright, saturated, everything holds still (the restorer's layer)
#   mid  = 半掩: dusk — both layers at half; the only light in which peripheral vision and the restorer both work
#   rod  = 全合: wide window, low level — flat grey, dim, and everything that moves shows (the visitors' layer)
const S04_PRESETS := ["cone", "mid", "rod"]
const S04_PRESET_T := {"cone": 0.0, "mid": 0.5, "rod": 1.0}
const S04_PRESET_NAMES := {"cone": "全开 · 亮", "mid": "半掩 · 黄昏", "rod": "全合 · 暗"}
const S04_PRESET_WL := {"cone": "窗宽 80 / 窗位 60", "mid": "窗宽 400 / 窗位 40", "rod": "窗宽 1500 / 窗位 -100"}
const S04_STARRY_CENTER := Vector2(350, 265)
# The signal in 《星空下的神经》, in the order it flows; Blue Lake traces it with the Chalk.
const S04_SIGNAL_NODES := [Vector2(312, 300), Vector2(335, 250), Vector2(365, 285), Vector2(388, 232)]
const S04_RESTORER_X := 455.0
# The restorer faces 《星空下的神经》: she only sees what is right in front of her, here.
const S04_RESTORER_FRONT := 410.0
const S04_BENCH_X := 510.0
const S04_GIRL_FRAME_X := 760.0
const S04_GIRL_MIN_X := 290.0
const S04_GIRL_MAX_X := 830.0
const S04_GIRL_SPEED := 42.0
const S04_GIRL_PAUSE := 2.5          # she lingers in front of the restorer each time she passes
const S04_CATCH_RANGE := 30.0
const S04_VISITOR_XS := [170.0, 945.0, 990.0]
const S04_TWINS_X := 880.0
const S04_LINE_TIME := 3.6
# 《窗》 hangs on the wall here in S04 and S05 (same room, same painting).
const S05_WINDOW_CENTER := Vector2(590, 285)
# S05–S08 sensor hall behind 《窗》, with depth. One-point perspective:
# z = 0 at the near floor edge, z = 1 at the far wall; things shrink toward the vanishing point.
const S05_NEAR_Y := 520.0
const S05_FAR_Y := 300.0
const S05_FAR_SCALE := 0.5
const S05_VP := Vector2(560, 80)
# The mural on the far wall has depth too: Graham comes out of the red house's door and walks down
# the painted road onto the floor. These are screen values, matching _draw_s05_mural().
const S05_MURAL_CX := 556.0
const S05_MURAL_HORIZON := 203.0
const S05_PAINT_TOP_Y := 208.0     # the house's doorstep
const S05_PAINT_SCALE := 0.12      # Graham's size at the doorstep
const S05_RACK_X := 800.0          # the eye-chart rack (empty C-shaped shelves), standing in the room
const S05_RACK_Z := 0.72
const S05_RAIL_X := 800.0          # the old lens slides along a rail from the eyepiece toward the rack
const S05_RAIL_Z0 := 0.12
const S05_RAIL_STEP := 0.11
const S05_RAIL_NOTCHES := 5
const S05_CLEAN_NOTCH := 4         # the cleaner's floor ("清洁区", marked): what is put there, he cleans
const S05_FOCUS_NOTCH := 1         # where the lens brings the rack's last row into focus
# The cleaner never moves: his ladder leans flat against the mural. He has Alice in Wonderland
# syndrome, and in this museum it shows on him: the nearer Graham stands, the bigger he looks;
# the farther, the smaller. Only from the footprints on the floor is he his normal size.
const S05_CLEANER_X := 1000.0
const S05_CLEANER_Z := 0.97
const S05_CLEANER_NORMAL := Vector2(0.28, 0.44)   # distance (in z) where he is normal size
const S05_FOOTPRINTS_Z := 0.61
const S05_LAST_ROW_GAPS := [1, 3, 0, 2]   # Landolt C gaps: 0 right, 1 down, 2 left, 3 up; the fifth case is fogged
# S06: the heap's shadow on the mural. Each piece sits in one of three slots (-1, 0, 1); its shadow
# lands on its mark on the mural only in the right slot: eyes in the house's windows (two per window),
# head on the door, body on the road, legs on the grass either side.
const S06_PILE_X := 470.0
const S06_PILE_Z := 0.62
const S06_PIECES := ["body", "head", "legs_l", "legs_r", "eyes"]
const S06_PIECE_CORRECT := {"body": 0, "head": 1, "legs_l": -1, "legs_r": 1, "eyes": 1}
const S06_PIECE_START := {"body": 1, "head": -1, "legs_l": 1, "legs_r": -1, "eyes": 0}
const S06_PIECE_NAMES := {"body": "一只大眼球", "head": "一只镜头盒", "legs_l": "一把折叠支架", "legs_r": "另一把折叠支架", "eyes": "一串小透镜"}
const S06_PIECE_FLOOR := {"body": Vector2(-24, 18), "head": Vector2(4, 34), "legs_l": Vector2(-50, 8), "legs_r": Vector2(30, 8), "eyes": Vector2(-6, 50)}
const S06_SLOT_STEP := 26.0        # on the floor
const S06_SHADOW_SLOT := 70.0      # on the mural
# S07: the red house's windows (0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right) are rooms.
const S07_WINDOW_ROOMS := ["s01", "s02", "s04", "hall"]
const S07_ROOM_NAMES := {"s01": "入口大厅", "s02": "表与里展厅", "s04": "画作展厅", "hall": "这间展厅"}
const S07_WINDOW_NAMES := ["左上", "右上", "左下", "右下"]
# The four empty plinths; each one belongs to a window of the red house.
const S07_PLINTHS := {"s01": Vector2(250, 0.40), "s02": Vector2(430, 0.30), "s04": Vector2(1000, 0.30), "hall": Vector2(620, 0.45)}
# S08: the guard chases but never catches up; the view closes in like an iris as Graham runs.
const S08_GUARD_SPEED := 150.0
const S08_GUARD_REACH := 70.0
const S08_RUN_TOTAL := 1100.0      # pixels of running until the circle closes

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
var s04_window := "cone"             # current preset of the curtain on 《窗》
var s04_win_t := 0.0                 # 0 = cone .. 1 = rod, eased toward the preset
var s04_window_seen := false
var s04_restorer_met := false
var s04_signal_progress := 0
var s04_signal_traced := false
var s04_starry_repaired := false
var s04_has_riboflavin := false
var s04_riboflavin_applied := false
var s04_girl_out := false            # 《戴珍珠耳机的少女》 has stepped out of her frame
var s04_girl_x := 760.0
var s04_girl_dir := -1.0
var s04_girl_pause := 0.0
var s04_girl_paused_here := false
var s04_girl_frozen := false         # caught by the bright window somewhere nobody was looking
var s04_girl_caught := false         # frozen right in front of the restorer
var s04_uv_on := false
var s04_visitors_recognized := false
var s04_handle_found := false
var s04_frame_installed := false
var s04_finish_pending := false
var s04_lines: Array = []            # queued dialogue lines (advance by time or E)
var s04_line_timer := 0.0
var s04_interactables: Array[Dictionary] = []
var s05_active := false
var s05_room := "window"           # "window": still in front of 《窗》 in the S04 room; "hall": behind it
var s05_window_observed := false
var s05_window_open := false
var s05_enter_anim := -1.0         # 0..1 while the painting's landscape grows into the hall
var s05_stepped_out := false       # Graham has walked out of the mural onto the floor
var s05_labeled := false           # the cleaner tagged Graham as a small exhibit, from afar
var s05_cleaner_met := false
var s05_lens_notch := 2
var s05_lens_clean := false
var s05_view := ""                 # "" / "lens" / "card" / "house": looking through or at something
var s05_cell_seen := false
var s05_finish_pending := false
var s05_lines: Array = []
var s05_line_timer := 0.0
var s05_interactables: Array[Dictionary] = []
var s05_hall_items: Array[Dictionary] = []
var s06_active := false
var s06_lamp_on := false
var s06_has_card := false          # the cleaner's catalogue card for the fifth case (the silhouette)
var s06_pieces := {}               # piece -> slot (-1, 0, 1)
var s06_shadow_done := false
var s06_case_clean := false
var s06_sensor_revealed := false
var s06_finish_pending := false
var s07_active := false
var s07_room := "hall"             # "hall", or a revisited room: "s01", "s02", "s04"
var s07_found := {}                # room -> Graham found its hidden thing
var s07_shelved := {}              # room -> the cleaner has numbered it and put it on its plinth
var s07_travel_anim := -1.0
var s07_travel_to := ""
var s07_hesitated := false
var s07_achievement_time := -1.0
var s07_room_items: Array[Dictionary] = []
var s08_active := false
var s08_stolen := false
var s08_guard := Vector2.ZERO      # screen position
var s08_run := 0.0                 # how far Graham has run
var s08_black_time := -1.0
var s08_exit_started := false
var theater_reveal := -1.0         # black, then the spotlight, then the stage
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
	_update_s04(delta)
	_update_hall(delta)
	_update_route_transitions()
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
	# S03 happens in the same hall as S02; the dead-end mirror is now the puzzle.
	# S03 happens in the same 表与里 hall as S02, with the same pieces.
	s03_interactables = s02_interactables.duplicate(true)
	s04_interactables = [
		# Left to right. The restorer is reached only from right in front of her (between her and the painting).
		{"name":"Visitor", "position":Vector2(170,440), "radius":40.0, "hint_y":258.0},
		{"name":"StarryNerves", "position":Vector2(S04_STARRY_CENTER.x,440), "radius":38.0, "hint_y":376.0},
		{"name":"Restorer", "position":Vector2(S04_RESTORER_FRONT,440), "radius":16.0, "hint_y":258.0},
		{"name":"RestorerSide", "position":Vector2(S04_RESTORER_X + 7.0,440), "radius":14.0, "hint_y":258.0},
		{"name":"Workbench", "position":Vector2(S04_BENCH_X,440), "radius":22.0, "hint_y":398.0},
		{"name":"Window", "position":Vector2(590,440), "radius":30.0, "hint_y":376.0},
		{"name":"PearlHeadphones", "position":Vector2(S04_GIRL_FRAME_X,440), "radius":40.0, "hint_y":376.0},
		{"name":"SculptureTwins", "position":Vector2(S04_TWINS_X,440), "radius":28.0, "hint_y":398.0},
		{"name":"VisitorGroup", "position":Vector2(968,440), "radius":45.0, "hint_y":258.0}
	]
	s05_interactables = [
		{"name":"Window", "position":Vector2(590,440), "radius":60.0, "hint_y":376.0}
	]
	# S05 hall, in depth: x is the near-plane x, z the depth (0 near .. 1 far wall); r is the reach at z = 0.
	# S05–S08 hall, in depth: x is the near-plane x, z the depth (0 near .. 1 far wall); r is the reach at z = 0.
	s05_hall_items = [
		{"name":"Eyepiece", "x":S05_RAIL_X, "z":0.02, "r":40.0, "dz":0.07, "draw":true},
		{"name":"Lens", "x":S05_RAIL_X, "z":0.34, "r":60.0, "dz":0.2, "draw":true},
		{"name":"Pile", "x":470.0, "z":0.62, "r":60.0, "dz":0.12, "draw":true},
		{"name":"Lamp", "x":340.0, "z":0.66, "r":30.0, "draw":true},
		{"name":"Rack", "x":S05_RACK_X, "z":S05_RACK_Z, "r":70.0, "dz":0.12, "draw":true},
		{"name":"Cleaner", "x":S05_CLEANER_X, "z":S05_CLEANER_Z, "r":60.0, "dz":1.0, "column":true, "draw":true},
		{"name":"Bucket", "x":940.0, "z":0.95, "r":24.0, "draw":true},
		{"name":"Mural", "x":560.0, "z":0.98, "r":300.0, "dz":0.06}
	]
	for plinth_room in S07_PLINTHS:
		var pl: Vector2 = S07_PLINTHS[plinth_room]
		s05_hall_items.append({"name":"Plinth_" + plinth_room, "x":pl.x, "z":pl.y, "r":40.0, "draw":true})
	# S07: one new hidden thing in each revisited room.
	s07_room_items = [
		{"name":"MapSticker", "room":"s01", "position":Vector2(310,440), "radius":45.0, "hint_y":376.0},
		{"name":"BlueFish", "room":"s02", "position":Vector2(330,440), "radius":50.0, "hint_y":376.0},
		{"name":"GirlDrawing", "room":"s04", "position":Vector2(S04_GIRL_FRAME_X,440), "radius":40.0, "hint_y":376.0}
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
		_draw_s06_hall()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S07_ENABLED and s07_active:
		_draw_s07_gallery()
	if not LEGACY_PROTOTYPE_FLOW_ENABLED and S08_ENABLED and s08_active:
		_draw_s05_hall()
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
	# Outside the museum: the red house (the same house as the mural behind 《窗》), photographed
	# from the street. Its door and the hook beside it are the door and hook of this hall.
	var sky: Color = [Color("#c9d8c6"), Color("#dde6ea"), Color("#7d8284")][s01_era]
	var wall: Color = [Color("#b0503a"), Color("#a2685c"), Color("#6e5650")][s01_era]
	draw_rect(inner, sky, true)
	var facade := Rect2(inner.position + Vector2(22, 16), Vector2(80, inner.size.y - 16))
	draw_rect(facade, wall, true)
	draw_colored_polygon(PackedVector2Array([facade.position + Vector2(-6, 0), Vector2(facade.end.x + 6, facade.position.y), Vector2(facade.get_center().x, inner.position.y + 2)]), wall.darkened(0.35))
	for wpos in [Vector2(6, 10), Vector2(60, 10)]:
		draw_rect(Rect2(facade.position + wpos, Vector2(12, 11)), Color("#f4e7b8").lerp(tone, 0.4), true)
	if s01_era == 1:
		draw_colored_polygon(PackedVector2Array([facade.position + Vector2(-6, 0), Vector2(facade.end.x + 6, facade.position.y), Vector2(facade.end.x - 4, facade.position.y - 4), facade.position + Vector2(4, -4)]), Color("#f4f6f8"))
	# The photographed door is this hall's door: the same door, the same hook.
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
		draw_string(ThemeDB.fallback_font, inner.position + Vector2(4, 12), "OPENING", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.35, 0.2, 0.1, 0.8))
		# Cutting the ribbon in front of the red house.
		draw_line(Vector2(inner.position.x + 8, door.position.y + 20), Vector2(inner.end.x - 8, door.position.y + 20), Color("#d8202a"), 2.0)
		draw_circle(Vector2(door.get_center().x, door.position.y + 20), 3.0, Color("#d8202a"))
		# Blue Lake was already here, years ago, in another form: a small girl with blue eyes in the crowd.
		_draw_s01_blue_lake_trace(Vector2(inner.position.x + 43.0, floor_y - 9.0), 0)
	elif s01_era == 1:
		# Winter: snow falling, coats, and someone up a ladder fixing the lamp over the door.
		for i in range(10):
			draw_circle(inner.position + Vector2(4 + (i * 13) % int(inner.size.x - 8), 3 + (i * 7) % int(inner.size.y - 10)), 1.1, Color.WHITE)
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


func _draw_s04_gallery() -> void:
	# Left to right: entrance door, a visitor in the dark edge, 《星空下的神经》, the restorer facing it,
	# her workbench, 《窗》 (the pupil, the only light), 《戴珍珠耳机的少女》, 《双生》, more visitors.
	var t := s04_win_t
	var cone_a := _s04_cone_alpha()
	var rod_a := _s04_rod_alpha()
	var now := Time.get_ticks_msec() * 0.001
	# The room: light pours from the middle; the edges stay dark (that is where the rods live).
	draw_rect(Rect2(84, 140, 936, 368), Color(0.03, 0.05, 0.09, 0.12 + 0.42 * t), true)
	draw_rect(Rect2(84, 140, 190, 368), Color(0.02, 0.03, 0.06, 0.30 * (1.0 - t)), true)
	draw_rect(Rect2(840, 140, 180, 368), Color(0.02, 0.03, 0.06, 0.30 * (1.0 - t)), true)
	draw_colored_polygon(PackedVector2Array([Vector2(548, 335), Vector2(632, 335), Vector2(720, 508), Vector2(460, 508)]), Color(1.0, 0.93, 0.72, 0.14 * (1.0 - t)))
	draw_string(ThemeDB.fallback_font, Vector2(100, 175), "画作展厅", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, _s04_c(Color("#b8c7d4")))
	# The door Graham came through is on the left wall.
	draw_rect(Rect2(62, 262, 22, 110), _s04_c(Color("#4b2c1d")), true)
	_draw_s04_window()
	_draw_s04_starry(now)
	_draw_s04_restorer(cone_a)
	_draw_s04_bench()
	_draw_s04_girl_painting(t)
	_draw_s04_twins(cone_a, rod_a)
	for i in range(S04_VISITOR_XS.size()):
		_draw_s04_visitor(S04_VISITOR_XS[i], i, rod_a, now)
	draw_string(ThemeDB.fallback_font, Vector2(150, 278), "参观者", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.88, 0.92, maxf(rod_a, 0.35)))
	draw_string(ThemeDB.fallback_font, Vector2(935, 278), "参观者们", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.88, 0.92, maxf(rod_a, 0.35)))
	if s04_girl_out:
		_draw_s04_girl_walking(s04_girl_x, rod_a)
	if s04_uv_on:
		# Ultraviolet: the riboflavin she painted with glows yellow-green wherever she has been.
		draw_rect(Rect2(84, 140, 936, 368), Color(0.42, 0.22, 0.9, 0.10), true)
		if s04_girl_caught:
			var x := S04_GIRL_MIN_X + 20.0
			while x < S04_GIRL_MAX_X:
				draw_circle(Vector2(x, 474), 3.0, Color(0.78, 1.0, 0.35, 0.55))
				x += 46.0
	if s04_active and player and s04_riboflavin_applied and s04_uv_on:
		draw_circle(Vector2(player.position.x, player.position.y - 4.0), 27.0, Color(0.78, 1.0, 0.35, 0.28))
		draw_arc(Vector2(player.position.x, player.position.y - 4.0), 27.0, 0.0, TAU, 28, Color(0.85, 1.0, 0.5, 0.75), 2.0)

## Window/level, applied to a colour: cone keeps it saturated and bright; rod maps it through a
## wide window at a low level (flat, dim, blue-grey). The room lerps between the two.
func _s04_c(c: Color) -> Color:
	var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var sat := 1.35
	var cone := Color(clampf((lum + (c.r - lum) * sat) * 1.08, 0.0, 1.0), clampf((lum + (c.g - lum) * sat) * 1.08, 0.0, 1.0), clampf((lum + (c.b - lum) * sat) * 1.08, 0.0, 1.0), c.a)
	var level := 0.42
	var width := 1.2
	var g := clampf((lum - (level - width * 0.5)) / width, 0.0, 1.0)
	var rod := Color(g * 0.46, g * 0.52, g * 0.60, c.a)
	return cone.lerp(rod, s04_win_t)

func _s04_cone_alpha() -> float:
	return clampf(1.5 - 2.0 * s04_win_t, 0.0, 1.0)

func _s04_rod_alpha() -> float:
	return clampf(2.0 * s04_win_t - 0.5, 0.0, 1.0)

func _draw_s04_window() -> void:
	var w := S05_WINDOW_CENTER
	var lit := 1.0 - s04_win_t
	# The painting glows: it is the room's light source.
	draw_circle(w, 70.0, Color(1.0, 0.92, 0.7, 0.10 + 0.10 * lit))
	if s04_frame_installed:
		draw_rect(Rect2(w.x - 53.0, w.y - 58.0, 106, 116), _s04_c(Color("#c7a56f")), false, 8.0)
	# Bare canvas: the frame was taken off for restoration.
	# Inside the painting: only a window — sky and grass. The house is seen from the other side.
	_draw_s05_window_view(Rect2(w.x - 45.0, w.y - 50.0, 90, 100))
	draw_rect(Rect2(w.x - 45.0, w.y - 50.0, 90, 100), Color(1.0, 0.9, 0.62, 0.25).lerp(Color(0.2, 0.25, 0.35, 0.45), s04_win_t), true)
	draw_line(Vector2(w.x, w.y - 50.0), Vector2(w.x, w.y + 50.0), _s04_c(Color("#8a6a4a")), 3.0)
	draw_line(Vector2(w.x - 45.0, w.y - 5.0), Vector2(w.x + 45.0, w.y - 5.0), _s04_c(Color("#8a6a4a")), 3.0)
	# The curtain: open at the sides (cone), half drawn (mid), closed (rod).
	var cover: float = 0.14 + 0.86 * s04_win_t
	var half: float = 45.0 * cover
	var curtain := _s04_c(Color("#8a3b3b"))
	draw_rect(Rect2(w.x - 45.0, w.y - 50.0, half, 100), curtain, true)
	draw_rect(Rect2(w.x + 45.0 - half, w.y - 50.0, half, 100), curtain, true)
	draw_line(Vector2(w.x - 47.0, w.y - 52.0), Vector2(w.x + 47.0, w.y - 52.0), _s04_c(Color("#5b4636")), 3.0)
	if s04_handle_found:
		draw_rect(Rect2(w.x + 30.0, w.y - 9.0, 6, 18), Color("#f6e5a7"), true)
	elif s04_uv_on:
		# The patch she painted over glows; the handle shows through as a dark shape.
		draw_rect(Rect2(w.x + 24.0, w.y - 14.0, 18, 28), Color(0.78, 1.0, 0.35, 0.75), true)
		draw_rect(Rect2(w.x + 30.0, w.y - 9.0, 6, 18), Color(0.2, 0.3, 0.15, 0.8), true)
	if s04_uv_on:
		# The blind spot: in the middle of the pupil, where nobody looks, a blue handprint
		# (Blue Lake's colour). Only ultraviolet shows it.
		var bp := w + Vector2(-4, -22)
		var blue := Color(0.0, 0.47, 0.84, 0.85)
		draw_circle(bp + Vector2(0, 6), 8.0, blue)
		for k in range(4):
			draw_line(bp + Vector2(-6 + k * 4.0, 0), bp + Vector2(-8 + k * 5.0, -11 + absf(k - 1.5) * 2.0), blue, 3.0)
		draw_line(bp + Vector2(7, 6), bp + Vector2(13, 0), blue, 3.0)
	if s04_uv_on and s04_girl_caught:
		# A small handprint, pressed onto the glass.
		draw_circle(w + Vector2(-18, 18), 6.0, Color(0.78, 1.0, 0.35, 0.6))
		for k in range(4):
			draw_line(w + Vector2(-23 + k * 3.5, 13), w + Vector2(-25 + k * 4.0, 5), Color(0.78, 1.0, 0.35, 0.6), 2.0)
	if not s05_active:
		draw_string(ThemeDB.fallback_font, Vector2(570, 362), "《窗》", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))
	if s04_active and s04_window_seen:
		draw_string(ThemeDB.fallback_font, Vector2(w.x - 62.0, 220), S04_PRESET_NAMES[s04_window] + "   " + S04_PRESET_WL[s04_window], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#bfe8ff") if blue_lake_active else Color("#9fb0bf"))
	if s04_active and blue_lake_active:
		var glow := 0.85 if chalk_hover_target == "S04Window" else 0.4
		draw_arc(w, 64.0, 0.0, TAU, 32, Color(0.75, 0.91, 1.0, glow), 2.0)

## How clearly Graham can see the signal in 《星空下的神经》: it needs the rods (dusk or dark)
## and it vanishes when she looks straight at it.
func _s04_signal_alpha() -> float:
	if s04_starry_repaired:
		return 1.0
	if not player:
		return 0.0
	var rods := clampf((s04_win_t - 0.25) / 0.25, 0.0, 1.0)
	var aside := clampf((absf(player.position.x - S04_STARRY_CENTER.x) - 25.0) / 40.0, 0.0, 1.0)
	return rods * aside

func _draw_s04_starry(now: float) -> void:
	var c := S04_STARRY_CENTER
	draw_rect(Rect2(c.x - 50.0, c.y - 50.0, 100, 100), _s04_c(Color("#b49464")), true)
	draw_rect(Rect2(c.x - 42.0, c.y - 42.0, 84, 84), _s04_c(Color("#2c3a5a")), true)
	draw_arc(c, 26.0, 0.0, 5.2, 24, _s04_c(Color("#c8c1a8")), 3.0)
	draw_arc(c, 13.0, 1.0, 6.0, 18, _s04_c(Color("#c8c1a8")), 2.0)
	draw_circle(c + Vector2(-28, -26), 3.0, _s04_c(Color("#f2e2a0")))
	draw_circle(c + Vector2(30, 24), 2.5, _s04_c(Color("#f2e2a0")))
	draw_string(ThemeDB.fallback_font, Vector2(c.x - 45.0, 352), "《星空下的神经》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	var a := _s04_signal_alpha()
	if a > 0.0:
		var pts := PackedVector2Array(S04_SIGNAL_NODES)
		draw_polyline(pts, Color(0.62, 0.92, 1.0, 0.35 * a), 2.0)
		# A pulse runs along the fibre, always in the same direction.
		var seg_count := pts.size() - 1
		var f := fmod(now * 0.6, 1.0) * seg_count
		var i := mini(int(f), seg_count - 1)
		draw_circle(pts[i].lerp(pts[i + 1], f - i), 4.0, Color(0.75, 0.97, 1.0, 0.9 * a))
		if blue_lake_active and not s04_signal_traced:
			for k in range(pts.size()):
				var hover := chalk_hover_target == "Signal%d" % k
				draw_arc(pts[k], 8.0, 0.0, TAU, 16, Color(0.75, 0.91, 1.0, (0.9 if hover else 0.45) * a), 2.0)
	for k in range(s04_signal_progress - 1):
		draw_line(S04_SIGNAL_NODES[k], S04_SIGNAL_NODES[k + 1], Color("#dff5ff"), 3.0)
	if s04_signal_progress >= 1:
		draw_circle(S04_SIGNAL_NODES[0], 3.0, Color("#dff5ff"))

func _draw_s04_restorer(cone_a: float) -> void:
	# A cone: short, pointed hat, three colour bands (blue / green / red), a magnifier. She faces left.
	var a := maxf(cone_a, 0.22)
	var x := S04_RESTORER_X
	draw_colored_polygon(PackedVector2Array([Vector2(x - 14, 312), Vector2(x + 14, 312), Vector2(x, 282)]), _s04_c(Color(0.85, 0.75, 0.55, a)))
	draw_circle(Vector2(x, 322), 13.0, _s04_c(Color(0.8, 0.66, 0.54, a)))
	draw_circle(Vector2(x - 6, 320), 2.2, Color(0.15, 0.15, 0.2, a))
	draw_rect(Rect2(x - 16, 335, 32, 14), _s04_c(Color(0.25, 0.45, 0.85, a)), true)
	draw_rect(Rect2(x - 16, 349, 32, 14), _s04_c(Color(0.3, 0.7, 0.4, a)), true)
	draw_rect(Rect2(x - 16, 363, 32, 14), _s04_c(Color(0.85, 0.3, 0.3, a)), true)
	draw_line(Vector2(x - 16, 345), Vector2(x - 34, 318), _s04_c(Color(0.75, 0.8, 0.85, a)), 3.0)
	draw_arc(Vector2(x - 37, 313), 6.0, 0.0, TAU, 14, _s04_c(Color(0.75, 0.9, 1.0, a)), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(x - 20, 276), "修复师", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.91, 0.87, 0.78, maxf(cone_a, 0.35)))

func _draw_s04_bench() -> void:
	var x := S04_BENCH_X
	draw_rect(Rect2(x - 22, 344, 44, 28), _s04_c(Color("#665d50")), true)
	draw_rect(Rect2(x - 26, 338, 52, 7), _s04_c(Color("#8a7a62")), true)
	# Ultraviolet lamp: a violet tube on the bench.
	draw_rect(Rect2(x - 14, 328, 28, 6), Color(0.6, 0.35, 1.0, 0.95) if s04_uv_on else _s04_c(Color("#5c5470")), true)
	if s04_uv_on:
		draw_circle(Vector2(x, 331), 18.0, Color(0.55, 0.3, 1.0, 0.25))
	if s04_has_riboflavin and not s04_riboflavin_applied:
		draw_rect(Rect2(x + 10, 326, 7, 12), _s04_c(Color("#e8c832")), true)
	if not s04_frame_installed:
		# The empty frame of 《窗》, leaning against the bench.
		draw_rect(Rect2(x - 44, 312, 22, 60), _s04_c(Color("#c7a56f")), false, 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(x - 20, 392), "工作台", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))

func _draw_s04_girl_painting(t: float) -> void:
	var x := S04_GIRL_FRAME_X
	draw_rect(Rect2(x - 45, 225, 90, 90), _s04_c(Color("#b49464")), true)
	draw_rect(Rect2(x - 38, 232, 76, 76), _s04_c(Color("#20242c")), true)
	if not s04_girl_out:
		var dusk := clampf(1.0 - absf(t - 0.5) * 4.0, 0.0, 1.0)   # strongest at the dusk window
		draw_rect(Rect2(x - 14, 280, 28, 28), _s04_c(Color("#d9b23a")), true)
		draw_circle(Vector2(x, 266), 14.0, _s04_c(Color("#e2c3a3")))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 16, 262), Vector2(x - 6, 246), Vector2(x + 12, 250), Vector2(x + 4, 262)]), _s04_c(Color("#2f5fb8")))
		# Purkinje shift: at dusk the red lips go dark and the blue earphone lights up; her eyes turn blue.
		draw_circle(Vector2(x + 3, 274), 2.5, _s04_c(Color("#c0303a")).lerp(Color(0.12, 0.1, 0.12), dusk))
		draw_circle(Vector2(x + 13, 268), 4.5, _s04_c(Color("#eeeadc")).lerp(Color(0.4, 0.75, 1.0), dusk))
		var eye := _s04_c(Color("#3a2a20")).lerp(Color(0.25, 0.55, 1.0), dusk)
		draw_circle(Vector2(x - 4, 264), 1.8, eye)
		draw_circle(Vector2(x + 5, 264), 1.8, eye)
		if s04_uv_on and s04_girl_caught:
			draw_line(Vector2(x - 4, 267), Vector2(x - 5, 278), Color(0.78, 1.0, 0.35, 0.8), 1.5)
			draw_line(Vector2(x + 5, 267), Vector2(x + 6, 278), Color(0.78, 1.0, 0.35, 0.8), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(x - 44, 352), "《戴珍珠耳机的少女》", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))

func _draw_s04_girl_walking(x: float, rod_a: float) -> void:
	# Out of her frame: a small grey shadow that moves (rod layer); when the bright window
	# catches her she holds still, in full colour (cone layer).
	var a := 1.0 if s04_girl_frozen else maxf(rod_a, 0.0)
	if a <= 0.01:
		return
	var bob := 0.0 if s04_girl_frozen else sin(Time.get_ticks_msec() * 0.012) * 1.5
	draw_rect(Rect2(x - 8, 442 + bob, 16, 26), _s04_c(Color(0.85, 0.7, 0.23, a)), true)
	draw_circle(Vector2(x, 434 + bob), 8.0, _s04_c(Color(0.89, 0.76, 0.64, a)))
	draw_colored_polygon(PackedVector2Array([Vector2(x - 9, 432 + bob), Vector2(x - 3, 423 + bob), Vector2(x + 7, 425 + bob), Vector2(x + 3, 432 + bob)]), _s04_c(Color(0.18, 0.37, 0.72, a)))
	draw_circle(Vector2(x + 7, 436 + bob), 2.5, _s04_c(Color(0.93, 0.92, 0.86, a)))

func _draw_s04_twins(cone_a: float, rod_a: float) -> void:
	# 《双生》: two heads back to back. The restorer's half lives in the bright layer, the visitor's in the dark.
	var x := S04_TWINS_X
	draw_rect(Rect2(x - 20, 326, 40, 46), _s04_c(Color("#4b5966")), true)
	draw_circle(Vector2(x - 10, 304), 12.0, Color(0.85, 0.62, 0.45, cone_a))
	draw_arc(Vector2(x - 10, 304), 12.0, 0.0, TAU, 20, Color(0.25, 0.2, 0.15, cone_a), 2.0)
	draw_circle(Vector2(x + 10, 304), 12.0, Color(0.55, 0.6, 0.68, rod_a))
	if s04_uv_on:
		draw_line(Vector2(x - 16, 362), Vector2(x - 4, 358), Color(0.78, 1.0, 0.35, 0.8), 1.5)
		draw_line(Vector2(x + 4, 360), Vector2(x + 16, 364), Color(0.78, 1.0, 0.35, 0.8), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(x - 18, 392), "《双生》", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))

func _draw_s04_visitor(x: float, index: int, rod_a: float, now: float) -> void:
	# A rod: tall, thin, a head like a stack of discs, grey-blue, face blurred. Only movement shows to them.
	var a := maxf(rod_a, 0.28)
	var sway := sin(now * 1.3 + index * 1.7) * 2.0 * rod_a
	var look := 0.0
	if player and rod_a > 0.5 and absf(player.velocity.x) > 30.0:
		look = signf(player.position.x - x) * 3.0
	var col := Color(0.49, 0.56, 0.64, a)
	draw_rect(Rect2(x - 9 + sway, 318, 18, 82), col, true)
	for k in range(4):
		draw_rect(Rect2(x - 11 + sway + look * 0.5, 296 + k * 5.5, 22, 4), Color(0.6, 0.66, 0.74, a), true)
	draw_circle(Vector2(x + sway + look, 310), 7.0, Color(0.7, 0.74, 0.8, a * 0.35))

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
		_show_dialogue("Blue Lake：把粉笔移到《窗》上，点一下，拉窗帘。")
	elif s05_active:
		_show_dialogue("Blue Lake：现在，把粉笔移到《窗》上（哪里都行），点左键。")
	elif s06_active:
		_show_dialogue("Blue Lake：" + _s06_chalk_hint())
	elif s07_active:
		_show_dialogue("Blue Lake：" + ("用粉笔点红房子的一扇窗。" if s07_room == "hall" else "用粉笔点那扇“窗”，回展厅去。"))
	else:
		_show_dialogue("Blue Lake 已经变成粉笔。")
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
		return "照片回到了真正的开幕日。大家站在一座红房子门前剪彩，人很多。\n一位保安正把一串钥匙挂到门边的钩子上。人群里还有一位拿着画笔的修复师，和一位一直盯着画看的参观者。"
	if s01_era == 1:
		var first := "" if chapter_state.has_story_event(&"s01_saw_self_in_photo") else "\n门口梯子上修灯的那个人……是我？那年冬天，我在这里修过灯。"
		chapter_state.mark_story_event(&"s01_saw_self_in_photo")
		return "《美术馆开幕日》。照片里是美术馆的正门，一座红房子。那扇门、门边的钩子，和这里一模一样。我们就是从照片里进来的。\n……可照片里在下雪。" + first
	return "多年以后。照片里的红房子褪了色，门口空了，到处是灰。\n门边的钩子上什么也没有。"

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
		_show_dialogue("门锁着。门边的钩子是空的。\nBlue Lake：照片里的门和这扇一模一样……照片里的钥匙呢？")
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
	elif object_name == "SculptureVenus" and s03_eye_lit and not s03_mirror_held:
		if s03_hands_seen:
			_show_dialogue("《机械维纳斯》：没有手臂。光在她眼睛的位置交汇。\n蓝湖：按 Space，可以再借她的眼睛看一次。")
		else:
			_show_dialogue("《机械维纳斯》：光在她眼睛的位置交汇。\n蓝湖：按 Space，借她的眼睛看看。")
		_show_space_prompt()
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
	objective_label.text = "借维纳斯的眼睛（Space）"
	_show_dialogue("水面亮了。反射的光射进棱镜，两束光交叉，落在维纳斯的眼睛上。\n蓝湖：……她看得见了。按 Space，让我借她的眼睛看看。")
	_show_space_prompt()
	await get_tree().create_timer(0.6).timeout
	s03_busy = false

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

func _try_toggle_s04_blue_lake() -> void:
	if not s04_window_seen:
		_show_dialogue("Blue Lake：先看看那幅会发光的画。")
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("Blue Lake：让我来拉窗帘。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_hide_space_prompt()
	_show_dialogue("Blue Lake：" + ("把粉笔移到《窗》上，点一下，拉窗帘。" if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _update_s04(delta: float) -> void:
	if not s04_active:
		return
	s04_win_t = move_toward(s04_win_t, S04_PRESET_T[s04_window], delta * 2.2)
	if s04_line_timer > 0.0:
		s04_line_timer -= delta
		if s04_line_timer <= 0.0:
			if not s04_lines.is_empty():
				_s04_next_line()
			elif s04_finish_pending:
				_s04_finish()
				return
	# 《戴珍珠耳机的少女》 goes out once the restorer is hunting for her, and only while it is not bright.
	if s04_starry_repaired and not s04_girl_caught:
		if not s04_girl_out and s04_window == "rod":
			s04_girl_out = true
			s04_girl_x = S04_GIRL_FRAME_X
			s04_girl_dir = -1.0
			chapter_state.mark_event(&"s04_girl_left_frame")
		if s04_girl_out and s04_window != "cone":
			s04_girl_frozen = false
			_s04_walk_girl(delta)
	if not s04_visitors_recognized and s04_win_t > 0.9 and s04_uv_on and s04_riboflavin_applied and player and absf(player.velocity.x) > 30.0:
		for vx in S04_VISITOR_XS:
			if absf(player.position.x - vx) < 70.0:
				_s04_recognized()
				break

func _s04_walk_girl(delta: float) -> void:
	if s04_girl_pause > 0.0:
		s04_girl_pause -= delta
		return
	s04_girl_x += s04_girl_dir * S04_GIRL_SPEED * delta
	if s04_girl_x <= S04_GIRL_MIN_X:
		s04_girl_x = S04_GIRL_MIN_X
		s04_girl_dir = 1.0
	elif s04_girl_x >= S04_GIRL_MAX_X:
		s04_girl_x = S04_GIRL_MAX_X
		s04_girl_dir = -1.0
	var near_front := absf(s04_girl_x - S04_RESTORER_FRONT) < 4.0
	if near_front and not s04_girl_paused_here:
		s04_girl_paused_here = true
		s04_girl_pause = S04_GIRL_PAUSE
	elif absf(s04_girl_x - S04_RESTORER_FRONT) > 40.0:
		s04_girl_paused_here = false

func _s04_say(lines: Array) -> void:
	s04_lines = lines.slice(1)
	_show_dialogue(lines[0])
	s04_line_timer = S04_LINE_TIME

func _s04_next_line() -> void:
	if s04_lines.is_empty():
		return
	var line: String = s04_lines.pop_front()
	_show_dialogue(line)
	s04_line_timer = S04_LINE_TIME
	if s04_girl_caught and s04_girl_out and line.contains("跑回了画框"):
		s04_girl_out = false

func _s04_update_objective() -> void:
	if s04_girl_caught:
		var left: Array[String] = []
		if not s04_visitors_recognized:
			left.append("让参观者认出你")
		if not s04_handle_found:
			left.append("找到《窗》的把手")
		if not s04_frame_installed:
			left.append("把画框装回《窗》")
		objective_label.text = "、".join(left) if not left.is_empty() else "《窗》"
	elif s04_starry_repaired:
		objective_label.text = "抓住在画上乱涂的人（要让修复师看见）"
	elif s04_restorer_met:
		objective_label.text = "帮修复师看见画里的信号"
	elif s04_window_seen:
		objective_label.text = "用蓝湖拉《窗》的窗帘"
	else:
		objective_label.text = "这间屋子的光从哪里来？"

func _try_s04_interact() -> void:
	if not s04_active or scene_state != "gallery" or transition_started:
		return
	if not s04_lines.is_empty():
		_s04_next_line()
		return
	if s04_finish_pending:
		return
	var nearest := _get_nearest_s04_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	match object_name:
		"Visitor", "VisitorGroup":
			_s04_talk_to_visitors()
		"Restorer":
			_s04_talk_to_restorer()
		"RestorerSide":
			if s04_win_t > 0.75:
				_show_dialogue("（太暗了。修复师停下了手，什么也看不见。）")
			else:
				_show_dialogue("修复师盯着《星空下的神经》，没注意到你。\n她好像只看得见正前方。")
		"Workbench":
			_s04_use_bench()
		"Window":
			_s04_look_at_window()
		"StarryNerves":
			if s04_starry_repaired:
				_show_dialogue("《星空下的神经》：信号沿着神经纤维流过去，一刻不停。")
			elif s04_win_t < 0.25:
				_show_dialogue("《星空下的神经》：漩涡不是星云，是神经纤维。\n正对着看，它一动不动。")
			else:
				_show_dialogue("正对着看，什么也没有。\n……眼角好像有东西在动。")
		"PearlHeadphones":
			_s04_look_at_girl()
		"SculptureTwins":
			if s04_uv_on:
				_show_dialogue("紫外灯下，说明牌上显出两个签名。\n一个是修复师的笔迹，另一个……是参观者的。")
			elif s04_win_t < 0.25:
				_show_dialogue("《双生》：只看得见一个头，轮廓分明，颜色鲜艳。\n说明牌上写着：共同创作。")
			elif s04_win_t > 0.75:
				_show_dialogue("《双生》：只看得见一个头，灰色的，好像在微微转动。")
			else:
				_show_dialogue("《双生》：两个头背对着背，一个鲜艳，一个灰。\n第一次看全了。")
	_s04_update_objective()
	queue_redraw()

func _s04_talk_to_visitors() -> void:
	if s04_visitors_recognized:
		_show_dialogue("参观者们：修灯的人。\n那个小影子总在《窗》前面停一停。她在上面画了东西。")
	elif s04_win_t < 0.25:
		chapter_state.mark_event(&"s04_visitor_observed")
		_show_dialogue("参观者：（他缩在暗处，脸是糊的。）……太亮了。看不清。\n你是……修灯的人吗？")
	elif s04_win_t <= 0.75:
		if s04_starry_repaired:
			_show_dialogue("参观者：夜里有个小影子到处走。\n我们看得见她在动，可是从来看不清她。")
		else:
			_show_dialogue("参观者：那幅《星空》在动。\n我总是用眼角才看得到。")
	elif s04_riboflavin_applied and s04_uv_on:
		_show_dialogue("参观者：刚才那个发光的……停下来就不见了。\nBlue Lake：他们只看得见动的东西。从他们面前走过去。")
	else:
		_show_dialogue("参观者：刚才有人走过去……\n现在什么也没有了。")

func _s04_talk_to_restorer() -> void:
	if s04_win_t > 0.75:
		_show_dialogue("（太暗了。修复师停下了手，什么也看不见。）")
		return
	if not s04_restorer_met:
		s04_restorer_met = true
		chapter_state.mark_event(&"s04_restorer_observed")
		_s04_say([
			"修复师：……你站在我正前方，我才看得见你。",
			"修复师：这幅《星空下的神经》，画的是正在传导的信号。\n可我越盯着它看，它越不动。我修不下去。"
		])
	elif s04_signal_traced and not s04_starry_repaired:
		_s04_repair_starry()
	elif not s04_starry_repaired:
		_show_dialogue("修复师：信号往哪边走？我正着看，什么也看不见。")
	elif not s04_girl_caught:
		_show_dialogue("修复师：我只看得见正前方。\n把那个乱涂的人，带到我面前来。")
	else:
		_show_dialogue("修复师：紫外灯在工作台上。\n那只画框是《窗》的，装回去吧。")

func _s04_repair_starry() -> void:
	s04_starry_repaired = true
	s04_has_riboflavin = true
	chapter_state.mark_event(&"s04_starry_repaired")
	chapter_state.mark_event(&"s04_riboflavin_received")
	_s04_say([
		"修复师照着粉笔的线，一笔一笔补上去。\n……画里的信号流动起来了。",
		"修复师：谢谢。还有一件事。\n有人夜里在我修好的画上乱涂。",
		"修复师：这种黄颜料不该出现在任何一幅古画里。是核黄素。\n（她把一小瓶刮下来的黄颜料放在工作台上。）",
		"修复师：我只在亮处看得见，那个人只在我看不见的时候动。\n帮我抓住她。"
	])
	_s04_update_objective()

func _s04_use_bench() -> void:
	if s04_has_riboflavin and not s04_riboflavin_applied:
		s04_riboflavin_applied = true
		chapter_state.mark_event(&"s04_pigment_applied")
		_show_dialogue("格雷汉把一点核黄素抹在手背和袖口上。\n黄色的，不太显眼。")
	elif s04_girl_caught:
		s04_uv_on = not s04_uv_on
		if s04_uv_on:
			chapter_state.mark_event(&"s04_uv_on")
		_show_dialogue("紫外灯亮了。屋里有些东西开始发出黄绿色的光。" if s04_uv_on else "紫外灯关了。")
	elif s04_starry_repaired:
		_show_dialogue("工作台上有一盏紫外灯。\n修复师：先别动它。先把那个人找出来。")
	else:
		_show_dialogue("修复师的工作台：放大镜，三种颜色的笔，一盏紫外灯。\n桌边靠着一只空画框。")

func _s04_look_at_window() -> void:
	if not s04_window_seen:
		s04_window_seen = true
		chapter_state.mark_event(&"s04_window_observed")
		_show_dialogue("《窗》：整间屋子的光，都是从这幅画里照出来的。\n画上的窗帘……好像拉得动。Blue Lake：按 Space，让我来。")
		_show_space_prompt()
	elif s04_uv_on and s04_win_t >= 0.5 and not s04_handle_found:
		s04_handle_found = true
		chapter_state.mark_event(&"s04_window_handle_found")
		_show_dialogue("紫外灯下，《窗》边上一块黄颜料亮了起来。\n下面原本画着一个把手。是她涂掉的。")
		_s04_check_complete()
	elif s04_uv_on and not chapter_state.has_event(&"s04_blue_handprint_seen"):
		chapter_state.mark_event(&"s04_blue_handprint_seen")
		_show_dialogue("紫外灯下，《窗》的正中间有一个蓝色的手印。\n比少女的手大。……一直在那里，只是谁也没看见。")
	elif s04_girl_caught and not s04_frame_installed:
		s04_frame_installed = true
		chapter_state.mark_event(&"s04_window_frame_installed")
		_show_dialogue("格雷汉把旧画框装回《窗》上。尺寸刚好。\n这幅画第一次有了窗框。")
		_s04_check_complete()
	elif s04_girl_caught and not s04_handle_found:
		_show_dialogue("《窗》上看不出把手。\n（那个小影子在上面画过东西。）")
	else:
		_show_dialogue("《窗》：现在是「" + S04_PRESET_NAMES[s04_window] + "」。\nBlue Lake 可以拉它的窗帘。")

func _s04_look_at_girl() -> void:
	if s04_girl_out and not s04_girl_caught:
		if s04_girl_frozen:
			_show_dialogue("画框里是空的。\n她站在外面某处，一动不动，好像一直都站在那里。")
		else:
			_show_dialogue("画框里是空的。")
	elif s04_uv_on and s04_girl_caught:
		_show_dialogue("紫外灯下，她脸上有两道发亮的泪痕。")
	elif s04_win_t < 0.25:
		_show_dialogue("《戴珍珠耳机的少女》：很美。\n可是想不起她像谁。")
	elif s04_win_t <= 0.75:
		_show_dialogue("黄昏里，她的红嘴唇暗了下去，蓝色的耳机亮了起来。\n眼睛也是蓝的。……像另一个人。")
	else:
		_show_dialogue("灰色的。看不清她的脸。")

func _try_s04_chalk_interaction() -> void:
	if chalk_hover_target.begins_with("Signal"):
		var index := int(chalk_hover_target.substr(6))
		if index != s04_signal_progress:
			_show_dialogue("Blue Lake：不对，信号不是从这里开始的。\n顺着它流的方向描。")
			return
		s04_signal_progress += 1
		if s04_signal_progress < S04_SIGNAL_NODES.size():
			_show_dialogue("Blue Lake：……接着描。")
		else:
			s04_signal_traced = true
			chapter_state.mark_event(&"s04_signal_traced")
			if s04_window == "mid":
				_s04_repair_starry()
			else:
				_show_dialogue("Blue Lake：线描好了。\n可是太暗，修复师看不见。")
		queue_redraw()
		return
	if chalk_hover_target != "S04Window":
		return
	var next: String = S04_PRESETS[(S04_PRESETS.find(s04_window) + 1) % S04_PRESETS.size()]
	s04_window = next
	chapter_state.mark_event(StringName("s04_window_" + next))
	match next:
		"cone":
			_show_dialogue("Blue Lake：全开。亮的、鲜艳的、不动的。")
		"mid":
			_show_dialogue("Blue Lake：半掩。黄昏。两种东西都看得见一点。")
		"rod":
			_show_dialogue("Blue Lake：全合。灰的、暗的……可是有东西在动。")
	if next == "cone" and s04_girl_out and not s04_girl_caught:
		if absf(s04_girl_x - S04_RESTORER_FRONT) <= S04_CATCH_RANGE:
			_s04_catch_girl()
		else:
			s04_girl_frozen = true
			_show_dialogue("她停在了半路，一动不动。修复师背对着她，什么也没看见。\nBlue Lake：要在修复师的正前方停住她。")
	_s04_update_objective()
	queue_redraw()

func _s04_catch_girl() -> void:
	s04_girl_caught = true
	s04_girl_frozen = true
	chapter_state.mark_event(&"s04_girl_caught")
	_s04_say([
		"修复师抬起头。正前方，一个黄裙子、蓝头巾的小姑娘站在画框外面，一动不动。\n修复师：……是你。",
		"少女：被看见了。\n少女：好久没有人看我第二眼了。",
		"（她朝格雷汉身边看了一眼，好像那里站着谁。）\n少女：……你也在呀。好久不见。",
		"少女：《窗》的把手？我画掉了。\n谁想从这里走，得先找到我呀。",
		"（少女跑回了画框里。）\n修复师：她的颜料就是核黄素，紫外灯下会发光。紫外灯在工作台上。",
		"修复师：那只空画框是《窗》的。我卸下来修，一直没装回去。\n装回去吧。"
	])
	s04_girl_x = S04_RESTORER_FRONT - 6.0   # she stays where she was caught until she runs back
	_s04_update_objective()

func _s04_recognized() -> void:
	s04_visitors_recognized = true
	chapter_state.mark_event(&"s04_visitor_recognized_by_light")
	_s04_say([
		"参观者：是——\n参观者：那个——\n参观者：修灯的人。",
		"参观者们：那年冬天，你把灯修好了。\n我们一直在等，想再看你一次。",
		"（他们看不清你的脸。可他们记得你走路的样子。）\nBlue Lake：原来认出一个人，不一定要看见她的脸。",
		"参观者：那个小影子，总在《窗》前面停一停。\n她在上面画了东西。"
	])
	_s04_update_objective()
	_s04_check_complete()

func _s04_check_complete() -> void:
	if s04_finish_pending or not (s04_visitors_recognized and s04_handle_found and s04_frame_installed):
		return
	s04_finish_pending = true
	var closing := "Blue Lake：有窗框，有把手。\n……它现在不只是一幅画了。"
	if s04_lines.is_empty():
		_s04_say([closing])
	else:
		s04_lines.append(closing)

func _s04_finish() -> void:
	s04_finish_pending = false
	chapter_state.mark_event(&"s04_window_unblocked")
	chapter_state.learn(&"s04_seeing_is_not_objective")
	chapter_state.complete_slice(ChapterState.Slice.S04_VISITOR)
	objective_label.text = "调查《窗》"
	_enter_s05_after_s04()

## ===== The sensor hall (S05–S08) ===============================================================
## --- Depth helpers ----------------------------------------------------------------------------
func _s05_scale(z: float) -> float:
	return lerpf(1.0, S05_FAR_SCALE, clampf(z, 0.0, 1.0))

func _s05_y(z: float) -> float:
	return lerpf(S05_NEAR_Y, S05_FAR_Y, clampf(z, 0.0, 1.0))

## Screen x of something standing at near-plane x `x`, depth `z`.
func _s05_px(x: float, z: float) -> float:
	return S05_VP.x + (x - S05_VP.x) * _s05_scale(z)

## Screen point of a world point: near-plane x, height y (near-plane screen y), depth z.
func _s05_pt(x: float, y: float, z: float) -> Vector2:
	var s := _s05_scale(z)
	return Vector2(S05_VP.x + (x - S05_VP.x) * s, S05_VP.y + (y - S05_VP.y) * s)

## Graham's depth on the hall floor (0..1). Inside the mural she counts as standing at the wall.
func _s05_player_z() -> float:
	if not player:
		return 0.0
	return clampf((S05_NEAR_Y - player.position.y) / (S05_NEAR_Y - S05_FAR_Y), 0.0, 1.0)

func _s05_in_painting() -> bool:
	return player != null and player.position.y < S05_FAR_Y - 1.0

## 0 at the bottom edge of the mural, 1 at the red house's doorstep.
func _s05_paint_t() -> float:
	return clampf((S05_FAR_Y - player.position.y) / (S05_FAR_Y - S05_PAINT_TOP_Y), 0.0, 1.0)

func _s05_lens_z() -> float:
	return S05_RAIL_Z0 + S05_RAIL_STEP * s05_lens_notch

func _s05_set_depth_mode(on: bool) -> void:
	if not player:
		return
	if on:
		player.ground_top = S05_PAINT_TOP_Y
		player.ground_y = S05_NEAR_Y
	else:
		player.ground_top = 410.0
		player.ground_y = 520.0
		player.scale = Vector2.ONE

## How big the cleaner looks, as a factor on his normal size, from where Graham stands.
func _s05_cleaner_factor() -> float:
	var d := absf(S05_CLEANER_Z - _s05_player_z())
	if _s05_in_painting():
		d = 0.0
	var lo: float = S05_CLEANER_NORMAL.x
	var hi: float = S05_CLEANER_NORMAL.y
	if d < lo:
		return lerpf(5.0, 1.0, smoothstep(0.08, lo, d))
	if d > hi:
		return lerpf(1.0, 0.25, smoothstep(hi, 0.62, d))
	return 1.0

func _s05_cleaner_size() -> String:
	var f := _s05_cleaner_factor()
	if f > 1.15:
		return "giant"
	if f < 0.85:
		return "tiny"
	return "normal"

func _in_sensor_hall() -> bool:
	if scene_state != "gallery":
		return false
	return (s05_active and s05_room == "hall") or s06_active or s08_active or (s07_active and s07_room == "hall")

## --- Drawing ----------------------------------------------------------------------------------
func _draw_s05_gallery() -> void:
	if s05_room == "hall":
		_draw_s05_hall()
		return
	# Still in the 《窗》 room: the same painting, now with a frame and a handle.
	_draw_s04_gallery()
	var w := S05_WINDOW_CENTER
	if blue_lake_active and not s05_window_open:
		# The whole frame is the target; the handle pulses so it is clear what opens it.
		var hover := chalk_hover_target == "Window"
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		draw_rect(Rect2(w - Vector2(53, 58), Vector2(106, 116)).grow(6.0), Color(0.75, 0.91, 1.0, 0.95 if hover else 0.45), false, 3.0 if hover else 2.0)
		draw_circle(w + Vector2(33, 0), 10.0 + 4.0 * pulse, Color(0.75, 0.91, 1.0, 0.25 + 0.25 * pulse))
		draw_arc(w + Vector2(33, 0), 14.0, 0.0, TAU, 20, Color(0.75, 0.91, 1.0, 0.9), 2.0)
	elif not s05_window_open and s05_room == "window":
		# Before Blue Lake: the handle still catches the eye.
		draw_arc(w + Vector2(33, 0), 12.0 + 2.0 * sin(Time.get_ticks_msec() * 0.005), 0.0, TAU, 20, Color(0.96, 0.9, 0.65, 0.6), 1.5)
	if s05_enter_anim >= 0.0:
		# The view inside the frame grows until it is the room Graham stands in.
		var t := s05_enter_anim * s05_enter_anim
		var r := Rect2(w - Vector2(45, 50), Vector2(90, 100))
		var full := Rect2(0, 58, 1152, 590)
		var g := Rect2(r.position.lerp(full.position, t), r.size.lerp(full.size, t))
		_draw_s05_window_view(g)

## What 《窗》 shows from the gallery: just a window — sky above, grass below. No house.
func _draw_s05_window_view(r: Rect2) -> void:
	var horizon := r.position.y + r.size.y * 0.62
	draw_rect(Rect2(r.position, Vector2(r.size.x, horizon - r.position.y)), Color("#8fc3ea"), true)
	draw_rect(Rect2(Vector2(r.position.x, horizon), Vector2(r.size.x, r.end.y - horizon)), Color("#6aa84f"), true)

func _s05_mural_rect() -> Rect2:
	var far_l := _s05_px(84, 1.0)
	var far_r := _s05_px(1020, 1.0)
	var far_top := S05_VP.y + (58.0 - S05_VP.y) * S05_FAR_SCALE
	return Rect2(far_l, far_top, far_r - far_l, S05_FAR_Y - far_top)

## A window of the red house on the mural, in screen space.
func _s07_mural_window_rect(i: int) -> Rect2:
	var cx := S05_MURAL_CX
	var hw := 46.0
	var base := S05_MURAL_HORIZON + 4.0
	var wx := cx - hw + 10.0 + (i % 2) * (hw * 2.0 - 34.0)
	var wy := base - 54.0 + 8.0 + (i / 2) * 22.0
	return Rect2(wx, wy, 14, 14)

## The mural on the far wall: the picture you stare at when your eyes are measured. The red house is
## the museum; its windows are the rooms of chapter 1. The painted road runs into the floor.
func _draw_s05_mural(r: Rect2) -> void:
	var horizon := S05_MURAL_HORIZON
	draw_rect(Rect2(r.position, Vector2(r.size.x, horizon - r.position.y)), Color("#8fc3ea"), true)
	draw_rect(Rect2(Vector2(r.position.x, horizon), Vector2(r.size.x, r.end.y - horizon)), Color("#6aa84f"), true)
	draw_circle(Vector2(r.position.x + r.size.x * 0.12, r.position.y + 24), 12.0, Color("#f3e3a0"))
	var cx := S05_MURAL_CX
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 70, r.end.y), Vector2(cx + 70, r.end.y), Vector2(cx + 6, horizon), Vector2(cx - 6, horizon)]), Color("#c9b98d"))
	var hw := 46.0
	var hh := 54.0
	var base := horizon + 4.0
	draw_rect(Rect2(cx - hw, base - hh, hw * 2.0, hh), Color("#c2402f"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(cx - hw - 8, base - hh), Vector2(cx + hw + 8, base - hh), Vector2(cx, base - hh - 30)]), Color("#7a2a22"))
	for i in range(4):
		var w := _s07_mural_window_rect(i)
		var lit: bool = s07_shelved.get(S07_WINDOW_ROOMS[i], false)
		if lit:
			draw_rect(w.grow(3), Color(1.0, 0.95, 0.6, 0.5), true)
		draw_rect(w, Color("#fff6b0") if lit else Color("#f4e7b8"), true)
		draw_line(Vector2(w.position.x + 7, w.position.y), Vector2(w.position.x + 7, w.end.y), Color("#7a2a22"), 1.0)
		draw_line(Vector2(w.position.x, w.position.y + 7), Vector2(w.end.x, w.position.y + 7), Color("#7a2a22"), 1.0)
		if blue_lake_active and s07_active and s07_room == "hall":
			var hover := chalk_hover_target == "MuralWindow%d" % i
			draw_rect(w.grow(4), Color(0.75, 0.91, 1.0, 0.95 if hover else 0.5), false, 2.0)
	draw_rect(Rect2(cx - 7, base - 20, 14, 20), Color("#5a2a1c"), true)

func _draw_s05_hall() -> void:
	var m := _s05_mural_rect()
	var far_l := m.position.x
	var far_r := m.end.x
	var far_top := m.position.y
	# Room in one-point perspective: ceiling, side walls, floor, far wall.
	draw_rect(Rect2(0, 58, 1152, 590), Color("#151c28"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(84, 58), Vector2(1020, 58), Vector2(far_r, far_top), Vector2(far_l, far_top)]), Color("#1d2735"))
	draw_colored_polygon(PackedVector2Array([Vector2(84, 58), Vector2(far_l, far_top), Vector2(far_l, S05_FAR_Y), Vector2(84, S05_NEAR_Y)]), Color("#263243"))
	draw_colored_polygon(PackedVector2Array([Vector2(1020, 58), Vector2(far_r, far_top), Vector2(far_r, S05_FAR_Y), Vector2(1020, S05_NEAR_Y)]), Color("#263243"))
	draw_colored_polygon(PackedVector2Array([Vector2(84, S05_NEAR_Y), Vector2(1020, S05_NEAR_Y), Vector2(far_r, S05_FAR_Y), Vector2(far_l, S05_FAR_Y)]), Color("#2f3a48"))
	for i in range(1, 6):
		var z := float(i) / 6.0
		draw_line(Vector2(_s05_px(84, z), _s05_y(z)), Vector2(_s05_px(1020, z), _s05_y(z)), Color(1, 1, 1, 0.05), 1.0)
	_draw_s05_mural(m)
	# The painted road carries on across the floor, faintly: the painting and the room are one road.
	draw_colored_polygon(PackedVector2Array([Vector2(S05_MURAL_CX - 70, S05_FAR_Y), Vector2(S05_MURAL_CX + 70, S05_FAR_Y), Vector2(S05_MURAL_CX + 150, S05_FAR_Y + 40), Vector2(S05_MURAL_CX - 150, S05_FAR_Y + 40)]), Color(0.79, 0.73, 0.55, 0.18))
	if s06_lamp_on:
		_draw_s06_shadow()
	draw_string(ThemeDB.fallback_font, Vector2(100, 150), "视觉传感器 · 迭代展", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
	_draw_s05_rail()
	_draw_s05_footprints()
	var things: Array = []
	for item in s05_hall_items:
		if item.get("draw", false):
			things.append(item)
	things.sort_custom(func(a, b): return _s05_item_z(a) > _s05_item_z(b))
	for item in things:
		_draw_s05_item(item)
	_draw_s06_case()
	if s05_labeled and player:
		var s := player.scale.x
		draw_rect(Rect2(player.position.x + 8.0 * s, player.position.y + 2.0 * s, 12.0 * s, 7.0 * s), Color("#e8e2c8"), true)
	if s05_view != "":
		_draw_s05_view()
	if s07_achievement_time >= 0.0:
		var a := clampf(4.0 - s07_achievement_time, 0.0, 1.0)
		draw_rect(Rect2(396, 96, 360, 40), Color(0.1, 0.12, 0.18, 0.85 * a), true)
		draw_rect(Rect2(396, 96, 360, 40), Color(0.95, 0.85, 0.5, a), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(420, 123), "成就解锁 · 全部归档", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.92, 0.6, a))
	if s08_active:
		_draw_s08_chase()

func _draw_s05_rail() -> void:
	# From the eyepiece straight toward the rack, with a notch for every stop; the cleaner's floor is marked.
	var a := Vector2(_s05_px(S05_RAIL_X, 0.02), _s05_y(0.02))
	var b := Vector2(_s05_px(S05_RAIL_X, S05_RACK_Z - 0.06), _s05_y(S05_RACK_Z - 0.06))
	draw_line(a, b, Color(0.8, 0.7, 0.5, 0.6), 3.0)
	for i in range(S05_RAIL_NOTCHES):
		var z := S05_RAIL_Z0 + S05_RAIL_STEP * i
		var s := _s05_scale(z)
		var p := Vector2(_s05_px(S05_RAIL_X, z), _s05_y(z))
		draw_line(p - Vector2(10 * s, 0), p + Vector2(10 * s, 0), Color(0.85, 0.75, 0.55, 0.8), 2.0)
	var cz := S05_RAIL_Z0 + S05_RAIL_STEP * S05_CLEAN_NOTCH
	var zone := PackedVector2Array([
		_s05_pt(S05_RAIL_X - 70, S05_NEAR_Y, cz - 0.05), _s05_pt(S05_RAIL_X + 70, S05_NEAR_Y, cz - 0.05),
		_s05_pt(S05_RAIL_X + 70, S05_NEAR_Y, cz + 0.05), _s05_pt(S05_RAIL_X - 70, S05_NEAR_Y, cz + 0.05)])
	draw_colored_polygon(zone, Color(0.55, 0.8, 0.95, 0.10))
	draw_polyline(PackedVector2Array([zone[0], zone[1], zone[2], zone[3], zone[0]]), Color(0.75, 0.9, 1.0, 0.55), 1.5)
	draw_string(ThemeDB.fallback_font, zone[0] + Vector2(-34, 4), "清洁区", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#bfe8ff"))

func _draw_s05_footprints() -> void:
	# The one place from which the cleaner looks his normal size.
	var z := S05_FOOTPRINTS_Z
	var s := _s05_scale(z)
	var p := Vector2(_s05_px(S05_CLEANER_X, z), _s05_y(z))
	for k in range(2):
		var q := p + Vector2(-8 + k * 14, -2 + k * 3) * s
		draw_circle(q, 4.0 * s, Color(0.85, 0.82, 0.72, 0.5))
		draw_circle(q + Vector2(0, -7) * s, 2.5 * s, Color(0.85, 0.82, 0.72, 0.5))
	draw_string(ThemeDB.fallback_font, p + Vector2(-20, 18), "脚印", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.82, 0.72, 0.8))

func _draw_s05_c(center: Vector2, radius: float, gap: int, col: Color, width: float) -> void:
	# Landolt C: a ring with one gap.
	var gap_angle: float = [0.0, PI * 0.5, PI, PI * 1.5][gap]
	draw_arc(center, radius, gap_angle + 0.45, gap_angle + TAU - 0.45, 24, col, width)

func _draw_s05_rack() -> void:
	# The eye chart, built as a rack: every letter is a C-shaped shelf. The cleaner has emptied them all
	# to clean them, except the fogged case at the end of the last row (he cannot see it).
	var z := S05_RACK_Z
	var s := _s05_scale(z)
	var x := _s05_px(S05_RACK_X, z)
	var foot := _s05_y(z)
	draw_rect(Rect2(x - 70 * s, foot - 250 * s, 140 * s, 250 * s), Color("#3a4654"), true)
	draw_rect(Rect2(x - 70 * s, foot - 250 * s, 140 * s, 250 * s), Color("#566674"), false, 2.0)
	var rows := [[3], [0, 2], [1, 3, 0], [1, 3, 0, 2, -1]]
	var sizes := [28.0, 19.0, 13.0, 9.0]
	var y := foot - 222 * s
	for r in range(rows.size()):
		var n: int = rows[r].size()
		var step: float = sizes[r] * 2.6
		var x0: float = x - step * (n - 1) * 0.5 * s
		for i in range(n):
			var c := Vector2(x0 + i * step * s, y)
			if rows[r][i] >= 0:
				_draw_s05_c(c, sizes[r] * s, rows[r][i], Color("#cfc8b4"), maxf(sizes[r] * 0.3 * s, 1.5))
			elif not s06_case_clean:
				draw_rect(Rect2(c - Vector2(sizes[r], sizes[r]) * s, Vector2(sizes[r], sizes[r]) * 2.0 * s), Color(0.82, 0.84, 0.87, 0.75), true)
		y += (sizes[r] * 2.0 + 16.0) * s
	if s06_has_card and not s08_stolen:
		# The catalogue card for the fifth case, pinned to the rack.
		draw_rect(Rect2(x + 50 * s, foot - 40 * s, 22 * s, 16 * s), Color("#e8e2c8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(x - 26, foot - 258 * s), "视力表展架", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))

func _draw_s05_cleaner() -> void:
	# The ladder leans flat against the mural, the way it would against any wall.
	var s := _s05_scale(S05_CLEANER_Z)
	var x := _s05_px(S05_CLEANER_X, S05_CLEANER_Z)
	var foot := _s05_y(S05_CLEANER_Z)
	var top := Vector2(x + 10 * s, S05_MURAL_HORIZON - 30.0)
	draw_line(Vector2(x - 14 * s, foot), top + Vector2(-10 * s, 0), Color("#8a7a62"), 3.0 * s)
	draw_line(Vector2(x + 14 * s, foot), top + Vector2(10 * s, 0), Color("#8a7a62"), 3.0 * s)
	for k in range(6):
		var t := (k + 1) / 7.0
		var l := Vector2(x - 14 * s, foot).lerp(top + Vector2(-10 * s, 0), t)
		var rr := Vector2(x + 14 * s, foot).lerp(top + Vector2(10 * s, 0), t)
		draw_line(l, rr, Color("#8a7a62"), 2.0 * s)
	# He stands on the fourth rung; his size depends on where Graham is (Alice in Wonderland syndrome).
	var f := _s05_cleaner_factor()
	var cs := s * f
	var stand := Vector2(x, foot).lerp(top, 4.0 / 7.0)
	draw_rect(Rect2(stand.x - 9 * cs, stand.y - 30 * cs, 18 * cs, 30 * cs), Color("#5c7a6e"), true)
	draw_circle(Vector2(stand.x, stand.y - 38 * cs), 8.0 * cs, Color("#c9ad8e"))
	draw_line(Vector2(stand.x - 9 * cs, stand.y - 24 * cs), Vector2(stand.x - 26 * cs, stand.y - 40 * cs), Color("#5c7a6e"), maxf(3.0 * cs, 1.0))
	draw_rect(Rect2(stand.x - 32 * cs, stand.y - 46 * cs, 9 * cs, 7 * cs), Color("#e8e2c8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(stand.x - 18, stand.y - 54 * cs - 4), "清洁工", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))

func _draw_s05_item(item: Dictionary) -> void:
	var z := _s05_item_z(item)
	var s := _s05_scale(z)
	var x := _s05_px(S05_RAIL_X if item.name == "Lens" else float(item.x), z)
	var foot := _s05_y(z)
	var n := String(item.name)
	match n:
		"Rack":
			_draw_s05_rack()
		"Cleaner":
			_draw_s05_cleaner()
		"Bucket":
			draw_rect(Rect2(x - 8 * s, foot - 16 * s, 16 * s, 16 * s), Color("#6f7d88"), true)
			draw_line(Vector2(x - 6 * s, foot), Vector2(x - 20 * s, foot + 6 * s), Color(0.5, 0.75, 0.95, 0.6), 2.0)
		"Eyepiece":
			draw_line(Vector2(x, foot), Vector2(x, foot - 34 * s), Color("#b08d57"), 4.0 * s)
			draw_circle(Vector2(x, foot - 38 * s), 6.0 * s, Color("#d9b36a"))
			draw_string(ThemeDB.fallback_font, Vector2(x - 16, foot - 50 * s), "目镜", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
		"Lens":
			draw_line(Vector2(x, foot), Vector2(x, foot - 44 * s), Color("#8a7a62"), 4.0 * s)
			draw_circle(Vector2(x, foot - 58 * s), 15.0 * s, Color(0.85, 0.87, 0.9, 0.85) if not s05_lens_clean else Color(0.7, 0.88, 1.0, 0.35))
			draw_arc(Vector2(x, foot - 58 * s), 15.0 * s, 0.0, TAU, 24, Color("#b08d57"), 3.0 * s)
			draw_string(ThemeDB.fallback_font, Vector2(x - 20, foot - 80 * s), "老镜片", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
		"Pile":
			_draw_s06_pile()
		"Lamp":
			if s06_lamp_on:
				var heap := _s06_piece_floor_pos("body")
				draw_colored_polygon(PackedVector2Array([Vector2(x + 4 * s, foot - 108 * s), Vector2(heap.x + 40, heap.y - 40), Vector2(heap.x - 30, heap.y + 10)]), Color(1.0, 0.95, 0.75, 0.16))
			draw_line(Vector2(x, foot), Vector2(x, foot - 120 * s), Color("#8796a2"), 3.0 * s)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 12 * s, foot - 120 * s), Vector2(x + 12 * s, foot - 120 * s), Vector2(x + 20 * s, foot - 100 * s), Vector2(x - 4 * s, foot - 100 * s)]), Color("#d6c79f"))
			draw_string(ThemeDB.fallback_font, Vector2(x - 20, foot + 14), "落地灯", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))
		_:
			if n.begins_with("Plinth_"):
				var room := n.substr(7)
				draw_rect(Rect2(x - 22 * s, foot - 46 * s, 44 * s, 46 * s), Color("#3d4a5a"), true)
				draw_rect(Rect2(x - 26 * s, foot - 50 * s, 52 * s, 6 * s), Color("#566674"), true)
				if s07_shelved.get(room, false):
					_draw_s07_egg(room, Vector2(x, foot - 58 * s), s * 2.2)
				draw_string(ThemeDB.fallback_font, Vector2(x - 26, foot + 14), "展台 · " + S07_WINDOW_NAMES[S07_WINDOW_ROOMS.find(room)] + "窗", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))

## The four hidden things, white and blue (Blue Lake's colours), drawn at `at` with scale `k`.
func _draw_s07_egg(room: String, at: Vector2, k: float) -> void:
	var blue := Color("#2f86e0")
	match room:
		"s01":
			draw_circle(at, 5.0 * k, blue)
			draw_circle(at, 2.0 * k, Color("#f4f6f8"))
		"s02":
			draw_colored_polygon(PackedVector2Array([at + Vector2(-7, 0) * k, at + Vector2(2, -3) * k, at + Vector2(2, 3) * k]), Color("#f4f6f8"))
			draw_colored_polygon(PackedVector2Array([at + Vector2(2, 0) * k, at + Vector2(7, -3) * k, at + Vector2(7, 3) * k]), blue)
		"s04":
			draw_rect(Rect2(at - Vector2(7, 6) * k, Vector2(14, 12) * k), Color("#f4f6f8"), true)
			draw_line(at + Vector2(-4, 4) * k, at + Vector2(-2, -3) * k, blue, 1.2)
			draw_circle(at + Vector2(3, 0) * k, 2.5 * k, blue)
		"hall":
			draw_circle(at, 4.5 * k, Color("#f4f6f8"))
			for q in [Vector2(-1.5, -1.5), Vector2(1.5, -1.5), Vector2(-1.5, 1.5), Vector2(1.5, 1.5)]:
				draw_circle(at + q * k, 0.8 * k, blue)

func _draw_s05_view() -> void:
	# Looking through or at something: a round view in the middle of the screen.
	var c := Vector2(576, 300)
	draw_circle(c, 156.0, Color(0, 0, 0, 0.85))
	draw_circle(c, 150.0, Color("#3a4654"))
	if s05_view == "card":
		# The cleaner's card for case 5: the red house, and where its owner's eyes, head, body and legs go.
		draw_rect(Rect2(c.x - 120, c.y - 90, 240, 180), Color("#e8e2c8"), true)
		draw_string(ThemeDB.fallback_font, Vector2(c.x - 110, c.y - 70), "编号 5 · 展品剪影", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#4a3a2a"))
		var house := Rect2(c.x - 40, c.y - 40, 80, 46)
		draw_rect(house, Color(0.76, 0.25, 0.18, 0.35), true)
		draw_rect(Rect2(c.x - 8, c.y - 14, 16, 20), Color(0.35, 0.16, 0.11, 0.45), true)
		var ink := Color(0.12, 0.1, 0.1, 0.85)
		draw_circle(Vector2(c.x, c.y - 6), 10.0, ink)
		draw_circle(Vector2(c.x, c.y + 26), 18.0, ink)
		for dir in [-1.0, 1.0]:
			for k in range(4):
				var root := Vector2(c.x + dir * 8, c.y + 28)
				var knee := root + Vector2(dir * (26 + k * 4), -16 + k * 10)
				draw_line(root, knee, ink, 4.0)
				draw_line(knee, knee + Vector2(dir * 12, 18), ink, 3.0)
		for wpos in [Vector2(-28, -30), Vector2(18, -30), Vector2(-28, -16), Vector2(18, -16)]:
			draw_rect(Rect2(c + wpos, Vector2(10, 9)), Color(0.96, 0.9, 0.7), true)
			draw_circle(c + wpos + Vector2(3, 4.5), 1.6, ink)
			draw_circle(c + wpos + Vector2(7, 4.5), 1.6, ink)
		draw_string(ThemeDB.fallback_font, Vector2(c.x - 110, c.y + 78), "眼在窗里 · 头在门口 · 身在路上 · 腿在草上", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#4a3a2a"))
	elif s05_view == "house":
		# The telescope, aimed past the rack at the mural: one window of the red house in focus at a time.
		draw_circle(c, 150.0, Color("#8fc3ea"))
		draw_rect(Rect2(c.x - 100, c.y - 60, 200, 140), Color("#c2402f"), true)
		var sharp := s05_lens_notch if s05_lens_notch < 4 else -1
		for i in range(4):
			var w := Rect2(c.x - 80 + (i % 2) * 100, c.y - 45 + (i / 2) * 60, 60, 46)
			draw_rect(w, Color("#f4e7b8"), true)
			if i == sharp:
				_draw_s07_window_scene(S07_WINDOW_ROOMS[i], w)
			else:
				draw_rect(w, Color(0.95, 0.9, 0.75, 0.85), true)
				for k in range(5):
					draw_rect(w.grow(-2.0 * k), Color(0.95, 0.9, 0.75, 0.15), false, 3.0)
	else:
		# The rack's last row: four empty C-shaped shelves and the fogged case.
		var blur := absf(float(s05_lens_notch - S05_FOCUS_NOTCH)) * 4.0
		for i in range(5):
			var p := c + Vector2(-112 + i * 56, 0)
			if i < 4:
				var gap: int = S05_LAST_ROW_GAPS[i]
				if blur <= 0.1:
					_draw_s05_c(p, 18.0, gap, Color("#cfc8b4"), 6.0)
				else:
					for k in range(6):
						var off := Vector2(cos(k * 1.05), sin(k * 1.05)) * blur
						_draw_s05_c(p + off, 18.0, gap, Color(0.81, 0.78, 0.7, 0.25), 6.0 + blur)
			else:
				draw_rect(Rect2(p - Vector2(24, 24), Vector2(48, 48)), Color(0.75, 0.77, 0.8, 0.55), true)
				if blur <= 0.1 and s05_lens_clean:
					for k in range(8):
						draw_circle(p + Vector2(-13 + (k % 4) * 9, -5 + (k / 4) * 10), 3.0, Color("#1f3b55"))
		if not s05_lens_clean:
			draw_circle(c, 150.0, Color(0.92, 0.93, 0.95, 0.85))
	draw_arc(c, 150.0, 0.0, TAU, 48, Color("#b08d57"), 6.0)

## Through the telescope, a window in focus shows a tiny view of its room and where its hidden thing is.
func _draw_s07_window_scene(room: String, w: Rect2) -> void:
	draw_rect(w, Color("#3a3026") if room != "s02" else Color("#1c2230"), true)
	var p := w.position
	match room:
		"s01":
			draw_rect(Rect2(p + Vector2(8, 10), Vector2(14, 14)), Color("#d8cfb5"), true)
			_draw_s07_egg("s01", p + Vector2(12, 15), 0.6)
		"s02":
			draw_rect(Rect2(p + Vector2(10, 8), Vector2(18, 16)), Color("#2c3747"), true)
			draw_line(p + Vector2(8, 28), p + Vector2(32, 28), Color(0.5, 0.75, 0.95), 2.0)
			_draw_s07_egg("s02", p + Vector2(20, 28), 0.6)
		"s04":
			draw_rect(Rect2(p + Vector2(18, 8), Vector2(18, 18)), Color("#b49464"), true)
			_draw_s07_egg("s04", p + Vector2(40, 18), 0.6)
		"hall":
			draw_rect(Rect2(p + Vector2(6, 6), Vector2(48, 20)), Color("#6aa84f"), true)
			draw_rect(Rect2(p + Vector2(40, 26), Vector2(8, 8)), Color("#6f7d88"), true)
			_draw_s07_egg("hall", p + Vector2(50, 34), 0.6)

## --- Lines -------------------------------------------------------------------------------------
func _s05_say(lines: Array) -> void:
	s05_lines = lines.slice(1)
	_show_dialogue(lines[0])
	s05_line_timer = S04_LINE_TIME

func _s05_next_line() -> void:
	if s05_lines.is_empty():
		return
	_show_dialogue(s05_lines.pop_front())
	s05_line_timer = S04_LINE_TIME

func _hall_say(lines: Array) -> void:
	_s05_say(lines)

## --- Per-frame -------------------------------------------------------------------------------
func _update_hall(delta: float) -> void:
	if scene_state == "theater":
		if theater_reveal >= 0.0:
			theater_reveal += delta
			if theater_reveal > 2.8:
				theater_reveal = -1.0
		return
	if not (s05_active or s06_active or s07_active or s08_active):
		return
	if s05_line_timer > 0.0:
		s05_line_timer -= delta
		if s05_line_timer <= 0.0:
			if not s05_lines.is_empty():
				_s05_next_line()
			elif s05_finish_pending:
				_s05_finish()
				return
			elif s06_finish_pending:
				_s06_finish()
				return
	if s07_achievement_time >= 0.0:
		s07_achievement_time += delta
		if s07_achievement_time > 4.0:
			s07_achievement_time = -1.0
	if s05_active and s05_enter_anim >= 0.0:
		s05_enter_anim += delta / 0.9
		if s05_enter_anim >= 1.0:
			s05_enter_anim = -1.0
			_s05_enter_hall()
		return
	if s07_active and s07_travel_anim >= 0.0:
		s07_travel_anim += delta / 0.8
		if s07_travel_anim >= 1.0:
			s07_travel_anim = -1.0
			_s07_arrive(s07_travel_to)
		return
	if s08_black_time >= 0.0:
		s08_black_time += delta
		if s08_black_time >= 0.7:
			s08_black_time = -1.0
			_s08_to_stage()
		return
	if not _in_sensor_hall() or not player:
		return
	if _s05_in_painting():
		# Walking on the painted road: small near the house, the road narrowing to the door.
		var t := _s05_paint_t()
		player.scale = Vector2.ONE * lerpf(S05_FAR_SCALE, S05_PAINT_SCALE, t)
		var half := lerpf(66.0, 8.0, t)
		player.position.x = clampf(player.position.x, S05_MURAL_CX - half, S05_MURAL_CX + half)
	else:
		var z := _s05_player_z()
		player.scale = Vector2.ONE * _s05_scale(z)
		player.position.x = clampf(player.position.x, _s05_px(100, z), _s05_px(1005, z))
		if s05_active and s05_room == "hall" and not s05_stepped_out and player.position.y > S05_FAR_Y + 12.0:
			s05_stepped_out = true
			chapter_state.mark_event(&"s05_stepped_out_of_the_mural")
			if s05_lines.is_empty():
				_show_dialogue("（格雷汉从画里走了出来。回头看，清洁工的梯子还平平地靠在那面墙上。）")
	if s05_view != "":
		var spot := _s05_item("Rack") if s05_view == "card" else _s05_item("Eyepiece")
		if spot.is_empty() or not _s05_near(spot):
			s05_view = ""
	if s08_active and s08_stolen and not s08_exit_started:
		_update_s08_chase(delta)

## --- Items -----------------------------------------------------------------------------------
func _s05_item(item_name: String) -> Dictionary:
	for item in s05_hall_items:
		if item.name == item_name:
			return item
	return {}

func _s05_item_z(item: Dictionary) -> float:
	return _s05_lens_z() if item.name == "Lens" else float(item.z)

func _s05_near(item: Dictionary) -> bool:
	if item.is_empty() or not player:
		return false
	var z := _s05_item_z(item)
	var pz := _s05_player_z()
	# The cleaner can be spoken to from anywhere in his column; what he hears depends on the distance.
	var xz := pz if item.get("column", false) else z
	var x := _s05_px(S05_RAIL_X if item.name == "Lens" else float(item.x), xz)
	return absf(player.position.x - x) < float(item.r) * _s05_scale(xz) and absf(pz - z) < float(item.get("dz", 0.09))

func _get_nearest_s05_hall_item() -> Dictionary:
	if _s05_in_painting():
		return {}
	# Right at the front of the rail the eyepiece wins; anywhere else along the rail, the lens.
	var eyepiece := _s05_item("Eyepiece")
	if _s05_near(eyepiece):
		return eyepiece
	var lens := _s05_item("Lens")
	if _s05_near(lens):
		return lens
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s05_hall_items:
		if _s05_near(item):
			var d := absf(_s05_player_z() - _s05_item_z(item))
			if item.get("column", false):
				d += 0.3
			if d < best:
				best = d
				nearest = item
	return nearest

func _hall_nearest_as_interactable() -> Dictionary:
	var item := _get_nearest_s05_hall_item()
	if item.is_empty():
		return {}
	var z := _s05_player_z() if item.get("column", false) else _s05_item_z(item)
	var sx := _s05_px(S05_RAIL_X if item.name == "Lens" else float(item.x), z)
	var sy := _s05_y(z)
	return {"name": item.name, "position": Vector2(sx, sy), "radius": 10.0, "hint_y": sy + 6.0}

## --- S05 ------------------------------------------------------------------------------------
func _s05_enter_hall() -> void:
	s05_room = "hall"
	_s05_set_depth_mode(true)
	# Out of 《窗》 and in through the red house's door: Graham is inside the mural, tiny, on its doorstep.
	player.position = Vector2(S05_MURAL_CX, S05_PAINT_TOP_Y + 1.0)
	player.scale = Vector2.ONE * S05_PAINT_SCALE
	player.input_locked = false
	chapter_state.set_map_state(&"Museum_S05_SensorHall")
	chapter_state.set_player_goal(&"explore_the_sensor_hall")
	objective_label.text = "S：顺着路往下走，走出画   W / S：走远、走近"
	s05_labeled = true
	chapter_state.mark_event(&"s05_labeled_by_cleaner")
	_s05_say([
		"（窗里的景色越来越近——格雷汉站在红房子的门口。在一幅画里。）",
		"（画外面是一间很深的展厅。梯子上有个人，正在擦一座空展架。）\n清洁工（远远地）：又来了一件小展品。……编号，贴上。",
		"（一张标签飞过来，贴在格雷汉的袖子上。）\nBlue Lake：在他眼里，你现在大概只有一粒米那么大。"
	])

func _s05_hall_interact() -> void:
	var nearest := _get_nearest_s05_hall_item()
	if nearest.is_empty():
		if _s05_in_painting():
			_show_dialogue("（还在画里。往下走，走出去。）")
		return
	var n := String(nearest.name)
	match n:
		"Cleaner":
			_s05_talk_to_cleaner()
		"Bucket":
			chapter_state.mark_event(&"s05_bucket_seen")
			_show_dialogue("水桶底下裂了一道缝。\n清洁工：上回打翻了，水全漏到楼下去了。楼下那幅画，到现在还湿着吧。")
		"Mural":
			chapter_state.mark_event(&"s05_mural_seen")
			_show_dialogue("壁画：绿草，蓝天，一条路，路的尽头是一座红房子。红房子有四扇窗。\n……这座房子，是美术馆。我们就是从它的门里走出来的。")
		"Rack":
			_show_dialogue("视力表展架：每个“C”都是一格展架，走近了才发现比人还高。\n全都空着。只有最后一行的第五格是一只玻璃柜，雾蒙蒙的。")
		"Pile":
			chapter_state.mark_event(&"s05_pile_seen")
			_show_dialogue("清洁工把展架上的展品全搬了下来，堆在这里，好擦展架。\n眼球、镜头、透镜……一代一代的，乱七八糟堆成一团。")
		"Lamp":
			_show_dialogue("一盏落地灯，灯头对着那堆展品。")
		"Lens":
			_s05_move_lens()
		"Eyepiece":
			_s05_look_through_lens()
		_:
			if n.begins_with("Plinth_"):
				var room := n.substr(7)
				var where: String = S07_WINDOW_NAMES[S07_WINDOW_ROOMS.find(room)]
				_show_dialogue("空展台。说明牌上画着一座红房子，" + where + "那扇窗涂成了黑色。")

## What the cleaner says depends on how big he looks from where Graham stands.
func _s05_cleaner_aside() -> String:
	if _s05_cleaner_size() == "giant":
		return "（从这么近看，清洁工大得顶到了天花板。他低头找了半天：）\n清洁工：声音从哪儿来的？太小了，看不见。"
	return "（从这么远看，清洁工小得像一粒扣子。）\n清洁工（细声细气）：……谁？那么大一个，挡着光了。"

func _s05_talk_to_cleaner() -> void:
	if _s05_cleaner_size() != "normal":
		if not s05_cleaner_met:
			_show_dialogue(_s05_cleaner_aside() + "\nBlue Lake：地上有一对脚印。站到那儿试试？")
		else:
			_show_dialogue(_s05_cleaner_aside())
		return
	if not s05_cleaner_met:
		s05_cleaner_met = true
		chapter_state.mark_event(&"s05_cleaner_met")
		objective_label.text = "帮清洁工看清视力表的最后一行"
		_s05_say([
			"清洁工：……哦，原来你这么大。站在脚印上，我看你才是正常大小。",
			"清洁工：我眼睛有毛病，医生说叫“爱丽丝梦游仙境症”，看什么都忽大忽小。\n……在这间屋子里，连别人看我也忽大忽小。",
			"清洁工：格雷汉·斯蒂尔，修灯的。你的标签我早就贴过了，就在楼下那扇门上。",
			"清洁工：这里展的是视觉传感器，一代一代的。今天擦展架，展品全搬下来了。\n可这面视力表我排了很多年，最后一行总差一格。",
			"清洁工：最后一行我看不清。你帮我看看？前面有块老镜片，从目镜里对着它看。\n镜片脏了就推到清洁区来——地上画着框的那块。放到那儿的东西，我都擦。"
		])
	elif not s05_lens_clean:
		_show_dialogue("清洁工：镜片推到清洁区来，我就擦。")
	elif not s05_cell_seen:
		_show_dialogue("清洁工：擦干净了，去看吧。")
	else:
		_show_dialogue("清洁工：第五格？我把展品一件不落全搬下来了。那一格什么也没有。")

func _s05_move_lens() -> void:
	var push := _s05_player_z() < _s05_lens_z()
	if push and s05_lens_notch < S05_RAIL_NOTCHES - 1:
		s05_lens_notch += 1
	elif not push and s05_lens_notch > 0:
		s05_lens_notch -= 1
	else:
		_show_dialogue("镜片架推到头了。")
		return
	chapter_state.mark_event(&"s05_lens_moved")
	if s05_lens_notch == S05_CLEAN_NOTCH and not s05_lens_clean:
		s05_lens_clean = true
		chapter_state.mark_event(&"s05_lens_cleaned")
		_s05_say([
			"清洁工：哟，这儿还有一件。脏成这样。",
			"（他从梯子上探过身，把镜片擦得干干净净。）\n清洁工：好了。"
		])
	elif not s05_lens_clean:
		var left := S05_CLEAN_NOTCH - s05_lens_notch
		_show_dialogue("格雷汉把镜片架往" + ("里推了一格。" if push else "外拉了一格。") + "\n镜片上蒙着一层白雾。" + ("离清洁区还有 %d 格。" % left if left > 0 else ""))
	else:
		_show_dialogue("格雷汉把镜片架往" + ("里推了一格。" if push else "外拉了一格。"))

func _s05_look_through_lens() -> void:
	chapter_state.mark_event(&"s05_eyepiece_used")
	if s07_active:
		_s07_telescope()
		return
	s05_view = "lens"
	if not s05_lens_clean:
		if s05_cleaner_met:
			_show_dialogue("镜片上蒙着一层白雾，什么也看不清。\nBlue Lake：把镜片推到清洁区去。")
		else:
			_show_dialogue("镜片上蒙着一层白雾，什么也看不清。\nBlue Lake：去问问那个擦东西的人。")
	elif s05_lens_notch != S05_FOCUS_NOTCH:
		var d := s05_lens_notch - S05_FOCUS_NOTCH
		_show_dialogue("最后一行的 C 糊成一片。\n镜片离目镜太" + ("远" if d > 0 else "近") + "了，往" + ("回拉" if d > 0 else "里推") + " %d 格试试。" % absi(d))
	elif not s05_cell_seen:
		s05_cell_seen = true
		s05_finish_pending = true
		chapter_state.mark_event(&"s05_last_cell_seen")
		_s05_say([
			"看清了。最后一行：下，上，右，左……四格空展架。\n第五格不是空的。灰蒙蒙的玻璃后面，有八个小小的镜头，排成两行。",
			"清洁工（远远地）：第五格？我把展品一件不落全搬下来了。那一格什么也没有。",
			"格雷汉：……八只眼睛。\nBlue Lake：那我们就去擦一擦。"
		])
	else:
		_show_dialogue("第五格里，八个小小的镜头。")

func _s05_finish() -> void:
	s05_finish_pending = false
	chapter_state.complete_slice(ChapterState.Slice.S05_WINDOW)
	_enter_s06_after_s05()

## --- S06 drawing ----------------------------------------------------------------------------
func _s06_piece_floor_pos(piece: String) -> Vector2:
	var slot: int = s06_pieces.get(piece, 0)
	var base: Vector2 = S06_PIECE_FLOOR[piece]
	var s := _s05_scale(S06_PILE_Z)
	var x := _s05_px(S06_PILE_X + base.x + slot * S06_SLOT_STEP, S06_PILE_Z)
	return Vector2(x, _s05_y(S06_PILE_Z) - base.y * s)

func _draw_s06_pile() -> void:
	var s := _s05_scale(S06_PILE_Z)
	var foot := _s05_y(S06_PILE_Z)
	for k in range(4):
		draw_rect(Rect2(Vector2(_s05_px(S06_PILE_X - 70 + k * 40, S06_PILE_Z), foot - 8 * s), Vector2(16, 8) * s), Color("#5c6b7a"), true)
	for piece in S06_PIECES:
		var p := _s06_piece_floor_pos(piece)
		match piece:
			"body":
				draw_circle(p, 13.0 * s, Color("#64747b"))
				draw_circle(p, 6.0 * s, Color("#172431"))
			"head":
				draw_rect(Rect2(p - Vector2(10, 8) * s, Vector2(20, 16) * s), Color("#9aa7ab"), true)
			"legs_l", "legs_r":
				var dir := -1.0 if piece == "legs_l" else 1.0
				for k in range(3):
					draw_line(p, p + Vector2(dir * (16 + k * 4), -10 + k * 8) * s, Color("#b08d57"), 2.5 * s)
			"eyes":
				for k in range(8):
					draw_circle(p + Vector2(-9 + (k % 4) * 6, -3 + (k / 4) * 6) * s, 2.2 * s, Color("#2f6fa8"))
		if blue_lake_active and s06_active and not s06_shadow_done:
			var hover: bool = chalk_hover_target == "Piece_" + piece
			draw_arc(p, 16.0 * s, 0.0, TAU, 18, Color(0.75, 0.91, 1.0, 0.9 if hover else 0.4), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(_s05_px(S06_PILE_X, S06_PILE_Z) - 40, foot + 14), "搬下来的展品", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))

## Where a piece's shadow falls on the mural: on its mark in the right slot, shifted sideways otherwise.
func _s06_shadow_offset(piece: String) -> Vector2:
	var slot: int = s06_pieces.get(piece, 0)
	var correct: int = S06_PIECE_CORRECT[piece]
	return Vector2((slot - correct) * S06_SHADOW_SLOT, 0)

func _draw_s06_shadow() -> void:
	var shade := Color(0.04, 0.06, 0.1, 0.72)
	var snap := Color(1.0, 0.86, 0.45, 0.85)
	var cx := S05_MURAL_CX
	var door := Vector2(cx, S05_MURAL_HORIZON - 6.0)
	var road := Vector2(cx, S05_MURAL_HORIZON + 40.0)
	for piece in S06_PIECES:
		var o := _s06_shadow_offset(piece)
		var right: bool = s06_pieces.get(piece, 0) == S06_PIECE_CORRECT[piece]
		match piece:
			"body":
				draw_circle(road + o, 26.0, shade)
				draw_circle(road + o + Vector2(0, 22), 18.0, shade)
				if right:
					draw_arc(road + o, 28.0, 0.0, TAU, 32, snap, 2.0)
			"head":
				draw_circle(door + o, 14.0, shade)
				if right:
					draw_arc(door + o, 16.0, 0.0, TAU, 24, snap, 2.0)
			"legs_l", "legs_r":
				var dir := -1.0 if piece == "legs_l" else 1.0
				var root := road + o + Vector2(dir * 14, 4)
				for k in range(4):
					var knee := root + Vector2(dir * (40 + k * 7), -22 + k * 14)
					var tip := knee + Vector2(dir * 20, 30)
					draw_line(root, knee, shade, 6.0)
					draw_line(knee, tip, shade, 5.0)
					if right:
						draw_circle(tip, 3.0, snap)
			"eyes":
				# Light comes through the lenses: eight bright spots, two in each window when right.
				for i in range(4):
					var w := _s07_mural_window_rect(i)
					for k in range(2):
						var e := w.position + Vector2(4 + k * 6, 7) + o
						draw_circle(e, 2.6, Color(1.0, 0.95, 0.7, 0.95))
				if right:
					for i in range(4):
						draw_rect(_s07_mural_window_rect(i).grow(2), snap, false, 1.5)
	if s06_shadow_done:
		var c: Vector2 = _s06_case_rect().get_center()
		draw_dashed_line(_s07_mural_window_rect(3).get_center(), c, Color(1.0, 0.95, 0.7, 0.45), 2.0, 8.0)

## The fifth case at the end of the rack's last row, in screen space.
func _s06_case_rect() -> Rect2:
	var s := _s05_scale(S05_RACK_Z)
	var x := _s05_px(S05_RACK_X, S05_RACK_Z)
	var foot := _s05_y(S05_RACK_Z)
	var c := Vector2(x + 46.8 * s, foot - 54.0 * s)
	return Rect2(c - Vector2(9, 9) * s, Vector2(18, 18) * s)

func _draw_s06_case() -> void:
	var r := _s06_case_rect()
	var c := r.get_center()
	if not s06_case_clean:
		return
	draw_rect(r, Color("#1c2836"), true)
	if s06_sensor_revealed and not s08_stolen:
		for k in range(8):
			draw_circle(c + Vector2(-4.5 + (k % 4) * 3.0, -2.0 + (k / 4) * 4.0), 1.2, Color("#9fe3ff"))
	draw_rect(r, Color(0.8, 0.92, 1.0, 0.7), false, 1.0)
	if blue_lake_active and s06_active and not s06_sensor_revealed:
		var hover := chalk_hover_target == "SensorCase"
		draw_arc(c, 14.0, 0.0, TAU, 20, Color(0.75, 0.91, 1.0, 0.9 if hover else 0.45), 2.0)

func _draw_s06_hall() -> void:
	_draw_s05_hall()

## --- S06 logic ------------------------------------------------------------------------------
func _enter_s06_after_s05() -> void:
	if s06_active:
		return
	s05_active = false
	s05_view = ""
	s06_active = true
	s06_lamp_on = false
	s06_has_card = false
	s06_pieces = S06_PIECE_START.duplicate()
	s06_shadow_done = false
	s06_case_clean = false
	s06_sensor_revealed = false
	s06_finish_pending = false
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	if s05_room != "hall":
		# Tests may jump straight here: put Graham in the hall, out of the mural.
		s05_room = "hall"
		s05_labeled = true
		s05_stepped_out = true
		_s05_set_depth_mode(true)
		player.position = Vector2(_s05_px(560, 0.3), _s05_y(0.3))
	chapter_state.advance_to(ChapterState.Slice.S06_PLATFORM)
	chapter_state.set_map_state(&"Museum_S06_SensorHall_Shadow")
	chapter_state.set_player_goal(&"see_what_the_cleaner_cannot")
	chapter_state.mark_story_event(&"s06_started")
	objective_label.text = "让清洁工看见第五格"
	_hall_say([
		"格雷汉：……八只眼睛，两行四个。\n阿姨也有八只眼睛。四对。",
		"Blue Lake：他看不见那一格。也许得先让他看见“她”。\n那堆展品旁边有一盏落地灯。"
	])
	_update_ui()
	queue_redraw()

func _try_s06_interact() -> void:
	if not s06_active or scene_state != "gallery" or transition_started:
		return
	if not s05_lines.is_empty():
		_s05_next_line()
		return
	if s06_finish_pending:
		return
	var item := _get_nearest_s05_hall_item()
	if item.is_empty():
		return
	match String(item.name):
		"Lamp":
			if not s06_lamp_on:
				s06_lamp_on = true
				chapter_state.mark_event(&"s06_lamp_on")
				_show_dialogue("格雷汉打开落地灯。那堆展品的影子落在壁画上，大得吓人。\n一团乱糟糟的影子。Blue Lake：按 Space。我来挪一挪它们。")
				_show_space_prompt()
			else:
				_show_dialogue("灯离那堆东西很近，所以影子很大。")
		"Pile":
			if not s06_lamp_on:
				_show_dialogue("清洁工搬下来的展品，乱七八糟堆成一团。\n旁边那盏落地灯还没开。")
			elif s06_shadow_done:
				_show_dialogue("从这边看只是一堆展品。墙上看，是阿姨。")
			else:
				_show_dialogue("大眼球、镜头盒、两把折叠支架、一串小透镜……\nBlue Lake：按 Space，用粉笔挪它们，看墙上的影子落在画里的什么地方。")
		"Cleaner":
			_s06_talk_to_cleaner()
		"Rack":
			if s06_sensor_revealed:
				_show_dialogue("第五格里，一只蜘蛛形的视觉传感器，八只镜头。")
			elif s06_case_clean:
				_show_dialogue("玻璃擦干净了。里面……还是看不出是什么。灰扑扑的一团，分不出远近。\nBlue Lake：按 Space。")
				_show_space_prompt()
			elif s06_has_card:
				s05_view = "card"
				_show_dialogue("展架上钉着那张卡片：编号 5 · 展品剪影。\n眼在窗里，头在门口，身在路上，腿在草上。")
			else:
				_show_dialogue("视力表展架。只有第五格那只玻璃柜雾蒙蒙的。\n每一格都该有一张编号卡。第五格的卡……不在这儿。")
		_:
			_s05_hall_interact()
	queue_redraw()

func _s06_talk_to_cleaner() -> void:
	var size := _s05_cleaner_size()
	if s06_case_clean:
		_show_dialogue("清洁工：擦干净了。……里面到底是什么？")
	elif size == "giant":
		if not s06_has_card:
			s06_has_card = true
			chapter_state.mark_event(&"s06_card_received")
			_hall_say([
				"（从这么近看，清洁工大得顶到了天花板。他自言自语：）\n清洁工：第五格的卡片……放哪儿了。哦，在顶上。",
				"（他随手从展架最顶上取下一张卡片，钉在了展架上。）\nBlue Lake：E 展架，看看那张卡。"
			])
		else:
			_show_dialogue(_s05_cleaner_aside())
	elif not s06_shadow_done:
		if size == "normal":
			_show_dialogue("清洁工：第五格？那里什么也没有。\n第五格的卡片在展架最顶上，我现在够不着……我要是再大一点就好了。")
		else:
			_show_dialogue(_s05_cleaner_aside())
	elif size == "tiny":
		_s06_cleaner_climbs_in()
	elif size == "normal":
		_show_dialogue("清洁工：……那影子在看第五格。\n可第五格那么小，我钻不进去擦。……我要是再小一点就好了。")
	else:
		_show_dialogue(_s05_cleaner_aside())

func _try_toggle_s06_blue_lake() -> void:
	if not s06_lamp_on:
		_show_dialogue("Blue Lake：先把灯打开。")
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("Blue Lake：看墙上的影子。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_hide_space_prompt()
	_show_dialogue("Blue Lake：" + (_s06_chalk_hint() if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _s06_chalk_hint() -> String:
	if not s06_shadow_done:
		return "用粉笔点那堆展品里的东西，挪一挪。\n影子落对地方会亮一下：窗、门、路、草地。"
	if s06_case_clean and not s06_sensor_revealed:
		return "用粉笔点第五格。"
	return "……"

func _try_s06_chalk_interaction() -> void:
	if chalk_hover_target.begins_with("Piece_") and not s06_shadow_done:
		var piece := chalk_hover_target.substr(6)
		var slot: int = s06_pieces[piece]
		s06_pieces[piece] = -1 if slot == 1 else slot + 1
		chapter_state.mark_event(&"s06_piece_moved")
		if _s06_shadow_is_kent():
			_s06_shadow_complete()
		elif s06_pieces[piece] == S06_PIECE_CORRECT[piece]:
			_show_dialogue("Blue Lake：挪了挪" + S06_PIECE_NAMES[piece] + "。……咔。这一块的影子对上了。")
		else:
			_show_dialogue("Blue Lake：挪了挪" + S06_PIECE_NAMES[piece] + "。墙上的影子跟着动了。")
	elif chalk_hover_target == "SensorCase" and s06_case_clean and not s06_sensor_revealed:
		_s06_reveal_sensor()
	queue_redraw()

func _s06_shadow_is_kent() -> bool:
	for piece in S06_PIECES:
		if s06_pieces[piece] != S06_PIECE_CORRECT[piece]:
			return false
	return true

func _s06_shadow_complete() -> void:
	s06_shadow_done = true
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Standard"
	chapter_state.mark_event(&"s06_shadow_is_kent")
	_hall_say([
		"墙上的影子是一只八只眼睛的蜘蛛：眼睛在红房子的窗里，脚踩在草地上。\n格雷汉：……阿姨。",
		"Blue Lake：八只眼睛都在看同一个地方。\n格雷汉：第五格。去叫清洁工看看。"
	])

func _s06_cleaner_climbs_in() -> void:
	s06_case_clean = true
	chapter_state.mark_event(&"s06_case_cleaned")
	objective_label.text = "第五格里是什么？"
	_hall_say([
		"（从这么远看，清洁工小得像一粒扣子。他顺着影子的视线看过去——）\n清洁工（细声细气）：第五格？……原来那儿还有一格。这么小，正好钻进去。",
		"（小小的清洁工钻进第五格的玻璃柜，从里面把雾擦得干干净净，又钻了出来。）",
		"清洁工：可我还是看不清。灰扑扑的一团，分不出远近。"
	])

func _s06_reveal_sensor() -> void:
	s06_sensor_revealed = true
	s06_finish_pending = true
	_hide_space_prompt()
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Standard"
	chapter_state.mark_event(&"s06_visual_sensor_revealed")
	chapter_state.mark_event(&"s06_kent_optical_part_revealed")
	chapter_state.learn(&"s06_invisible_does_not_mean_nonexistent")
	_hall_say([
		"Blue Lake 借来阿姨看东西的方式：清楚的是近处，模糊的是远处。\n那团灰忽然有了前后——",
		"第五格里是一只蜘蛛形的视觉传感器，八只镜头，两行四个。\nBlue Lake：这里刚才明明什么都没有。",
		"格雷汉：这个型号……和阿姨坏掉的那只一模一样。\n早就停产了。我找了好几年。"
	])

func _s06_finish() -> void:
	s06_finish_pending = false
	chapter_state.complete_slice(ChapterState.Slice.S06_PLATFORM)
	_enter_s07_after_s06()

## --- S07: the red house ---------------------------------------------------------------------
func _draw_s07_gallery() -> void:
	if s07_room == "hall":
		_draw_s05_hall()
	elif s07_room == "s01":
		_draw_s01_gallery()
	elif s07_room == "s02":
		_draw_s02_hall()
	elif s07_room == "s04":
		_draw_s04_gallery()
	if s07_room != "hall":
		_draw_s07_room_extras()
	if s07_travel_anim >= 0.0:
		# The window grows until it is the room.
		var t := s07_travel_anim * s07_travel_anim
		var w := _s07_mural_window_rect(S07_WINDOW_ROOMS.find(s07_travel_to)) if s07_room == "hall" else _s07_return_rect()
		var full := Rect2(0, 58, 1152, 590)
		var g := Rect2(w.position.lerp(full.position, t), w.size.lerp(full.size, t))
		draw_rect(g, Color("#f4e7b8") if s07_room == "hall" else Color("#8fc3ea"), true)
		draw_rect(g, Color("#7a2a22"), false, 4.0)

## In each old room, a "window" that already hung there leads back: the red-house photo (S01),
## the water under 《那喀索斯》 (S02), and 《窗》 itself (S04). Blue Lake opens it with the Chalk.
func _s07_return_rect() -> Rect2:
	match s07_room:
		"s01":
			return S01_PHOTO_RECT
		"s02":
			return Rect2(S02_NARCISSUS_RECT.position.x, S02_NARCISSUS_RECT.end.y - 14, S02_NARCISSUS_RECT.size.x, 18)
		_:
			return Rect2(S05_WINDOW_CENTER - Vector2(45, 50), Vector2(90, 100))

func _draw_s07_room_extras() -> void:
	if not s07_found.get(s07_room, false):
		match s07_room:
			"s01":
				_draw_s07_egg("s01", Vector2(S01_MAP_RECT.position.x + 18, S01_MAP_RECT.position.y + 30), 0.8)
			"s02":
				_draw_s07_egg("s02", Vector2(S02_NARCISSUS_RECT.position.x + 66, S02_NARCISSUS_RECT.end.y - 4), 1.0)
			"s04":
				_draw_s07_egg("s04", Vector2(S04_GIRL_FRAME_X + 41, 306), 1.0)
	if blue_lake_active:
		var hover := chalk_hover_target == "ReturnWindow"
		draw_rect(_s07_return_rect().grow(4), Color(0.75, 0.91, 1.0, 0.95 if hover else 0.5), false, 2.0)

func _enter_s07_after_s06() -> void:
	if s07_active:
		return
	s06_active = false
	s07_active = true
	s07_room = "hall"
	s07_found = {"s01": false, "s02": false, "s04": false, "hall": false}
	s07_shelved = {"s01": false, "s02": false, "s04": false, "hall": false}
	s07_travel_anim = -1.0
	s07_hesitated = false
	s07_achievement_time = -1.0
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	chapter_state.advance_to(ChapterState.Slice.S07_RETURN)
	chapter_state.set_map_state(&"Museum_S07_RedHouse")
	chapter_state.set_player_goal(&"reobserve_old_areas")
	chapter_state.mark_story_event(&"s07_started")
	objective_label.text = "拿走传感器 · （可选）四个空展台，四扇窗"
	_hall_say([
		"清洁工：四个展台，空了很多年了。说明牌上画着红房子，一个展台一扇窗。",
		"Blue Lake：红房子的窗……按 Space，我用粉笔推开它们看看。\n目镜也能看见那几扇窗，镜片的位置不同，看清的窗也不同。"
	])
	_update_ui()
	queue_redraw()

func _try_s07_interact() -> void:
	if not s07_active or scene_state != "gallery" or transition_started:
		return
	if not s05_lines.is_empty():
		_s05_next_line()
		return
	if s07_travel_anim >= 0.0:
		return
	if s07_room != "hall":
		_s07_room_interact()
		queue_redraw()
		return
	var item := _get_nearest_s05_hall_item()
	if item.is_empty():
		return
	var n := String(item.name)
	if n == "Rack":
		if not s07_hesitated:
			s07_hesitated = true
			chapter_state.mark_event(&"s07_hesitated")
			_show_dialogue("格雷汉：……这是展品。清洁工擦了它一辈子都没看见过它。\n可阿姨等了好几年。")
		else:
			_s08_steal()
	elif n == "Bucket" and not s07_found["hall"]:
		_s07_find("hall")
		_show_dialogue("水桶后面卡着一颗蓝白色的纽扣。")
		_s07_shelve_new()
	elif n == "Cleaner":
		if _s05_cleaner_size() != "normal":
			_show_dialogue(_s05_cleaner_aside())
		else:
			_show_dialogue("清洁工：第五格里原来有东西。我排了一辈子，原来早就排满了。")
	else:
		_s05_hall_interact()
	queue_redraw()

func _s07_telescope() -> void:
	s05_view = "house"
	if s05_lens_notch >= 4:
		_show_dialogue("目镜越过展架，对着壁画上的红房子。\n镜片太远了，四扇窗都糊成一片。往回拉一拉。")
		return
	var room: String = S07_WINDOW_ROOMS[s05_lens_notch]
	var where: String = S07_WINDOW_NAMES[s05_lens_notch]
	var hint := ""
	match room:
		"s01":
			hint = "入口大厅。导览图上，眼睛的位置好像贴着什么。"
		"s02":
			hint = "表与里展厅。画框底下的水里，有东西在游。"
		"s04":
			hint = "画作展厅。少女的画框背后夹着一张纸。"
		"hall":
			hint = "这间展厅，和一个正在看着它的人。……水桶后面有一样蓝白色的东西。"
	_show_dialogue(where + "那扇窗清楚了：" + hint)

func _try_toggle_s07_blue_lake() -> void:
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue("Blue Lake：看窗。")
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	if blue_lake_active:
		_show_dialogue("Blue Lake：" + ("用粉笔点红房子的一扇窗。" if s07_room == "hall" else "用粉笔点那扇“窗”，回展厅去。"))
	else:
		_show_dialogue("Blue Lake：……先收起来。")
	_update_ui()
	queue_redraw()

func _try_s07_chalk_interaction() -> void:
	if s07_travel_anim >= 0.0:
		return
	if s07_room == "hall" and chalk_hover_target.begins_with("MuralWindow"):
		var i := int(chalk_hover_target.substr(11))
		var room: String = S07_WINDOW_ROOMS[i]
		chapter_state.mark_event(StringName("s07_opened_window_" + room))
		if room == "hall":
			_show_dialogue("窗里是这间展厅，和一个正在看着它的人。\n……水桶后面，有一样蓝白色的东西。")
			return
		_s07_travel(room)
	elif s07_room != "hall" and chalk_hover_target == "ReturnWindow":
		_s07_travel("hall")

func _s07_travel(room: String) -> void:
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Standard"
	s05_view = ""
	s07_travel_to = room
	s07_travel_anim = 0.0
	player.input_locked = true
	_show_dialogue("那扇窗越来越近——")
	_update_ui()

func _s07_arrive(room: String) -> void:
	player.input_locked = false
	if room == "hall":
		s07_room = "hall"
		_s05_set_depth_mode(true)
		player.position = Vector2(_s05_px(S05_MURAL_CX, 0.88), _s05_y(0.88))
		_show_dialogue("（又回到了展厅里，站在壁画跟前。）")
		_s07_shelve_new()
	else:
		s07_room = room
		_s05_set_depth_mode(false)
		player.position = Vector2(160.0, 470.0)
		chapter_state.mark_event(StringName("s07_visited_" + room))
		_show_dialogue("（" + S07_ROOM_NAMES[room] + "。要回去，就用蓝湖推开这里的“窗”。）")
	queue_redraw()

func _s07_room_interact() -> void:
	var nearest := _get_nearest_s07_interactable()
	if nearest.is_empty():
		return
	var n := String(nearest.name)
	if s07_found.get(s07_room, false):
		_show_dialogue("（已经找到了。带回去给清洁工看看。）")
		return
	_s07_find(s07_room)
	match n:
		"MapSticker":
			_show_dialogue("导览图：“你在这里”贴在后脑勺。\n眼睛的位置多了一张蓝白色的小贴纸：“它在这里”。格雷汉把它揭了下来。")
		"BlueFish":
			_show_dialogue("《那喀索斯》画框下沿的水里，游着一条蓝白色的小鱼。\n楼上漏下来的水里，怎么会有鱼？格雷汉用手捧了起来。")
		"GirlDrawing":
			_show_dialogue("画框背后夹着一张小画：一个修理工，旁边站着一个蓝色的影子。\n是她画的。格雷汉把它抽了出来。")

func _s07_find(room: String) -> void:
	s07_found[room] = true
	chapter_state.mark_event(StringName("s07_found_" + room))

## Back in the hall, the cleaner numbers and shelves what Graham found, with a remark.
func _s07_shelve_new() -> void:
	var lines: Array = []
	var remarks := {
		"s01": "清洁工：一张贴纸，“它在这里”。……贴错地方了吧，眼睛那儿又不是这里。\n编号一，贴上。",
		"s02": "清洁工：楼下水里捞上来的？我那桶水里可没养鱼。\n编号二，贴上。",
		"s04": "清洁工：画得不怎么样。这个修理工……有点像你。\n编号三，贴上。",
		"hall": "清洁工：我梯子底下的？我怎么没看见。……也是，我看什么都忽大忽小。\n编号四，贴上。"
	}
	for room in S07_WINDOW_ROOMS:
		if s07_found[room] and not s07_shelved[room]:
			s07_shelved[room] = true
			chapter_state.mark_event(StringName("s07_shelved_" + room))
			lines.append(remarks[room])
	if lines.is_empty():
		return
	var all_done := true
	for room in S07_WINDOW_ROOMS:
		if not s07_shelved[room]:
			all_done = false
	if all_done:
		lines.append("清洁工：四个展台都满了。我编了一辈子号，头一回编齐。")
		chapter_state.mark_event(&"achievement_all_filed")
		s07_achievement_time = 0.0
	_hall_say(lines)

func _get_nearest_s07_interactable() -> Dictionary:
	if s07_room == "hall":
		return _hall_nearest_as_interactable()
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s07_room_items:
		if item.room != s07_room:
			continue
		var distance: float = absf(player.position.x - item.position.x)
		if distance < item.radius and distance < best:
			best = distance
			nearest = item
	return nearest

## --- S08: take it and run -------------------------------------------------------------------
func _s08_steal() -> void:
	chapter_state.mark_event(&"s07_sensor_taken")
	chapter_state.complete_slice(ChapterState.Slice.S07_RETURN)
	s07_active = false
	s08_active = true
	s08_stolen = true
	s08_exit_started = false
	s08_run = 0.0
	s08_black_time = -1.0
	s05_view = ""
	blue_lake_active = false
	chalk_cursor.set_active(false)
	s08_guard = Vector2(_s05_px(1000, 0.04), _s05_y(0.04))
	chapter_state.advance_to(ChapterState.Slice.S08_TRUE_EXIT)
	chapter_state.set_map_state(&"Museum_S08_Escape")
	chapter_state.set_player_goal(&"escape")
	chapter_state.mark_story_event(&"s08_started")
	objective_label.text = "跑！"
	_show_dialogue("格雷汉打开第五格，把传感器揣进怀里。\n清洁工：喂——那是第五格的！　保安：站住！")
	_update_ui()
	queue_redraw()

func _update_s08_chase(delta: float) -> void:
	s08_run += absf(player.velocity.x) * delta + absf(player.velocity.y) * delta
	var d := s08_guard.distance_to(player.position)
	if d > S08_GUARD_REACH:
		s08_guard = s08_guard.move_toward(player.position, minf(S08_GUARD_SPEED * delta, d - S08_GUARD_REACH))
	elif d > 0.01:
		# Never quite caught: if she runs at him, he is always just out of reach (like an old cartoon).
		s08_guard = player.position + (s08_guard - player.position).normalized() * S08_GUARD_REACH
	if s08_run >= S08_RUN_TOTAL:
		s08_exit_started = true
		s08_black_time = 0.0
		transition_started = true
		player.input_locked = true
		chapter_state.mark_event(&"s08_ran_into_the_dark")

func _s08_iris_radius() -> float:
	return lerpf(900.0, 0.0, clampf(s08_run / S08_RUN_TOTAL, 0.0, 1.0))

func _draw_s08_chase() -> void:
	if not s08_stolen:
		return
	var gz := clampf((S05_NEAR_Y - s08_guard.y) / (S05_NEAR_Y - S05_FAR_Y), 0.0, 1.0)
	var s := _s05_scale(gz)
	var g := s08_guard
	draw_rect(Rect2(g.x - 12 * s, g.y - 46 * s, 24 * s, 40 * s), Color("#566b7a"), true)
	draw_circle(Vector2(g.x, g.y - 54 * s), 10.0 * s, Color("#bba88c"))
	draw_line(Vector2(g.x + 10 * s, g.y - 40 * s), Vector2(g.x + 10 * s + signf(player.position.x - g.x) * 22 * s, g.y - 44 * s), Color("#566b7a"), 4.0 * s)
	draw_string(ThemeDB.fallback_font, Vector2(g.x - 20, g.y - 72 * s), "保安", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f0c6a5"))
	# Like the end of an old cartoon: a circle closing in on Graham as she runs, until it is all black.
	var r := _s08_iris_radius()
	if s08_black_time >= 0.0 or r < 2.0:
		draw_rect(Rect2(0, 0, 1152, 648), Color.BLACK, true)
		return
	var c := player.position + Vector2(0, -6) * player.scale.x
	draw_arc(c, r + 1100.0, 0.0, TAU, 128, Color.BLACK, 2200.0)

func _s08_to_stage() -> void:
	chapter_state.mark_event(&"s08_iris_closed")
	chapter_state.learn(&"s08_left_the_gallery_with_kents_eyes")
	_finish_transition()
	theater_reveal = 0.0

func _try_s08_interact() -> void:
	if not s08_active or scene_state != "gallery" or transition_started:
		return
	_show_dialogue("Blue Lake：别停！跑！")

func _try_toggle_s08_blue_lake() -> void:
	_show_dialogue("Blue Lake：别看了，跑！")

func _try_s08_chalk_interaction() -> void:
	pass

func _get_nearest_s06_interactable() -> Dictionary:
	return _hall_nearest_as_interactable()

func _get_nearest_s08_interactable() -> Dictionary:
	return {}

## The theater after the black: a sudden circle of light on Graham, then the stage around her.
func _draw_theater_reveal() -> void:
	if theater_reveal < 0.0 or not player:
		return
	var t := theater_reveal
	if t < 0.45:
		draw_rect(Rect2(0, 0, 1152, 648), Color.BLACK, true)
		return
	var a := 1.0 if t < 1.7 else clampf(1.0 - (t - 1.7) / 1.0, 0.0, 1.0)
	draw_arc(player.position + Vector2(0, -10), 70.0 + 1100.0, 0.0, TAU, 128, Color(0, 0, 0, a), 2200.0)

func _try_s05_interact() -> void:
	if not s05_active or scene_state != "gallery" or transition_started:
		return
	if not s05_lines.is_empty():
		_s05_next_line()
		return
	if s05_finish_pending or s05_enter_anim >= 0.0:
		return
	if s05_room == "hall":
		_s05_hall_interact()
		queue_redraw()
		return
	var nearest := _get_nearest_s05_interactable()
	if nearest.is_empty():
		return
	if not s05_window_observed:
		s05_window_observed = true
		chapter_state.mark_event(&"s05_window_observed")
	_show_dialogue("《窗》：窗外是蓝天和草地。现在它有了窗框，也有了把手（右边那一小块）。\nBlue Lake：按 Space，再用粉笔点一下《窗》，就能打开它。")
	_show_space_prompt()
	queue_redraw()

func _try_toggle_s05_blue_lake() -> void:
	if s05_room == "hall":
		_show_dialogue("Blue Lake：在这里，我看什么都差不多大。")
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
	_hide_space_prompt()
	_show_dialogue("Blue Lake：" + ("把粉笔移到《窗》上（哪里都行），点左键。" if blue_lake_active else "……先收起来。"))
	_update_ui()
	queue_redraw()

func _try_s05_chalk_interaction() -> void:
	if chalk_hover_target != "Window" or s05_window_open:
		return
	s05_window_open = true
	_hide_space_prompt()
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Standard"
	chapter_state.mark_event(&"s05_window_opened")
	chapter_state.learn(&"s05_blue_lake_can_change_the_world")
	chapter_state.set_player_goal(&"understand_the_window")
	_show_dialogue("Blue Lake：你把一幅画……打开了。")
	objective_label.text = "《窗》打开了。"
	player.input_locked = true
	s05_enter_anim = 0.0
	_update_ui()
	queue_redraw()

func _enter_s05_after_s04() -> void:
	if s05_active:
		return
	s04_active = false
	s05_active = true
	s05_room = "window"
	s05_window_observed = false
	s05_window_open = false
	s05_enter_anim = -1.0
	s05_stepped_out = false
	s05_labeled = false
	s05_cleaner_met = false
	s05_lens_notch = 2
	s05_lens_clean = false
	s05_view = ""
	s05_cell_seen = false
	s05_finish_pending = false
	s05_lines = []
	s05_line_timer = 0.0
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	chapter_state.advance_to(ChapterState.Slice.S05_WINDOW)
	chapter_state.set_map_state(&"Museum_S05_Window")
	chapter_state.set_player_goal(&"find_the_window")
	chapter_state.mark_story_event(&"s05_started")
	objective_label.text = "打开《窗》：Space，再用粉笔点它"
	_show_dialogue("Blue Lake：有窗框，有把手。……按 Space，我们去打开它。")
	_show_space_prompt()
	_update_ui()
	queue_redraw()


















func _enter_s04_after_s03() -> void:
	if s04_active:
		return
	s03_active = false
	s04_active = true
	s04_window = "cone"
	s04_win_t = 0.0
	s04_window_seen = false
	s04_restorer_met = false
	s04_signal_progress = 0
	s04_signal_traced = false
	s04_starry_repaired = false
	s04_has_riboflavin = false
	s04_riboflavin_applied = false
	s04_girl_out = false
	s04_girl_x = S04_GIRL_FRAME_X
	s04_girl_pause = 0.0
	s04_girl_paused_here = false
	s04_girl_frozen = false
	s04_girl_caught = false
	s04_uv_on = false
	s04_visitors_recognized = false
	s04_handle_found = false
	s04_frame_installed = false
	s04_finish_pending = false
	s04_lines = []
	s04_line_timer = 0.0
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	# Through the 里 door of the second hall Graham steps in at the left wall, walking right.
	player.position.x = 100.0
	chapter_state.advance_to(ChapterState.Slice.S04_VISITOR)
	chapter_state.set_map_state(&"Museum_S04_Visitor")
	chapter_state.set_player_goal(&"recognize_the_visitor")
	chapter_state.mark_story_event(&"s04_started")
	objective_label.text = "这间屋子的光从哪里来？"
	_show_dialogue("（这间展厅很亮。光全是从中间那幅画里照出来的。）\nBlue Lake：你刚才相信了一个眼睛看不到的东西。")
	_update_ui()
	queue_redraw()

func _update_route_transitions() -> void:
	if not player or scene_state != "gallery":
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
	if s05_room == "hall":
		var item := _get_nearest_s05_hall_item()
		if item.is_empty():
			return {}
		var z := _s05_item_z(item)
		var sx := _s05_px(S05_RAIL_X if item.name == "Lens" else float(item.x), z)
		var sy := _s05_y(z)
		return {"name": item.name, "position": Vector2(sx, sy), "radius": 10.0, "hint_y": sy + 6.0}
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s05_interactables:
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
	# The way out of the gallery (S08: through 《窗》 with the guard behind) ends with the curtain
	# opening on the Truth Theater stage.
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
	_s05_set_depth_mode(false)
	if s08_active:
		chapter_state.set_map_state(&"Theater_Stage_Entrance")
		chapter_state.mark_story_event(&"s08_true_exit_reached")
		chapter_state.mark_story_event(&"s08_escaped_with_kents_eyes")
		chapter_state.mark_story_event(&"theater_entered")
		chapter_state.complete_slice(ChapterState.Slice.S08_TRUE_EXIT)
		objective_label.text = "真理美术馆 · 完"
		_show_dialogue("全黑。\n——啪。一圈灯光打下来，照在格雷汉身上。你站在舞台上。")
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

	_draw_theater_reveal()
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
		if s04_active:
			interaction_hint_label.text = "左键 拉窗帘" if chalk_hover_target == "S04Window" else "左键 描"
		elif s05_active and chalk_hover_target == "Window":
			interaction_hint_label.text = "左键 打开《窗》"
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
	if s05_active or s06_active or s07_active or s08_active:
		var n5: String = nearest.get("name", "")
		if not s05_lines.is_empty():
			interaction_hint_label.text = "E 继续"
		elif n5 == "Cleaner":
			interaction_hint_label.text = "E 说话"
		elif n5 == "Lens":
			interaction_hint_label.text = "E 往里推" if _s05_player_z() < _s05_lens_z() else "E 往外拉"
		elif n5 == "Eyepiece":
			interaction_hint_label.text = "E 看"
		elif s07_active and n5 == "Rack":
			interaction_hint_label.text = "E 拿走" if s07_hesitated else "E 看"
		elif s06_active and n5 == "Lamp" and not s06_lamp_on:
			interaction_hint_label.text = "E 开灯"
	if s04_active:
		var n4: String = nearest.get("name", "")
		if not s04_lines.is_empty():
			interaction_hint_label.text = "E 继续"
		elif n4 in ["Restorer", "Visitor", "VisitorGroup"]:
			interaction_hint_label.text = "E 说话"
		elif n4 == "Workbench" and s04_has_riboflavin and not s04_riboflavin_applied:
			interaction_hint_label.text = "E 抹上核黄素"
		elif n4 == "Workbench" and s04_girl_caught:
			interaction_hint_label.text = "E 关紫外灯" if s04_uv_on else "E 开紫外灯"
		elif n4 == "Window" and s04_girl_caught and not s04_frame_installed and not (s04_uv_on and s04_win_t >= 0.5 and not s04_handle_found):
			interaction_hint_label.text = "E 装上画框"
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
		if not s04_signal_traced and _s04_signal_alpha() > 0.5:
			for k in range(S04_SIGNAL_NODES.size()):
				if mouse_position.distance_to(S04_SIGNAL_NODES[k]) <= 14.0:
					chalk_hover_target = "Signal%d" % k
		if chalk_hover_target == "" and mouse_position.distance_to(S05_WINDOW_CENTER) <= 62.0:
			chalk_hover_target = "S04Window"
	elif S05_ENABLED and s05_active:
		# The whole framed painting (and a margin around it) opens it, not just the small handle.
		if s05_room == "window" and not s05_window_open and Rect2(S05_WINDOW_CENTER - Vector2(53, 58), Vector2(106, 116)).grow(28.0).has_point(mouse_position):
			chalk_hover_target = "Window"
	elif S06_ENABLED and s06_active:
		if s06_lamp_on and not s06_shadow_done:
			var sc := _s05_scale(S06_PILE_Z)
			for piece in S06_PIECES:
				if mouse_position.distance_to(_s06_piece_floor_pos(piece)) <= 16.0 * sc:
					chalk_hover_target = "Piece_" + piece
		if s06_case_clean and not s06_sensor_revealed and _s06_case_rect().grow(10.0).has_point(mouse_position):
			chalk_hover_target = "SensorCase"
	elif S07_ENABLED and s07_active:
		if s07_room == "hall":
			for i in range(4):
				if _s07_mural_window_rect(i).grow(6.0).has_point(mouse_position):
					chalk_hover_target = "MuralWindow%d" % i
		elif _s07_return_rect().grow(6.0).has_point(mouse_position):
			chalk_hover_target = "ReturnWindow"
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
