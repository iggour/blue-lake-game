extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const CursorScript := preload("res://scripts/chalk_cursor.gd")
const TransitionScript := preload("res://scripts/transition_overlay.gd")
const BlueLakeTransformScript := preload("res://scripts/blue_lake_transform.gd")
const ChapterStateScript := preload("res://scripts/chapter_state.gd")
# S01 entrance hall. From afar the wall is a face: 《观看的永恒》 and 《这不是一只眼睛》 are the eyes,
# the "出口" sign over the door is the nose and the exit door is the mouth.
const S01_PHOTO_RECT := Rect2(110, 215, 140, 100)
const S01_MAP_RECT := Rect2(270, 225, 80, 90)
const S01_CLOCKS_RECT := Rect2(430, 185, 190, 110)
const S01_CLOCK_BACK := Vector2(470, 236)      # left melting eye: its hands turn the photo back
const S01_CLOCK_FORWARD := Vector2(585, 236)   # right melting eye: forward, and then it melts
const S01_DOOR_RECT := Rect2(680, 282, 80, 90)
const S01_SIGN := Vector2(720, 262)            # the "出口" sign: the face's nose
const S01_EYE_RECT := Rect2(850, 185, 120, 110)
const S01_EYE_CENTER := Vector2(910, 236)
const S01_PHOTO_ERAS := ["开幕日", "冬天", "多年以后"]
const S01_HINT_AFTER := 12.0                   # seconds without progress before the eye starts hinting
# 《观看的永恒》 keeps the photo's era: warm opening day, winter, years of dust.
const S01_CLOCK_SKY := [Color("#d9a95e"), Color("#a9bccb"), Color("#76786f")]
const S01_CLOCK_GROUND := [Color("#c49a5e"), Color("#e8eef2"), Color("#7b766c")]
# The community map is a maze of sulci on a 13 × 7 grid (x 0..12 = front of the head .. back).
# The red "你在这里" dot starts at the back, inside a round printed gyrus; the grooves form a tree,
# and the one way to "出口" at the front draws a key's blade and teeth (the gyrus is its bow).
# The first path is the solution; the others are dead-end grooves branching off it.
const S01_MAZE_START := Vector2i(11, 3)
const S01_MAZE_GOAL := Vector2i(0, 3)
const S01_MAZE_PATHS := [
	[Vector2i(11, 3), Vector2i(10, 3), Vector2i(9, 3), Vector2i(8, 3), Vector2i(7, 3), Vector2i(6, 3), Vector2i(5, 3), Vector2i(4, 3), Vector2i(4, 4), Vector2i(3, 4), Vector2i(3, 3), Vector2i(2, 3), Vector2i(2, 4), Vector2i(1, 4), Vector2i(1, 3), Vector2i(0, 3)],
	[Vector2i(9, 3), Vector2i(9, 2), Vector2i(9, 1), Vector2i(8, 1), Vector2i(7, 1), Vector2i(7, 0)],
	[Vector2i(9, 1), Vector2i(10, 1)],
	[Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(9, 4)],
	[Vector2i(7, 5), Vector2i(7, 6), Vector2i(6, 6)],
	[Vector2i(6, 3), Vector2i(6, 2), Vector2i(5, 2), Vector2i(4, 2), Vector2i(4, 1), Vector2i(3, 1), Vector2i(2, 1), Vector2i(2, 2), Vector2i(1, 2)],
	[Vector2i(4, 1), Vector2i(4, 0), Vector2i(5, 0)],
	[Vector2i(6, 2), Vector2i(6, 1), Vector2i(6, 0)],
	[Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5), Vector2i(2, 5)],
	[Vector2i(4, 5), Vector2i(4, 6)],
	[Vector2i(8, 3), Vector2i(8, 4)],
	[Vector2i(1, 4), Vector2i(1, 5)]
]
const S01_MAZE_ROOM_AREA := Rect2(283, 257, 54, 30)   # the grid on the small map on the wall
const S01_MAZE_BIG_AREA := Rect2(95, 100, 504, 216)   # the grid in the map's close-up (its own space)
# Close-ups (特写): where each one sits on screen; its content is drawn in a space of that size.
const CLOSEUP_RECTS := {
	"photo": Rect2(316, 88, 520, 380),
	"map": Rect2(226, 88, 700, 380),
	"clocks": Rect2(296, 105, 560, 340),
	"door": Rect2(406, 88, 340, 380),
	"eye": Rect2(356, 95, 440, 360),
	"guard": Rect2(356, 90, 440, 380),
	"narcissus": Rect2(276, 88, 600, 390),
	"venus": Rect2(316, 88, 520, 400),
	"lan": Rect2(366, 110, 420, 300),
	"bench": Rect2(276, 88, 600, 390),
	"smear": Rect2(396, 84, 360, 404),
	"girl": Rect2(396, 88, 360, 400),
	"window": Rect2(366, 88, 420, 400),
	"visitor": Rect2(426, 90, 300, 380),
	"twins": Rect2(386, 110, 380, 340),
	"swap": Rect2(406, 88, 360, 400),
	"eyepiece": Rect2(336, 88, 480, 400),
	"cleaner": Rect2(376, 88, 400, 400),
	"rack": Rect2(366, 88, 420, 400),
	"pile": Rect2(276, 88, 600, 390),
	"mural": Rect2(276, 88, 600, 390)
}
const CLOSEUP_OPEN_TIME := 0.2
const CLOSEUP_CLOSE_TIME := 0.16
## S01 close-ups get an entrance of their own (a line round the edge, a glint, a map unfolding).
const S01_CLOSEUPS := ["photo", "map", "clocks", "door", "eye"]
const CLOSEUP_ANIM_TIME := {
	"chalk": 2.4, "key": 2.2, "door": 2.2, "turn": 0.9, "splat": 0.9, "eyelid": 1.6,
	"glove": 2.0, "ripple": 1.4, "pose": 0.6, "mirror_pose": 2.4, "face": 0.4, "swap": 1.6,
	"snip": 1.0, "dab": 2.8, "heads": 0.9, "giant": 2.0, "lamp": 1.4, "shovel": 1.2, "pages": 1.6,
	"sponge": 2.4, "tail": 2.2, "switch": 0.5, "kent": 2.4, "reach": 1.0, "take": 2.6, "peel": 0.8
}
const S01_HAND_SPEED := 260.0                  # Graham's hand over the photo (its own space)
const S01_HAND_START := Vector2(380, 352)

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
	"s03.pov.01",
	"s03.pov.02",
	"s03.pov.03",
	"s03.pov.04",
	"s03.pov.05",
	"s03.pov.06",
	"s03.pov.07",
	"s03.pov.08",
	"s03.pov.09",
	"s03.pov.10",
	"s03.pov.11"
]

# S04 "整间展厅是一只眼睛": 《窗》 is the pupil and the room's only light. Blue Lake (Space + Chalk)
# draws its curtain through three preset windows, like a radiologist switching window width/level:
#   cone = 全开: narrow window, high level — bright, saturated, everything holds still (the restorer's layer)
#   mid  = 半掩: dusk — both layers at half; the only light in which peripheral vision and the restorer both work
#   rod  = 全合: wide window, low level — flat grey, dim, and everything that moves shows (the visitors' layer)
const S04_PRESETS := ["cone", "mid", "rod"]
const S04_PRESET_T := {"cone": 0.0, "mid": 0.5, "rod": 1.0}
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
const S06_PIECE_NAMES := {"body": "一只大眼球", "head": "一只镜头盒", "legs_l": "一把折叠支架", "legs_r": "另一把折叠支架", "eyes": "一串小透镜"}
const S06_PIECE_FLOOR := {"body": Vector2(-24, 18), "head": Vector2(4, 34), "legs_l": Vector2(-50, 8), "legs_r": Vector2(30, 8), "eyes": Vector2(-6, 50)}
# The pile's close-up (600 × 390), seen from just behind the floor lamp: a piece at p throws its shadow
# onto the mural at LAMP + (p − LAMP)·THROW, THROW times its size. Mural space: see _cv_mural().
const S06_LAMP := Vector2(300, 430)
const S06_THROW := 1.6
const S06_FLOOR := Rect2(100, 214, 400, 166)  # where the pieces can be put down (their shadows stay on the mural)
const S06_SNAP := 20.0                         # how close (on the mural) a shadow must land to settle
const S06_SHADOW_TARGET := {"eyes": Vector2(300, 111), "head": Vector2(300, 137), "body": Vector2(300, 175), "legs_l": Vector2(246, 178), "legs_r": Vector2(354, 178)}
const S06_PIECE_START := {"body": Vector2(120, 330), "head": Vector2(470, 300), "legs_l": Vector2(430, 356), "legs_r": Vector2(150, 250), "eyes": Vector2(480, 236)}
# The lens string's eight bright spots (in shadow space): two to a window when its shadow is right.
const S06_EYE_SPOTS := [Vector2(-42, -13), Vector2(-34, -13), Vector2(34, -13), Vector2(42, -13), Vector2(-42, 13), Vector2(-34, 13), Vector2(34, 13), Vector2(42, 13)]
# The sensor's eight lenses in the fifth case (fractions of the case, from its centre): a front row
# of four with the middle pair large, a wider back row of four. Seen through the eyepiece in S05,
# marked from memory with LAN's chalk in S06.
const S06_LENS_SPOTS := [Vector2(-0.30, -0.14), Vector2(-0.10, -0.17), Vector2(0.10, -0.17), Vector2(0.30, -0.14), Vector2(-0.36, 0.16), Vector2(-0.14, 0.20), Vector2(0.14, 0.20), Vector2(0.36, 0.16)]
const S06_LENS_BIG := [false, true, true, false, false, false, false, false]
const S06_WIPE_TIME := 5.0                     # the tiny cleaner wiping the fifth case from inside
const SENSOR_CASE := Rect2(270, 132, 130, 120) # the fifth case in the rack's close-up (420 × 400)
# In the cleaner's close-up (400 × 400): where he is, by how big he looks, and the bucket.
const CLEANER_SPOT := {"giant": [Vector2(280, 190), 100.0], "normal": [Vector2(282, 150), 70.0], "tiny": [Vector2(292, 240), 34.0]}
const BUCKET_SPOT := Vector2(112, 318)
# S07: the red house's windows (0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right) are rooms.
const S07_WINDOW_ROOMS := ["s01", "s02", "s04", "hall"]
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
var s01_has_chalk := false            # handed out of the opening-day photo by the blue-eyed girl
var s01_has_key := false              # drawn on the map with the chalk, lifted off the paper
var s01_maze_path: Array[Vector2i] = []   # the chalk line on the map, from "你在这里" to the red dot
var s01_maze_adj := {}                # Vector2i -> Array of the grooves' neighbours
var s01_exit_route := ""              # "past" (the key) or "future" (rusted through)
var touch_pulse_t := -1.0              # a small ring where the hand touched (E), in the close-up's own space
var touch_pulse_at := Vector2.ZERO
var hand_drawn_frame := -10
var closeup_hand := Vector2(380, 352)   # Graham's hand over the photo, in the photo's own space
# What touching the people in the photo has changed (each shows somewhere else too):
var s01_ribbon_cut := false           # the guard cut the ribbon: a stub stays tied to the door in later eras
var s01_restorer_dab := false         # the restorer painted the ribbon (fresh red paint on 《观看的永恒》's frame too)
var s01_visitors_turned := false      # the visitors look out of the photo, faceless
var s01_cleaner_waved := false        # the cleaner grew over the roof: broom marks on the map's corner
var s01_lamp_fixed := false           # Graham fixed the lamp in winter: the hall's 出口 sign stops humming
var s01_snow_out := false             # a shovelful of snow flew out of the photo onto the hall's floor
var s01_book_open := false            # the blue book leafed through itself: a small handprint
var hyper_textures := {}
var closeup_xf := Transform2D.IDENTITY    # the close-up's current transform while it draws
var s01_eye_zoom := 0.0               # in 《这不是一只眼睛》's close-up: 0 standing back .. 1 right up close (W/S)
var s01_eyelid_seen := false
var achievements_unlocked: Array[String] = []   # platform achievements (Steam etc.), no in-game pop-up
var venus_drag := ""                  # "left"/"right": the arm LAN's chalk is dragging in Venus's close-up
var venus_pose := -1                  # index into VENUS_POSES once both arms are on
var venus_pose_prev := -1
var s02_ripple_left := 0.0            # seconds the real water under 《那喀索斯》 keeps rippling
var s03_mirror_line_pending := false
var s04_dabs: Array[Vector2] = []     # riboflavin on Graham, in the riboflavin close-up's space
var s04_girl_face := -1               # which of her faces 《戴珍珠耳机的少女》 is pulling
var s04_walk_phase := 0.0             # Graham's gait, for the point-light walker
var s04_firefly_said := false
var s04_fluor_shown := false
var s04_freeze_flash_done := false
var hyper_flash := ""                 # a hyper-real insert that cuts in over the hall itself
var hyper_flash_left := 0.0              # procedural placeholder textures for the hyper-real inserts
var s01_clocks_seen := false
var s01_face_noticed := false
var s01_idle_time := 0.0
var s01_eye_look := Vector2(910, 440) # where 《这不是一只眼睛》 is looking (world position)
var s01_eye_visits := 0
var s01_eyelid_closed := false
var s01_dark_overlay: ColorRect
var closeup := ""                     # "" or what is being looked at up close (特写)
var closeup_t := 0.0                  # 0..1 while it grows from the wall to the middle
var closeup_age := 0.0                # seconds since this close-up was opened (entrance effects)
var closeup_closing := false
var closeup_from := Rect2()           # where it hangs in the room
var closeup_anim := ""                # something happening inside the close-up
var closeup_anim_t := 0.0
var closeup_prev_era := 1             # 《观看的永恒》 slides from this era while a hand turns
var closeup_prev_melt := 0
var closeup_layer: Node2D             # drawn above Graham
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
var s03_dark_time := 0.0            # seconds in S03 without the lamp fixed (LAN points at it after a while)
const S03_LAMP_HINT_AFTER := 15.0
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
var s05_lens_pos := 2.0            # where the lens is drawn on its rail (slides toward s05_lens_notch)
var s06_drag := ""                 # the piece LAN's chalk is dragging in the pile's close-up
var s06_wipe_t := -1.0             # 0..1 while the tiny cleaner wipes the fifth case from inside
var s06_lens_marked: Array = []    # which of the eight lens spots LAN has marked in the fifth case
var s07_fish_fled := false
var mouse_t := 0.0                 # the white mouse's own clock (its little runs and peeks)
var s02_mouse_run := 0.0            # how far it has got since the belt stopped (nothing cancels it now)
var s04_mouse := ""                # "", "eating", "fleeing", "bottle", "running", "pacing"
var s04_mouse_x := 0.0
var s04_mouse_climb := 0.0          # 0..1 up the wall into 《窗》 as it escapes
var s04_mouse_seen := false        # the visitors have seen its dots run, in the dark
var s04_mouse_hint_t := 0.0
var s08_mouse := Vector2(940, 0.95)  # (near-plane x, depth z): behind the bucket
var s08_mouse_on := false
var s08_mouse_wp := 0
var s08_mouse_dir := -1.0
var s08_mouse_clock := 0.0
var s08_lost_time := 0.0
var s08_shout_t := 0.0
var s08_shout_i := 0
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
var dialogue_label: Label            # holds the whole current text (tests read it); hidden
var dialogue_view: Label             # what the player sees: one line at a time, typed out
var dlg_lines: Array = []
var dlg_index := 0
var dlg_shown := 0
var dlg_t := 0.0
var dlg_shake := 0.0
var dlg_base_pos := Vector2(230, 505)
var dlg_wait_ack := false               # a timed sequence is waiting for the player's E after the last line
var dialogue_needs_e := true         # between two lines the player presses E (tests turn this off)
var dialogue_more: Label             # the small "E ▸" when another line is waiting
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
	_build_closeup_layer()
	if LEGACY_PROTOTYPE_FLOW_ENABLED:
		_show_dialogue(_t("legacy.flow.01"))
		var tutorial_timer := get_tree().create_timer(6.0)
		tutorial_timer.timeout.connect(_hide_tutorial)
	else:
		_show_dialogue(_t("s01.arrive.01"))
		objective_label.text = _t("goal.s01.01")
		chapter_state.set_blue_lake_state(&"uninitialized")
		chapter_state.set_map_state(&"Museum_S01_Initial")
		chapter_state.mark_story_event(&"s01_started")
		chapter_state.set_player_goal(&"none")

func _process(delta: float) -> void:
	queue_redraw()
	_update_dialogue_view(delta)
	_update_chalk_hover()
	_update_interaction_hint()
	if dialogue_needs_e and _dlg_e_continues() and interaction_hint_label:
		interaction_hint_label.text = _t("hint.dialogue.more")
	_update_s01(delta)
	_update_closeup(delta)
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
	objective_label.text = _t("goal.s01.02")
	layer.add_child(objective_label)
	interaction_hint_label = Label.new()
	interaction_hint_label.position = Vector2.ZERO
	interaction_hint_label.add_theme_color_override("font_color", Color("#dff5ff"))
	interaction_hint_label.add_theme_color_override("font_shadow_color", Color("#0b1521"))
	interaction_hint_label.add_theme_constant_override("shadow_offset_x", 2)
	interaction_hint_label.add_theme_constant_override("shadow_offset_y", 2)
	interaction_hint_label.add_theme_font_size_override("font_size", 15)
	interaction_hint_label.text = _t("hint.general.01")
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
	dialogue_label.visible = false
	dialogue_view = Label.new()
	dialogue_view.position = dlg_base_pos
	dialogue_view.size = Vector2(700, 86)
	dialogue_view.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_view.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_view.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_view.add_theme_color_override("font_shadow_color", Color("#000000"))
	dialogue_view.add_theme_constant_override("shadow_offset_x", 2)
	dialogue_view.add_theme_constant_override("shadow_offset_y", 2)
	dialogue_view.add_theme_font_size_override("font_size", 19)
	layer.add_child(dialogue_view)
	dialogue_more = Label.new()
	dialogue_more.text = "E ▸"
	dialogue_more.position = dlg_base_pos + Vector2(664, 66)
	dialogue_more.add_theme_font_size_override("font_size", 13)
	dialogue_more.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	dialogue_more.visible = false
	layer.add_child(dialogue_more)
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
		# 《那喀索斯》 and its picture lamp are one close-up; so are 《机械维纳斯》 and 《光》 above her.
		{"name":"Narcissus", "position":Vector2(315,440), "radius":65.0, "hint_y":376.0},
		{"name":"SculptureVenus", "position":Vector2(528,440), "radius":50.0, "hint_y":398.0}
	]
	# S03 happens in the same hall as S02; the dead-end mirror is now the puzzle.
	# S03 happens in the same 表与里 hall as S02, with the same pieces.
	s03_interactables = s02_interactables.duplicate(true)
	s04_interactables = [
		# Left to right. The restorer is reached only from right in front of her (between her and the painting).
		{"name":"Visitor", "position":Vector2(170,440), "radius":40.0, "hint_y":258.0},
		# 《星空下的神经》, the restorer and her workbench are one close-up: 修复台.
		{"name":"Bench", "position":Vector2(430,440), "radius":95.0, "hint_y":376.0},
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
		{"name":"Eyepiece", "x":S05_RAIL_X, "z":0.02, "r":110.0, "dz":0.25, "draw":true},
		{"name":"Lens", "x":S05_RAIL_X, "z":0.34, "r":60.0, "dz":0.2, "draw":true, "inert":true},
		{"name":"Pile", "x":470.0, "z":0.62, "r":60.0, "dz":0.12, "draw":true},
		{"name":"Lamp", "x":340.0, "z":0.66, "r":30.0, "draw":true, "inert":true},
		{"name":"Rack", "x":S05_RACK_X, "z":S05_RACK_Z, "r":70.0, "dz":0.12, "draw":true},
		{"name":"Cleaner", "x":S05_CLEANER_X, "z":S05_CLEANER_Z, "r":60.0, "dz":1.0, "column":true, "draw":true},
		{"name":"Bucket", "x":940.0, "z":0.95, "r":60.0, "dz":0.12, "draw":true, "inert":true},
		{"name":"Mural", "x":560.0, "z":0.98, "r":300.0, "dz":0.06}
	]
	for plinth_room in S07_PLINTHS:
		var pl: Vector2 = S07_PLINTHS[plinth_room]
		s05_hall_items.append({"name":"Plinth_" + plinth_room, "x":pl.x, "z":pl.y, "r":40.0, "draw":true, "inert":true})
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
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), _t("sign.s01.01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d8c7a8"))
	_draw_s01_photo()
	_draw_s01_map()
	_draw_s01_clocks()
	_draw_s01_door()
	_draw_s01_not_an_eye()
	draw_string(ThemeDB.fallback_font, Vector2(112, 492), _t("sign.s01.02"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#a8957a"))
	# The shovelful of snow that flew out of the winter photo: it lies by the carpet and does not melt.
	if s01_snow_out:
		for b in [[Vector2(196, 400), 14.0], [Vector2(212, 403), 10.0], [Vector2(184, 404), 8.0]]:
			var bc: Vector2 = b[0]
			var br: float = b[1]
			draw_set_transform(bc, 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, br, Color("#f4f6f8"))
			draw_set_transform(Vector2.ZERO)
	_draw_s01_mouse()
	# What Graham is holding: the chalk from the photo, then the chalk key from the map.
	if s01_active and player and s01_has_chalk and not s01_gate_open:
		var hand := player.position + Vector2(18, 10)
		if s01_has_key:
			_s01_draw_key_shape(self, hand, Vector2(1.3, 1.6), Color("#f4f6f8"), 1.4)
		else:
			draw_rect(Rect2(hand, Vector2(7, 2.6)), Color("#f4f6f8"), true)

func _draw_s01_figure(at: Vector2, body: Color, scale_factor: float = 1.0) -> void:
	draw_circle(at, 3.2 * scale_factor, Color("#d9c3a5"))
	draw_rect(Rect2(at.x - 3.5 * scale_factor, at.y + 3.0 * scale_factor, 7.0 * scale_factor, 11.0 * scale_factor), body, true)

func _draw_s01_photo() -> void:
	var r := S01_PHOTO_RECT
	draw_rect(r, Color("#c9ae78"), true)
	var inner := r.grow(-8.0)
	var tone: Color = [Color("#8a7350"), Color("#a9bac4"), Color("#5f6466")][s01_era]
	# Outside the museum: the red house (the same house as the mural behind 《窗》), photographed
	# from the street.
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
	var door := Rect2(inner.position + Vector2(52, 28), Vector2(20, 34))
	draw_rect(door, Color("#7a4a30") if s01_era == 2 else Color("#2c3640"), true)
	var floor_y := inner.end.y - 10.0
	draw_line(Vector2(inner.position.x, floor_y + 4.0), Vector2(inner.end.x, floor_y + 4.0), tone.darkened(0.3), 1.0)
	if s01_era == 0:
		# Opening day: the guard with the big scissors; the restorer and the visitor are in the crowd.
		_draw_s01_figure(Vector2(door.end.x + 9.0, floor_y - 14.0), Color("#566b7a"))
		_draw_s01_figure(Vector2(inner.position.x + 14.0, floor_y - 14.0), Color("#b26b5e"))
		_draw_s01_figure(Vector2(inner.position.x + 30.0, floor_y - 14.0), Color("#6c8290"))
		for i in range(3):
			_draw_s01_figure(Vector2(inner.end.x - 28.0 + i * 9.0, floor_y - 13.0), Color("#7a6a5a"), 0.9)
		if s01_visitors_turned:
			# They look out of the photo now: pale, featureless faces.
			for vx in [inner.position.x + 30.0, inner.end.x - 28.0, inner.end.x - 19.0, inner.end.x - 10.0]:
				draw_circle(Vector2(vx, floor_y - 14.0), 2.6, Color("#f3e8d6"))
		draw_string(ThemeDB.fallback_font, inner.position + Vector2(4, 12), "OPENING", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.35, 0.2, 0.1, 0.8))
		# Cutting the ribbon in front of the red house.
		if s01_ribbon_cut:
			if not s01_has_chalk:
				draw_line(Vector2(inner.position.x + 8, door.position.y + 20), Vector2(door.get_center().x - 2, door.position.y + 26), Color("#d8202a"), 2.0)
			draw_line(Vector2(inner.end.x - 8, door.position.y + 20), Vector2(door.get_center().x + 2, door.position.y + 26), Color("#d8202a"), 2.0)
		elif s01_restorer_dab:
			draw_line(Vector2(inner.position.x + 8, door.position.y + 20), Vector2(inner.end.x - 8, door.position.y + 20), Color("#d8202a"), 2.0)
			draw_circle(Vector2(door.get_center().x, door.position.y + 20), 3.0, Color("#d8202a"))
		# Blue Lake was already here, years ago, in another form: a small girl with blue eyes in the crowd.
		_draw_s01_blue_lake_trace(Vector2(inner.position.x + 43.0, floor_y - 9.0), 0)
	elif s01_era == 1:
		# Winter: snow falling, coats, and someone up a ladder fixing the lamp over the door.
		draw_rect(Rect2(inner.position.x, floor_y + 4.0, inner.size.x, 4.0), Color("#f4f6f8"), true)
		if s01_lamp_fixed:
			draw_circle(Vector2(door.get_center().x, door.position.y - 3.0), 5.0, Color(1.0, 0.92, 0.6, 0.6))
		var ladder_x := inner.end.x - 22.0
		draw_line(Vector2(ladder_x, floor_y + 3.0), Vector2(ladder_x + 6.0, inner.position.y + 20.0), Color("#5b4a3a"), 1.5)
		draw_line(Vector2(ladder_x + 10.0, floor_y + 3.0), Vector2(ladder_x + 12.0, inner.position.y + 20.0), Color("#5b4a3a"), 1.5)
		draw_rect(Rect2(ladder_x + 2.0, inner.position.y + 4.0, 12, 4), Color("#f4e7b8"), true)
		_draw_s01_figure(Vector2(ladder_x + 8.0, inner.position.y + 14.0), Color("#4b79a8"), 0.9)
		_draw_s01_figure(Vector2(inner.position.x + 20.0, floor_y - 14.0), Color("#3b3f46"))
		# ...a white bear with blue eyes, left on the floor under the window.
		_draw_s01_blue_lake_trace(Vector2(inner.position.x + 40.0, floor_y), 1)
	else:
		# Many years later: nobody, dust, a cobweb in the corner, the door boarded up.
		for i in range(14):
			draw_circle(inner.position + Vector2((i * 37) % int(inner.size.x), (i * 23) % int(inner.size.y)), 0.9, Color(1, 1, 1, 0.35))
		draw_arc(inner.position + Vector2(18, 14), 9.0, 0.0, TAU, 16, Color(0.45, 0.33, 0.18, 0.5), 1.0)
		draw_arc(inner.end - Vector2(20, 22), 12.0, 0.0, TAU, 16, Color(0.45, 0.33, 0.18, 0.45), 1.0)
		draw_line(door.position + Vector2(0, 8), door.end - Vector2(0, 10), Color("#a88a62"), 2.0)
		# ...a book with a blue cover and white pages, the only thing left in the empty hall.
		_draw_s01_blue_lake_trace(Vector2(inner.position.x + 30.0, floor_y + 1.0), 2)
		if s01_book_open:
			draw_rect(Rect2(Vector2(inner.position.x + 26.0, floor_y - 3.0), Vector2(8, 3)), Color("#f4f6f8"), true)
	if s01_ribbon_cut and s01_era > 0:
		draw_line(door.end - Vector2(4, 18), door.end - Vector2(3, 10), Color("#b2433a"), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 2, 340), _t("sign.s01.03"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))

## Blue Lake hides in every chapter as something white-and-blue that can become something else.
## In the S01 photo: a blue-eyed girl (opening day), a white bear (winter), a blue book (years later).
## No dialogue points at them; they are there to be noticed, now or on a later visit.
## Only the girl has hands: she is the one who can pass Graham the chalk.
func _draw_s01_blue_lake_trace(at: Vector2, form: int) -> void:
	var blue := Color("#2f86e0")
	if form == 0:
		draw_circle(at, 2.6, Color("#d9c3a5"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-2.5, 2.5), at + Vector2(2.5, 2.5), at + Vector2(4.0, 10.0), at + Vector2(-4.0, 10.0)]), Color("#f4f6f8"))
		draw_rect(Rect2(at + Vector2(-1.6, -0.6), Vector2(1.2, 1.2)), blue, true)
		draw_rect(Rect2(at + Vector2(0.6, -0.6), Vector2(1.2, 1.2)), blue, true)
		if not s01_has_chalk:
			draw_rect(Rect2(at + Vector2(3.5, 1.0), Vector2(3.2, 1.3)), Color.WHITE, true)
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
	# Whatever was drawn in the close-up shows here too: the chalk line, where the red dot stopped,
	# and later the key-shaped blank where the key came off the paper.
	_s01_draw_map_on(self, S01_MAZE_ROOM_AREA, false)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 2, 340), _t("sign.s01.04"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))

## The clock-eyes. Each painting keeps the photo's era: warm, snowing, or grey with dust.
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
	var bg: Color = S01_CLOCK_SKY[s01_era]
	var ground: Color = S01_CLOCK_GROUND[s01_era]
	draw_rect(inner, bg, true)
	draw_rect(Rect2(inner.position.x, inner.end.y - 26.0, inner.size.x, 26.0), ground, true)
	draw_line(Vector2(inner.position.x + 60, inner.end.y - 26), Vector2(inner.position.x + 120, inner.position.y + 30), Color("#4f5d60"), 5.0)
	if s01_era == 1:
		for corner in [inner.position, Vector2(inner.end.x, inner.position.y)]:
			for k in range(3):
				var dir: Vector2 = (inner.get_center() - corner).normalized().rotated((k - 1) * 0.35)
				draw_line(corner, corner + dir * 16.0, Color(0.93, 0.97, 1.0, 0.8), 1.0)
	elif s01_era == 2:
		draw_polyline(PackedVector2Array([inner.position + Vector2(130, 0), inner.position + Vector2(122, 30), inner.position + Vector2(136, 52), inner.position + Vector2(128, 94)]), Color(0.15, 0.15, 0.15, 0.6), 1.0)
	_draw_s01_clock_eye(S01_CLOCK_BACK, _s01_left_turns(s01_era), 0)
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
	if s01_restorer_dab:
		draw_line(r.position + Vector2(4, r.size.y - 4), r.position + Vector2(26, r.size.y - 7), Color(0.85, 0.13, 0.16, 0.95), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 44, 318), _t("sign.s01.05"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))

func _s01_left_turns(era: int) -> int:
	return -(1 - era) if era <= 1 else 0

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
	_draw_s01_sign()

## The "出口" sign over the door is the face's nose. It ages with the clock-eyes: brand new and
## glaring on opening day, humming in winter, dark and hanging crooked years later, and once the
## eye has melted onto the floor it falls down too.
func _draw_s01_sign() -> void:
	var s := S01_SIGN
	var font := ThemeDB.fallback_font
	if s01_melt >= 2:
		draw_line(s + Vector2(-10, -12), s + Vector2(-10, -7), Color("#6d6250"), 1.5)
		var fallen := PackedVector2Array([Vector2(732, 376), Vector2(764, 370), Vector2(766, 382), Vector2(734, 388)])
		draw_colored_polygon(fallen, Color("#2f3f35"))
		draw_polyline(PackedVector2Array([fallen[0], fallen[1], fallen[2], fallen[3], fallen[0]]), Color("#56604f"), 1.0)
		return
	if s01_era == 2:
		# One chain left: it hangs from its left corner.
		draw_line(s + Vector2(-14, -12), s + Vector2(-14, -7), Color("#6d6250"), 1.5)
		var pivot := s + Vector2(-16, -8)
		var pts := PackedVector2Array()
		for corner in [Vector2(0, 0), Vector2(32, 0), Vector2(32, 16), Vector2(0, 16)]:
			pts.append(pivot + corner.rotated(0.38))
		draw_colored_polygon(pts, Color("#2f3f35"))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("#56604f"), 1.0)
		return
	var glow := 0.22 if s01_era == 0 else 0.12
	if s01_era == 1 and not s01_lamp_fixed:
		# Humming and flickering, until Graham fixes the lamp in the winter photo.
		glow *= 0.6 + 0.4 * absf(sin(Time.get_ticks_msec() * 0.023) * sin(Time.get_ticks_msec() * 0.007))
	draw_circle(s, 30.0 if s01_era == 0 else 20.0, Color(0.35, 1.0, 0.55, glow * 0.6))
	draw_circle(s, 18.0, Color(0.35, 1.0, 0.55, glow))
	for cx in [-12.0, 12.0]:
		draw_line(s + Vector2(cx, -14), s + Vector2(cx, -8), Color("#8d7b5c"), 1.5)
	draw_rect(Rect2(s - Vector2(16, 8), Vector2(32, 16)), Color("#3fdc7a") if s01_era == 0 else Color("#2fae5f"), true)
	draw_string(font, s + Vector2(-11, 5), _t("sign.s01.06"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

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
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 22, r.end.y - 14), _t("sign.s01.07"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8e2d0"))
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x - 6, 318), _t("sign.s01.08"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8dfc8"))

## --- The map, drawn on any canvas (the small one on the wall, or the close-up) -----------------
func _s01_maze_pos(n: Vector2i, area: Rect2) -> Vector2:
	return area.position + Vector2(n.x * area.size.x / 12.0, n.y * area.size.y / 6.0)

func _s01_ring(c: Vector2, rx: float, ry: float, n: int = 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var a := TAU * i / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

## The key: the round gyrus around "你在这里" is the bow, the solved path is the blade and the teeth.
## `origin` is where the blade's tip (the goal) sits; `cell` is one maze step.
func _s01_draw_key_shape(ci: CanvasItem, origin: Vector2, cell: Vector2, color: Color, width: float, angle: float = 0.0) -> void:
	var path: Array = S01_MAZE_PATHS[0]
	var pts := PackedVector2Array()
	for node in path:
		var n: Vector2i = node
		pts.append(origin + (Vector2(n.x - S01_MAZE_GOAL.x, n.y - S01_MAZE_GOAL.y) * cell).rotated(angle))
	ci.draw_polyline(pts, color, width)
	var bow := _s01_ring(Vector2.ZERO, cell.x * 0.75, cell.y * 0.85, 20)
	var bow_center := Vector2(S01_MAZE_START.x - S01_MAZE_GOAL.x + 0.25, 0) * cell
	for i in range(bow.size()):
		bow[i] = origin + (bow_center + bow[i]).rotated(angle)
	ci.draw_polyline(bow, color, width)

func _s01_draw_map_on(ci: CanvasItem, area: Rect2, big: bool) -> void:
	var cell := Vector2(area.size.x / 12.0, area.size.y / 6.0)
	var ink := Color("#6b5a44")
	var center := area.get_center()
	# The outline of the brain, a little bumpy, with the cerebellum tucked under the back.
	var outline := PackedVector2Array()
	for i in range(48):
		var a := TAU * i / 48.0
		var wob := 1.0 + 0.035 * sin(a * 9.0)
		outline.append(center + Vector2(cos(a) * (area.size.x * 0.5 + cell.x * 0.95) * wob, sin(a) * (area.size.y * 0.5 + cell.y * 0.95) * wob))
	var back := center + Vector2(area.size.x * 0.36, area.size.y * 0.52)
	if big:
		var lobe := _s01_ring(back, cell.x * 1.6, cell.y * 1.0, 24)
		lobe.remove_at(lobe.size() - 1)
		ci.draw_colored_polygon(lobe, Color("#d8ccaa"))
		ci.draw_polyline(_s01_ring(back, cell.x * 1.6, cell.y * 1.0, 24), ink, 2.0)
	ci.draw_colored_polygon(outline, Color("#e6dcc0"))
	var closed := outline.duplicate()
	closed.append(outline[0])
	ci.draw_polyline(closed, ink, 3.0 if big else 1.5)
	# The sulci: the maze's grooves.
	var groove_w := cell.y * 0.42 if big else 1.4
	for node in s01_maze_adj:
		var a: Vector2i = node
		for other in s01_maze_adj[a]:
			var b: Vector2i = other
			if a.x < b.x or (a.x == b.x and a.y < b.y):
				ci.draw_line(_s01_maze_pos(a, area), _s01_maze_pos(b, area), Color("#b8a47c") if big else Color(0.42, 0.35, 0.27, 0.5), groove_w)
	if big:
		for node in s01_maze_adj:
			var p := _s01_maze_pos(node, area)
			ci.draw_circle(p, groove_w * 0.5, Color("#b8a47c"))
	# The round gyrus around "你在这里" (printed; it becomes the key's bow).
	var start := _s01_maze_pos(S01_MAZE_START, area)
	var bow := _s01_ring(start + Vector2(cell.x * 0.25, 0), cell.x * 0.75, cell.y * 0.85)
	ci.draw_polyline(bow, Color("#b8a47c") if big else Color(0.42, 0.35, 0.27, 0.5), groove_w)
	var font := ThemeDB.fallback_font
	var goal := _s01_maze_pos(S01_MAZE_GOAL, area)
	if big:
		ci.draw_string(font, start + Vector2(-34, -cell.y * 1.05), _t("sign.s01.09"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8a2a24"))
		ci.draw_string(font, goal + Vector2(-cell.x * 0.95, -cell.y * 0.7), _t("sign.s01.06"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
		ci.draw_line(goal + Vector2(-cell.x * 0.85, -cell.y * 0.5), goal + Vector2(-cell.x * 0.2, -cell.y * 0.1), ink, 1.5)
	else:
		ci.draw_line(goal + Vector2(-3, -3), goal + Vector2(-1, -1), ink, 1.0)
	# The cleaner grew over the roof in the opening-day photo: his broom swept the map's corner.
	if s01_cleaner_waved:
		var corner := area.end + cell * Vector2(0.4, 0.2)
		for k in range(4):
			ci.draw_line(corner + Vector2(-k * cell.x * 0.18, 0), corner + Vector2(-k * cell.x * 0.18 - cell.x * 0.5, cell.y * 0.35), Color(0.42, 0.35, 0.27, 0.6), 2.0 if big else 0.8)
	# What has been drawn on it.
	var lifted := s01_has_key or (closeup == "map" and closeup_anim == "key" and closeup_anim_t > 0.35)
	var dot := goal
	if lifted:
		# The key came off the paper and left its shape behind, blank.
		_s01_draw_key_shape(ci, goal, cell, Color("#f8f3e3"), cell.y * 0.5 if big else 2.4)
	else:
		var chalk := PackedVector2Array()
		for node in s01_maze_path:
			chalk.append(_s01_maze_pos(node, area))
		if chalk.size() >= 2:
			ci.draw_polyline(chalk, Color("#fbfbf7"), cell.y * 0.16 if big else 1.2)
		dot = chalk[chalk.size() - 1]
	var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.006) if big else 1.0
	ci.draw_circle(dot, (cell.y * 0.26 if big else 2.6) * pulse, Color("#c4372f"))
	if big and _s01_maze_active():
		ci.draw_arc(dot, cell.y * 0.42 * pulse, 0.0, TAU, 20, Color(0.77, 0.22, 0.18, 0.5), 2.0)

## --- Close-up drawing ---------------------------------------------------------------------------
## Drawn on its own layer above Graham. The content of each close-up is drawn in its own space
## (0..size), and that space is scaled from where the thing hangs to the middle of the screen.
func _draw_closeup() -> void:
	var cv: CanvasItem = closeup_layer
	_draw_point_light(cv)
	if closeup == "":
		_draw_hyperreal(cv)
		return
	# Opening: fast out, then settles (ease-out); closing: smooth.
	var e := closeup_t * closeup_t * (3.0 - 2.0 * closeup_t)
	if not closeup_closing:
		e = 1.0 - pow(1.0 - closeup_t, 3.0)
	cv.draw_rect(Rect2(0, 58, 1152, 590), Color(0.02, 0.03, 0.05, 0.8 * e), true)
	var kind := _closeup_kind()
	var target: Rect2 = CLOSEUP_RECTS[kind]
	var cur := Rect2(closeup_from.position.lerp(target.position, e), closeup_from.size.lerp(target.size, e))
	closeup_xf = Transform2D(0.0, cur.size / target.size, 0.0, cur.position)
	cv.draw_set_transform_matrix(closeup_xf)
	var sz := target.size
	match kind:
		"photo":
			_draw_closeup_photo(cv, sz)
		"map":
			_draw_closeup_map(cv, sz)
		"clocks":
			_draw_closeup_clocks(cv, sz)
		"door":
			_draw_closeup_door(cv, sz)
		"eye":
			_draw_closeup_eye(cv, sz)
		"guard":
			_draw_closeup_guard(cv, sz)
		"narcissus":
			_draw_closeup_narcissus(cv, sz)
		"venus":
			_draw_closeup_venus(cv, sz)
		"lan":
			_draw_closeup_lan(cv, sz)
		"bench":
			_draw_closeup_bench(cv, sz)
		"smear":
			_draw_closeup_smear(cv, sz)
		"girl":
			_draw_closeup_s04_girl(cv, sz)
		"window":
			_draw_closeup_window(cv, sz)
		"visitor":
			_draw_closeup_visitor(cv, sz)
		"twins":
			_draw_closeup_twins(cv, sz)
		"swap":
			_draw_closeup_swap(cv, sz)
		"eyepiece":
			_draw_closeup_eyepiece(cv, sz)
		"cleaner":
			_draw_closeup_cleaner(cv, sz)
		"rack":
			_draw_closeup_rack(cv, sz)
		"pile":
			_draw_closeup_pile(cv, sz)
		"mural":
			_draw_closeup_mural(cv, sz)
	if not closeup_closing:
		_draw_s01_entrance(cv, kind, sz)
	cv.draw_set_transform(Vector2.ZERO)
	_draw_hyperreal(cv)

## --- S01 close-up entrances (2026-11-09, user): quick, one gesture each --------------------------
## Composition: each close-up gets one line or one plane that moves, nothing stacked.
## All: a hairline runs once round the edge as it opens, then fades (the eye is led to the frame).
## Photo: a light band slides across the glass, and now and then a faint one again.
## Map: it unfolds, panel by panel; the creases stay faintly on the paper.
func _draw_s01_entrance(cv: CanvasItem, kind: String, sz: Vector2) -> void:
	var a := closeup_age
	var m := minf(sz.x, sz.y)
	# The hairline (blue when it is LAN who is looking).
	var line_color := Color(0.62, 0.82, 1.0) if kind == "lan" else Color(1, 1, 1)
	if a < 0.6:
		var k := clampf(a / 0.3, 0.0, 1.0)
		var fade := 1.0 - clampf((a - 0.3) / 0.3, 0.0, 1.0)
		var corners := [Vector2.ZERO, Vector2(sz.x, 0), sz, Vector2(0, sz.y), Vector2.ZERO]
		var total := 2.0 * (sz.x + sz.y)
		var left := total * k
		for i in range(4):
			var p0: Vector2 = corners[i]
			var p1: Vector2 = corners[i + 1]
			var seg := p0.distance_to(p1)
			if left <= 0.0:
				break
			var end := p1 if left >= seg else p0.lerp(p1, left / seg)
			cv.draw_line(p0, end, Color(line_color, 0.75 * fade), 1.5)
			left -= seg
	match kind:
		# --- the other halls (2026-11-10, user): one gesture each, nothing stacked ---
		"narcissus":
			# Light runs once along the water at the foot of the frame.
			if a > 0.1 and a < 0.75:
				var g := (a - 0.1) / 0.65
				var fade := sin(g * PI)
				var x := sz.x * (1.0 - pow(1.0 - g, 2.0))
				var y := sz.y * 0.9
				cv.draw_line(Vector2(maxf(0.0, x - 90.0), y), Vector2(x, y), Color(1, 1, 1, 0.5 * fade), 2.0)
				cv.draw_line(Vector2(maxf(0.0, x - 50.0), y + 6.0), Vector2(minf(sz.x, x + 20.0), y + 6.0), Color(1, 1, 1, 0.25 * fade), 1.0)
		"venus":
			# A line of light drops down her axis, from where the prism hangs.
			if a < 0.6:
				var g := 1.0 - pow(1.0 - clampf(a / 0.35, 0.0, 1.0), 2.0)
				var fade := 1.0 - clampf((a - 0.35) / 0.25, 0.0, 1.0)
				cv.draw_line(Vector2(sz.x * 0.5, 0), Vector2(sz.x * 0.5, sz.y * g), Color(1, 1, 1, 0.45 * fade), 1.5)
		"girl":
			# A framed painting: light slides over the varnish.
			var canvas := Rect2(Vector2(14, 14), sz - Vector2(28, 28))
			if a > 0.12 and a < 0.7:
				var g := (a - 0.12) / 0.58
				_draw_glint(cv, canvas, lerpf(canvas.position.x - 120.0, canvas.end.x + canvas.size.y * 0.5, 1.0 - pow(1.0 - g, 2.0)), 40.0, 0.16)
		"window":
			# 《窗》: two curtains part.
			if a < 0.3:
				var g := 1.0 - pow(1.0 - a / 0.3, 3.0)
				var half := sz.x * 0.5 * (1.0 - g)
				var cloth := Color(0.09, 0.08, 0.07, 0.88)
				cv.draw_rect(Rect2(0, 0, half, sz.y), cloth, true)
				cv.draw_rect(Rect2(sz.x - half, 0, half, sz.y), cloth, true)
				cv.draw_line(Vector2(half, 0), Vector2(half, sz.y), Color(1, 1, 1, 0.35), 1.5)
				cv.draw_line(Vector2(sz.x - half, 0), Vector2(sz.x - half, sz.y), Color(1, 1, 1, 0.35), 1.5)
		"bench", "eyepiece":
			# Looking closely: a ring draws in to the middle and is gone.
			if a < 0.45:
				var g := 1.0 - pow(1.0 - a / 0.45, 3.0)
				cv.draw_arc(sz * 0.5, lerpf(m * 0.46, m * 0.1, g), 0.0, TAU, 56, Color(1, 1, 1, 0.5 * (1.0 - g)), 1.5)
		"visitor":
			# They come up out of the dark.
			if a < 0.5:
				cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.8 * (1.0 - a / 0.5)), true)
		"twins":
			# One half, then the other.
			if a < 0.42:
				var left := 0.75 * (1.0 - clampf(a / 0.24, 0.0, 1.0))
				var right := 0.75 * (1.0 - clampf((a - 0.14) / 0.28, 0.0, 1.0))
				cv.draw_rect(Rect2(0, 0, sz.x * 0.5, sz.y), Color(0, 0, 0, left), true)
				cv.draw_rect(Rect2(sz.x * 0.5, 0, sz.x * 0.5, sz.y), Color(0, 0, 0, right), true)
		"rack":
			# The sight chart: a line reads down the rows.
			if a < 0.55:
				var g := a / 0.55
				var y := sz.y * (1.0 - pow(1.0 - g, 2.0))
				cv.draw_line(Vector2(0, y), Vector2(sz.x, y), Color(1, 1, 1, 0.4 * sin(g * PI)), 1.5)
		"pile":
			# The floor lamp behind: a breath of warm light.
			if a < 0.35:
				cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(1.0, 0.9, 0.7, 0.2 * (1.0 - a / 0.35)), true)
		"mural":
			# A shadow passes over the wall, once.
			if a > 0.1 and a < 0.7:
				var g := (a - 0.1) / 0.6
				var wall := Rect2(Vector2.ZERO, sz)
				var band := PackedVector2Array([Vector2(lerpf(-140.0, sz.x + sz.y * 0.5, g), 0), Vector2(lerpf(-140.0, sz.x + sz.y * 0.5, g) + 70.0, 0), Vector2(lerpf(-140.0, sz.x + sz.y * 0.5, g) + 70.0 - sz.y * 0.5, sz.y), Vector2(lerpf(-140.0, sz.x + sz.y * 0.5, g) - sz.y * 0.5, sz.y)])
				var box := PackedVector2Array([wall.position, Vector2(wall.end.x, 0), wall.end, Vector2(0, wall.end.y)])
				for poly in Geometry2D.intersect_polygons(band, box):
					cv.draw_colored_polygon(poly, Color(0, 0, 0, 0.14))
		"photo":
			var glass := Rect2(Vector2(18, 18), sz - Vector2(36, 36))
			if a > 0.12 and a < 0.7:
				var g := (a - 0.12) / 0.58
				var x := lerpf(glass.position.x - 120.0, glass.end.x + glass.size.y * 0.5, 1.0 - pow(1.0 - g, 2.0))
				_draw_glint(cv, glass, x, 46.0, 0.22)
				_draw_glint(cv, glass, x + 64.0, 10.0, 0.16)
			# Now and then, faintly.
			var cycle := fmod(a + 3.0, 7.5)
			if cycle < 0.9 and a > 1.0:
				var x2 := lerpf(glass.position.x - 80.0, glass.end.x + glass.size.y * 0.5, cycle / 0.9)
				_draw_glint(cv, glass, x2, 30.0, 0.09)
		"map":
			var panels := 4
			var pw := sz.x / panels
			var paper_back := Color("#d6caa8")
			for i in range(panels):
				var p := clampf((a - 0.05 - i * 0.07) / 0.18, 0.0, 1.0)
				p = 1.0 - pow(1.0 - p, 3.0)
				var x0 := i * pw
				# The crease, faintly, for good.
				if i > 0:
					cv.draw_line(Vector2(x0, 0), Vector2(x0, sz.y), Color(0, 0, 0, 0.10), 1.0)
					cv.draw_line(Vector2(x0 + 1.5, 0), Vector2(x0 + 1.5, sz.y), Color(1, 1, 1, 0.12), 1.0)
				if p < 1.0:
					var cover := Rect2(x0 + pw * p, 0, pw * (1.0 - p) + 1.0, sz.y)
					cv.draw_rect(cover, paper_back.darkened(0.08 * float(i % 2)), true)
					cv.draw_line(Vector2(cover.position.x, 0), Vector2(cover.position.x, sz.y), Color(0, 0, 0, 0.35), 2.0)
			cv.draw_line(Vector2(0, sz.y * 0.5), Vector2(sz.x, sz.y * 0.5), Color(0, 0, 0, 0.08), 1.0)
			cv.draw_line(Vector2(0, sz.y * 0.5 + 1.5), Vector2(sz.x, sz.y * 0.5 + 1.5), Color(1, 1, 1, 0.10), 1.0)

## A slanted band of light across `area`, clipped to it.
func _draw_glint(cv: CanvasItem, area: Rect2, x: float, w: float, alpha: float) -> void:
	var h := area.size.y
	var band := PackedVector2Array([Vector2(x, area.position.y), Vector2(x + w, area.position.y), Vector2(x + w - h * 0.5, area.end.y), Vector2(x - h * 0.5, area.end.y)])
	var box := PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)])
	for poly in Geometry2D.intersect_polygons(band, box):
		cv.draw_colored_polygon(poly, Color(1, 1, 1, alpha))

## A person in the photo. `facing_out`: the face turned toward the viewer (blank, no features);
## otherwise they are seen from behind, looking at the door.
func _cv_figure(cv: CanvasItem, head: Vector2, body: Color, k: float, facing_out: bool = false) -> void:
	cv.draw_rect(Rect2(head.x - 3.5 * k, head.y + 3.0 * k, 7.0 * k, 11.0 * k), body, true)
	if facing_out:
		cv.draw_circle(head, 3.2 * k, Color("#e6d3b8"))
	else:
		cv.draw_circle(head, 3.2 * k, Color("#d9c3a5"))
		cv.draw_arc(head + Vector2(0, -0.4 * k), 3.0 * k, PI * 0.9, PI * 2.1, 10, Color("#5b4a3a"), 1.6 * k)

func _s01_highlight(cv: CanvasItem, id: String) -> void:
	if closeup_anim != "" or _s01_photo_spot_at(closeup_hand) != id:
		return
	for spot in _s01_photo_spots():
		if spot.id == id:
			var pos: Vector2 = spot.pos
			var r: float = spot.r
			# Viewfinder corners (it's a photograph), breathing a little.
			var d := r + 2.0 * sin(Time.get_ticks_msec() * 0.008)
			var arm := d * 0.45
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					var c := pos + Vector2(sx * d, sy * d)
					cv.draw_line(c, c - Vector2(sx * arm, 0), Color(1, 1, 1, 0.7), 2.0)
					cv.draw_line(c, c - Vector2(0, sy * arm), Color(1, 1, 1, 0.7), 2.0)

func _draw_closeup_photo(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var era := s01_era
	var t := closeup_anim_t
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#c9ae78"), true)
	cv.draw_rect(Rect2(Vector2(6, 6), sz - Vector2(12, 12)), Color("#a88a56"), false, 2.0)
	var inner := Rect2(Vector2(18, 18), sz - Vector2(36, 36))
	var sky: Color = [Color("#c9d8c6"), Color("#dde6ea"), Color("#7d8284")][era]
	var wall: Color = [Color("#b0503a"), Color("#a2685c"), Color("#6e5650")][era]
	var tone: Color = [Color("#8a7350"), Color("#a9bac4"), Color("#5f6466")][era]
	var ground_y := 330.0
	cv.draw_rect(inner, sky, true)
	cv.draw_rect(Rect2(inner.position.x, ground_y, inner.size.x, inner.end.y - ground_y), tone.lightened(0.2), true)
	# The red house: four windows and a door (the same house as the mural behind 《窗》).
	var facade := Rect2(150, 120, 220, ground_y - 120)
	cv.draw_rect(facade, wall, true)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(136, 122), Vector2(384, 122), Vector2(260, 54)]), wall.darkened(0.35))
	for wp in [Vector2(172, 145), Vector2(318, 145), Vector2(172, 205), Vector2(318, 205)]:
		cv.draw_rect(Rect2(wp, Vector2(30, 28)), Color("#f4e7b8").lerp(tone, 0.4), true)
		cv.draw_line(wp + Vector2(15, 0), wp + Vector2(15, 28), wall.darkened(0.4), 2.0)
	var door := Rect2(238, 248, 44, ground_y - 248)
	cv.draw_rect(door, Color("#7a4a30") if era == 2 else Color("#2c3640"), true)
	# The lamp over the door: Graham is fixing it in winter.
	var lamp_on := era == 0 or (era == 1 and (s01_lamp_fixed or (closeup_anim == "lamp" and t > 0.5)))
	if lamp_on:
		cv.draw_circle(Vector2(260, 238), 22.0, Color(1.0, 0.92, 0.6, 0.35))
	cv.draw_rect(Rect2(250, 234, 20, 9), Color("#fff2b8") if lamp_on else (Color("#8a8574") if era != 2 else Color("#6b6658")), true)
	if s01_ribbon_cut and era > 0:
		# What is left of the cut ribbon, tied to the door handle all these years.
		cv.draw_line(Vector2(276, 292), Vector2(280, 318), Color("#c23a32").lerp(tone, 0.35 * era), 3.0)
	match era:
		0:
			_draw_closeup_photo_opening(cv, ground_y, t)
		1:
			_draw_closeup_photo_winter(cv, ground_y, inner, t)
		_:
			_draw_closeup_photo_later(cv, ground_y, inner, door, t)
	_draw_closeup_hand(cv)
	cv.draw_string(font, Vector2(sz.x * 0.5 - 70, -10), _t("sign.s01.03"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _draw_closeup_photo_opening(cv: CanvasItem, ground_y: float, t: float) -> void:
	var font := ThemeDB.fallback_font
	cv.draw_string(font, Vector2(28, 40), "OPENING", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.35, 0.2, 0.1, 0.8))
	# No ribbon at first: the restorer paints it across the door, the guard's big scissors cut it,
	# and the girl (LAN) plays with what is left.
	var cut := s01_ribbon_cut or (closeup_anim == "snip" and t > 0.45)
	var red := Color("#d8202a")
	# The restorer walks across the door painting the ribbon as she goes, then walks back.
	var rx := 70.0
	var walking := false
	if closeup_anim == "dab":
		if t < 0.65:
			rx = lerpf(70.0, 392.0, smoothstep(0.0, 1.0, t / 0.65))
			walking = true
		else:
			rx = lerpf(392.0, 70.0, smoothstep(0.0, 1.0, (t - 0.65) / 0.35))
	var reach := 0.0
	if s01_restorer_dab:
		reach = 1.0
	elif closeup_anim == "dab":
		reach = 1.0 if not walking else clampf((rx + 28.0 - 110.0) / 300.0, 0.0, 1.0)
	if cut:
		var fall := 1.0 if s01_ribbon_cut else clampf((t - 0.45) / 0.4, 0.0, 1.0)
		if not s01_has_chalk and not (closeup_anim == "chalk"):
			cv.draw_line(Vector2(110, 296), Vector2(254, 296 + 30 * fall), red, 4.0)
		cv.draw_line(Vector2(410, 296), Vector2(266, 296 + 30 * fall), red, 4.0)
	elif reach > 0.0:
		cv.draw_line(Vector2(110, 296), Vector2(110 + 300.0 * reach, 296), red, 4.0)
		if reach >= 1.0:
			cv.draw_circle(Vector2(260, 296), 7.0, red)
	var turned := s01_visitors_turned or (closeup_anim == "heads" and t > 0.5)
	# The guard, with the big scissors.
	_cv_figure(cv, Vector2(320, ground_y - 50), Color("#566b7a"), 3.6)
	var open_a := 0.35
	if closeup_anim == "snip":
		open_a = 0.35 * absf(cos(t * PI * 1.0))
	elif s01_ribbon_cut:
		open_a = 0.0
	var pivot := Vector2(300, 296) if (closeup_anim == "snip" or not s01_ribbon_cut) else Vector2(326, 270)
	for sgn in [-1.0, 1.0]:
		cv.draw_line(pivot + Vector2(28, 0).rotated(sgn * open_a), pivot - Vector2(18, 0).rotated(sgn * open_a), Color("#9aa3a8"), 3.0)
	cv.draw_circle(pivot - Vector2(20, 0), 3.0, Color("#3b3f46"))
	_s01_highlight(cv, "guard")
	# The restorer, brush in hand; touched, she walks across the door painting the ribbon, and back.
	var dab_k := 0.0
	var bob := 0.0
	if closeup_anim == "dab":
		dab_k = sin(clampf(t, 0.0, 1.0) * PI)
		bob = -absf(sin(t * TAU * 5.0)) * 3.0
	_cv_figure(cv, Vector2(rx, ground_y - 50 + bob), Color("#b26b5e"), 3.6)
	var brush := Vector2(rx + 26, 282)
	if walking:
		brush = Vector2(rx + 28, 294)
	cv.draw_line(Vector2(rx + 14, 300 + bob), brush, Color("#7a5a3a"), 2.0 + 1.0 * dab_k)
	cv.draw_circle(brush, 3.0, red if (closeup_anim == "dab" or s01_restorer_dab) else Color("#7a5a3a"))
	_s01_highlight(cv, "restorer")
	# The visitors look at the door; touched, they all turn to look out of the photo, faceless.
	_cv_figure(cv, Vector2(112, ground_y - 50), Color("#6c8290"), 3.6, turned)
	for i in range(3):
		_cv_figure(cv, Vector2(400.0 + i * 24.0, ground_y - 46), Color("#7a6a5a"), 3.2, turned)
	_s01_highlight(cv, "visitors")
	# The cleaner, sweeping. Touched, he doesn't look up: three hard strokes, the dust flies to the corner.
	var sweep := 0.0
	var dust := 0.0
	if closeup_anim == "giant":
		var k := clampf(t, 0.0, 1.0)
		sweep = sin(k * TAU * 3.0) * (1.0 - k)
		dust = sin(k * PI)
	var cleaner_k := 3.0
	var feet := Vector2(482, ground_y)
	var head := feet - Vector2(0, 14.0 * cleaner_k)
	_cv_figure(cv, head, Color("#5d7a5a"), cleaner_k)
	cv.draw_line(feet + Vector2(-6 * cleaner_k * 0.3, -6), feet + Vector2(-22.0 + 16.0 * sweep, 2), Color("#8a6a3a"), 2.0)
	if dust > 0.0:
		for i in range(5):
			var p := feet + Vector2(-26.0 + i * 9.0 + 40.0 * t, -4.0 - 10.0 * dust * (0.5 + 0.1 * i))
			cv.draw_circle(p, 2.0 + i * 0.6, Color(0.55, 0.5, 0.42, 0.5 * dust))
	_s01_highlight(cv, "cleaner")
	# On the pavement, in chalk: a round scribble with grooves and a dot at the back (the map).
	var scribble := Vector2(150, 348)
	cv.draw_polyline(_s01_ring(scribble, 22, 9, 24), Color(1, 1, 1, 0.85), 1.5)
	cv.draw_polyline(PackedVector2Array([scribble + Vector2(-14, 0), scribble + Vector2(-6, -4), scribble + Vector2(2, 2), scribble + Vector2(10, -3)]), Color(1, 1, 1, 0.75), 1.2)
	cv.draw_circle(scribble + Vector2(16, 1), 2.0, Color(1, 1, 1, 0.9))
	_draw_closeup_girl(cv, Vector2(205, 300))
	_s01_highlight(cv, "girl")
	# Opening day: press cameras flash now and then.
	var time := Time.get_ticks_msec() * 0.001
	for k in range(3):
		var phase := fmod(time * 0.45 + k * 0.41, 1.0)
		if phase < 0.08:
			var at: Vector2 = [Vector2(60, 230), Vector2(470, 210), Vector2(130, 120)][k]
			var a := 1.0 - phase / 0.08
			cv.draw_circle(at, 10.0 + 14.0 * a, Color(1, 1, 1, 0.5 * a))
			for r in range(6):
				var d := Vector2.RIGHT.rotated(r * TAU / 6.0 + 0.3)
				cv.draw_line(at + d * 6.0, at + d * (22.0 + 16.0 * a), Color(1, 1, 1, 0.8 * a), 2.0)

func _draw_closeup_photo_winter(cv: CanvasItem, ground_y: float, inner: Rect2, t: float) -> void:
	# Snow lying still on the roof and the ground (a photograph: nothing falls), frost on the glass.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(136, 122), Vector2(384, 122), Vector2(372, 112), Vector2(148, 112)]), Color("#f4f6f8"))
	cv.draw_rect(Rect2(inner.position.x, ground_y, inner.size.x, 10), Color("#f4f6f8"), true)
	_draw_frost(cv, inner, 0.8)
	# Someone up a ladder, fixing the lamp over the door: Graham. Touched, she screws the bulb in and waves.
	cv.draw_line(Vector2(304, ground_y), Vector2(282, 236), Color("#5b4a3a"), 3.0)
	cv.draw_line(Vector2(320, ground_y), Vector2(298, 236), Color("#5b4a3a"), 3.0)
	for k in range(5):
		var yk := 250.0 + k * 17.0
		cv.draw_line(Vector2(285 + (yk - 236) * 0.23, yk), Vector2(301 + (yk - 236) * 0.23, yk), Color("#5b4a3a"), 2.0)
	cv.draw_circle(Vector2(289, 238), 9.0, Color("#f2c6a0"))
	cv.draw_arc(Vector2(289, 235), 9.5, PI * 1.05, PI * 1.95, 12, Color("#2b3547"), 6.0)
	cv.draw_rect(Rect2(281, 246, 16, 22), Color("#4b79a8"), true)
	var waving := s01_lamp_fixed or (closeup_anim == "lamp" and t > 0.5)
	if waving:
		var w := sin(Time.get_ticks_msec() * 0.01) * 6.0
		cv.draw_line(Vector2(295, 248), Vector2(312 + w, 230), Color("#4b79a8"), 4.0)
	else:
		var twist := sin(t * TAU * 2.0) * 3.0 if closeup_anim == "lamp" else 0.0
		cv.draw_line(Vector2(283, 248), Vector2(268 + twist, 238), Color("#4b79a8"), 4.0)
	_s01_highlight(cv, "graham")
	# The cleaner, shovelling snow. Touched, he throws a shovelful out of the photo.
	_cv_figure(cv, Vector2(96, ground_y - 50), Color("#5d7a5a"), 3.6)
	var throw := sin(clampf(t, 0.0, 1.0) * PI) if closeup_anim == "shovel" else 0.0
	var blade := Vector2(118, 322).lerp(Vector2(126, 286), throw)
	cv.draw_line(Vector2(100, 300), blade, Color("#8a6a3a"), 3.0)
	cv.draw_rect(Rect2(blade - Vector2(6, 2), Vector2(12, 6)), Color("#7d8790"), true)
	if closeup_anim == "shovel" and t > 0.4:
		var k := (t - 0.4) / 0.6
		var lump := blade.lerp(Vector2(-30, 420), k) + Vector2(0, -80.0 * sin(k * PI))
		cv.draw_circle(lump, 9.0, Color("#f4f6f8"))
		cv.draw_circle(lump + Vector2(8, 4), 6.0, Color("#f4f6f8"))
	_s01_highlight(cv, "shoveler")
	# ...and a white bear with blue eyes, on the ground; its eyes follow the hand.
	var bear := Vector2(200, ground_y + 6)
	cv.draw_circle(bear + Vector2(0, -16), 11.0, Color("#f4f6f8"))
	cv.draw_circle(bear + Vector2(-9, -26), 4.0, Color("#f4f6f8"))
	cv.draw_circle(bear + Vector2(9, -26), 4.0, Color("#f4f6f8"))
	cv.draw_circle(bear + Vector2(0, 0), 13.0, Color("#f4f6f8"))
	var look := (closeup_hand - (bear + Vector2(0, -18))).normalized() * 1.5
	cv.draw_rect(Rect2(bear + Vector2(-6, -19) + look, Vector2(3.5, 3.5)), Color("#2f86e0"), true)
	cv.draw_rect(Rect2(bear + Vector2(3, -19) + look, Vector2(3.5, 3.5)), Color("#2f86e0"), true)
	_s01_highlight(cv, "bear")
	_s01_highlight(cv, "snow")

func _draw_closeup_photo_later(cv: CanvasItem, ground_y: float, inner: Rect2, door: Rect2, t: float) -> void:
	# Years later: faded, nobody, the door boarded up, water stains and mould on the print.
	cv.draw_line(door.position + Vector2(-4, 18), door.end + Vector2(4, -22), Color("#a88a62"), 6.0)
	cv.draw_line(Vector2(door.position.x - 4, door.end.y - 22), Vector2(door.end.x + 4, door.position.y + 18), Color("#a88a62"), 6.0)
	_draw_stains(cv, inner, 1.0)
	# ...and a book with a blue cover and white pages on the doorstep. Touched, it leafs through itself.
	var at := Vector2(259, ground_y + 7)
	if s01_book_open or closeup_anim == "pages":
		cv.draw_rect(Rect2(at - Vector2(20, 7), Vector2(40, 12)), Color("#2f86e0"), true)
		cv.draw_rect(Rect2(at - Vector2(18, 9), Vector2(17, 12)), Color("#f4f6f8"), true)
		cv.draw_rect(Rect2(at - Vector2(-1, 9), Vector2(17, 12)), Color("#f4f6f8"), true)
		if closeup_anim == "pages":
			var flip := fmod(t * 7.0, 1.0)
			var tip := at + Vector2(lerpf(16, -16, flip), -9 - 14 * sin(flip * PI))
			cv.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -9), tip, tip + Vector2(0, 12), at + Vector2(0, 3)]), Color("#e6eaee"))
		if s01_book_open or t > 0.85:
			cv.draw_circle(at + Vector2(8, -3), 2.6, Color(0.2, 0.45, 0.85, 0.8))
			for f in range(4):
				cv.draw_circle(at + Vector2(5 + f * 2.0, -7), 0.9, Color(0.2, 0.45, 0.85, 0.8))
	else:
		cv.draw_rect(Rect2(at - Vector2(15, 6), Vector2(30, 11)), Color("#2f86e0"), true)
		cv.draw_line(at + Vector2(-12, -1), at + Vector2(12, -1), Color("#f4f6f8"), 2.0)
	cv.draw_rect(inner, Color(0.45, 0.45, 0.45, 0.22), true)
	_s01_highlight(cv, "book")

## Frost creeping in from the corners: fern-like crystals (instead of falling snow).
func _draw_frost(cv: CanvasItem, area: Rect2, a: float) -> void:
	var ice := Color(0.93, 0.97, 1.0, 0.75 * a)
	var corners := [[area.position, 0.0], [Vector2(area.end.x, area.position.y), PI / 2.0], [area.end, PI], [Vector2(area.position.x, area.end.y), PI * 1.5]]
	for c in corners:
		var origin: Vector2 = c[0]
		var base: float = c[1]
		for i in range(5):
			var ang := base + 0.15 + i * 0.3
			var dir := Vector2.RIGHT.rotated(ang)
			var length := 40.0 + (i % 3) * 22.0
			cv.draw_line(origin, origin + dir * length, ice, 1.5)
			for j in range(1, 5):
				var p := origin + dir * (length * j / 5.0)
				var side := 7.0 * (1.0 - j / 6.0)
				cv.draw_line(p, p + dir.rotated(0.7) * side, ice, 1.0)
				cv.draw_line(p, p + dir.rotated(-0.7) * side, ice, 1.0)

## Water stains, mould and peeling paint (instead of cobwebs).
func _draw_stains(cv: CanvasItem, area: Rect2, a: float) -> void:
	var stain := Color(0.45, 0.33, 0.18, 0.45 * a)
	for s in [[Vector2(70, 70), 30.0], [Vector2(430, 60), 22.0], [Vector2(400, 300), 40.0], [Vector2(110, 280), 18.0]]:
		var c: Vector2 = area.position + (s[0] as Vector2) * (area.size / Vector2(484, 344))
		var r: float = s[1]
		cv.draw_arc(c, r, 0.0, TAU, 28, stain, 2.0)
		cv.draw_arc(c + Vector2(3, 2), r * 0.7, 0.0, TAU, 24, Color(stain, 0.3 * a), 1.5)
	for i in range(18):
		var p := area.position + Vector2(fmod(i * 53.0, area.size.x * 0.3) + area.size.x * 0.68, fmod(i * 29.0, area.size.y * 0.25))
		cv.draw_circle(p, 1.5 + (i % 3), Color(0.25, 0.33, 0.2, 0.55 * a))
	cv.draw_colored_polygon(PackedVector2Array([area.position + Vector2(0, area.size.y * 0.6), area.position + Vector2(26, area.size.y * 0.66), area.position + Vector2(8, area.size.y * 0.74), area.position + Vector2(0, area.size.y * 0.72)]), Color(0.92, 0.9, 0.84, 0.7 * a))

## The blue-eyed girl in the opening-day crowd (LAN, years ago). She holds a piece of chalk;
## when Graham reaches for it, her arm comes out of the photograph.
func _draw_closeup_girl(cv: CanvasItem, head: Vector2) -> void:
	var skin := Color("#e2c9a8")
	var shoulder := head + Vector2(6, 14)
	cv.draw_colored_polygon(PackedVector2Array([head + Vector2(-8, 9), head + Vector2(8, 9), head + Vector2(14, 34), head + Vector2(-14, 34)]), Color("#f4f6f8"))
	cv.draw_circle(head, 9.0, skin)
	cv.draw_rect(Rect2(head + Vector2(-5, -2), Vector2(3, 3)), Color("#2f86e0"), true)
	cv.draw_rect(Rect2(head + Vector2(2, -2), Vector2(3, 3)), Color("#2f86e0"), true)
	cv.draw_arc(head + Vector2(0, -2), 9.5, PI, TAU, 10, Color("#c9b27e"), 3.0)
	var hand: Vector2
	if s01_has_chalk:
		hand = shoulder + Vector2(4, 18)
	elif closeup == "photo" and closeup_anim == "chalk":
		# First she twirls the cut ribbon; then her arm comes out of the photo, down past its frame.
		if closeup_anim_t < 0.35:
			var spin := closeup_anim_t / 0.35 * TAU * 2.0
			var loop := PackedVector2Array()
			for i in range(17):
				var a := spin + i * 0.35
				loop.append(head + Vector2(cos(a) * (20.0 + i), 14.0 + sin(a) * (10.0 + i * 0.6)))
			cv.draw_polyline(loop, Color("#d8202a"), 3.0)
		var t := clampf((closeup_anim_t - 0.3) / 0.7, 0.0, 1.0)
		var raised := shoulder + Vector2(16, -14)
		var out := Vector2(310, 420)
		hand = raised.lerp(out, t * t * (3.0 - 2.0 * t)) + Vector2(0, -40.0 * sin(t * PI))
	else:
		hand = shoulder + Vector2(16, -14)
	cv.draw_line(shoulder, hand, skin, 3.0)
	cv.draw_circle(hand, 2.5, skin)
	if not s01_has_chalk:
		var fade := 1.0
		if closeup_anim == "chalk" and closeup_anim_t > 0.85:
			fade = (1.0 - closeup_anim_t) / 0.15
		cv.draw_rect(Rect2(hand + Vector2(-2, -7), Vector2(4, 11)), Color(1, 1, 1, fade), true)

## Graham's hand over the photo (big close-up): her sleeve comes in from the bottom edge.
func _draw_closeup_hand(cv: CanvasItem, bottom: float = 460.0) -> void:
	if closeup_anim == "chalk":
		return
	var h := closeup_hand
	var sleeve := Color("#4b79a8")
	var skin := Color("#f2c6a0")
	cv.draw_colored_polygon(PackedVector2Array([h + Vector2(-9, 14), h + Vector2(9, 14), h + Vector2(16, bottom - h.y), h + Vector2(-16, bottom - h.y)]), Color(sleeve, 0.9))
	cv.draw_circle(h + Vector2(0, 6), 9.0, skin)
	cv.draw_line(h + Vector2(-2, 2), h + Vector2(-1, -10), skin, 4.0)
	for f in [Vector2(-7, 0), Vector2(5, -2), Vector2(9, 4)]:
		cv.draw_line(h + Vector2(f.x * 0.6, 4), h + f, skin, 3.5)
	cv.draw_circle(h + Vector2(-1, -10), 2.0, skin.darkened(0.15))
	hand_drawn_frame = Engine.get_process_frames()
	if touch_pulse_t >= 0.0 and touch_pulse_t < 0.28:
		var g := touch_pulse_t / 0.28
		cv.draw_arc(touch_pulse_at + Vector2(-1, -10), 6.0 + 22.0 * (1.0 - pow(1.0 - g, 2.0)), 0.0, TAU, 28, Color(1, 1, 1, 0.6 * (1.0 - g)), 1.5)

func _draw_closeup_map(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#8a6f4a"), true)
	cv.draw_rect(Rect2(Vector2(12, 12), sz - Vector2(24, 24)), Color("#d8cfb5"), true)
	cv.draw_string(font, Vector2(30, 46), _t("sign.s01.10"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#6b5a44"))
	_s01_draw_map_on(cv, S01_MAZE_BIG_AREA, true)
	if s07_active and s07_room == "s01" and not s07_found.get("s01", true):
		# Where the eyes would be: a small blue-and-white sticker, "它在这里". E peels it off.
		var lift := closeup_anim_t if closeup_anim == "peel" else 0.0
		var at := Vector2(157, 127) + Vector2(40, -90) * lift
		_draw_s07_egg("s01", at, 3.0, cv)
		cv.draw_string(font, at + Vector2(18, 6), _t("sign.s01.11"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#2f86e0"))
	if closeup_anim == "key":
		var t := closeup_anim_t
		var cell := Vector2(S01_MAZE_BIG_AREA.size.x / 12.0, S01_MAZE_BIG_AREA.size.y / 6.0)
		var goal := _s01_maze_pos(S01_MAZE_GOAL, S01_MAZE_BIG_AREA)
		if t < 0.35:
			# The chalk line and the bow light up together: a key.
			var glow := sin(t / 0.35 * PI)
			_s01_draw_key_shape(cv, goal, cell, Color(1, 1, 1, 0.35 * glow), cell.y * 0.7)
			_s01_draw_key_shape(cv, goal, cell, Color(1, 1, 1, 0.9), cell.y * 0.2)
		else:
			# It peels off the paper, turns, and drops out of the bottom of the close-up.
			var k := (t - 0.35) / 0.65
			var origin := goal.lerp(Vector2(sz.x * 0.45, sz.y + 120), k * k)
			var shrink := lerpf(1.0, 0.55, k)
			_s01_draw_key_shape(cv, origin + Vector2(3, 4), cell * shrink, Color(0, 0, 0, 0.35), cell.y * 0.3 * shrink, k * 0.6)
			_s01_draw_key_shape(cv, origin, cell * shrink, Color("#fbfbf7"), cell.y * 0.3 * shrink, k * 0.6)

func _draw_closeup_clocks(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var time := Time.get_ticks_msec() * 0.001
	# While a hand is turning, the painting slides from the old era to the new one.
	var w := 1.0
	var from_era := s01_era
	var from_melt := s01_melt
	if closeup_anim == "turn":
		w = closeup_anim_t * closeup_anim_t * (3.0 - 2.0 * closeup_anim_t)
		from_era = closeup_prev_era
		from_melt = closeup_prev_melt
	var weights: Array[float] = []
	for k in range(3):
		weights.append(lerpf(1.0 if from_era == k else 0.0, 1.0 if s01_era == k else 0.0, w))
	var sky: Color = S01_CLOCK_SKY[from_era].lerp(S01_CLOCK_SKY[s01_era], w)
	var ground: Color = S01_CLOCK_GROUND[from_era].lerp(S01_CLOCK_GROUND[s01_era], w)
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#c7a56f"), true)
	var inner := Rect2(Vector2(16, 16), sz - Vector2(32, 32))
	cv.draw_rect(inner, sky, true)
	cv.draw_rect(Rect2(inner.position.x, inner.end.y - 80, inner.size.x, 80), ground, true)
	cv.draw_line(Vector2(150, inner.end.y - 80), Vector2(250, 60), Color("#4f5d60"), 12.0)
	cv.draw_line(Vector2(222, 108), Vector2(262, 96), Color("#4f5d60"), 6.0)
	# Opening day: warm light, and press cameras flashing.
	if weights[0] > 0.01:
		var a0 := weights[0]
		cv.draw_rect(inner, Color(1.0, 0.85, 0.5, 0.18 * a0), true)
		for k in range(3):
			var phase := fmod(time * 0.5 + k * 0.37, 1.0)
			if phase < 0.09:
				var at: Vector2 = [Vector2(80, 70), Vector2(470, 90), Vector2(300, 250)][k]
				var a := (1.0 - phase / 0.09) * a0
				cv.draw_circle(at, 12.0 + 18.0 * a, Color(1, 1, 1, 0.45 * a))
				for r in range(6):
					var d := Vector2.RIGHT.rotated(r * TAU / 6.0 + 0.3)
					cv.draw_line(at + d * 8.0, at + d * (26.0 + 20.0 * a), Color(1, 1, 1, 0.8 * a), 2.0)
	# Winter: frost growing in from the corners, the eyes glazed and cracked.
	if weights[1] > 0.01:
		_draw_frost(cv, inner, weights[1])
	# Years later: water stains, mould, peeling paint, a crack across the canvas.
	if weights[2] > 0.01:
		var a2 := weights[2]
		cv.draw_rect(inner, Color(0.4, 0.4, 0.38, 0.35 * a2), true)
		_draw_stains(cv, inner, a2)
		cv.draw_polyline(PackedVector2Array([Vector2(300, 16), Vector2(286, 70), Vector2(312, 118), Vector2(296, 190), Vector2(318, 260), Vector2(304, sz.y - 16)]), Color(0.1, 0.1, 0.1, 0.7 * a2), 2.0)
	var left_a := lerpf(_s01_hand_angle(_s01_left_turns(from_era)), _s01_hand_angle(_s01_left_turns(s01_era)), w)
	var right_a := lerpf(_s01_hand_angle(from_era + from_melt), _s01_hand_angle(s01_era + s01_melt), w)
	var right_melt := lerpf(float(from_melt), float(s01_melt), w)
	_draw_closeup_clock_eye(cv, Vector2(160, 170), left_a, 0.0, weights[1])
	_draw_closeup_clock_eye(cv, Vector2(400, 170), right_a, right_melt, weights[1])
	# A fresh stroke of the ribbon's red paint on this frame too (the restorer painted the ribbon).
	if s01_restorer_dab:
		cv.draw_polyline(PackedVector2Array([Vector2(20, 330), Vector2(60, 318), Vector2(96, 326)]), Color(0.85, 0.13, 0.16, 0.95), 5.0)
	cv.draw_string(font, Vector2(sz.x * 0.5 - 64, -10), _t("sign.s01.05"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _s01_hand_angle(turns: int) -> float:
	return -PI / 2.0 + turns * 0.9

func _draw_closeup_clock_eye(cv: CanvasItem, c: Vector2, a: float, melt: float, frost: float) -> void:
	var white := Color("#ece6d6")
	if melt >= 2.95:
		cv.draw_circle(c, 52.0, Color("#3d4441"))
		cv.draw_line(c + Vector2(0, 52), c + Vector2(6, 160), Color("#cfc8b6"), 6.0)
		return
	var drip := 80.0 + melt * 40.0
	cv.draw_colored_polygon(PackedVector2Array([c + Vector2(-46, 14), c + Vector2(46, 14), c + Vector2(14, drip), c + Vector2(0, drip + 16.0), c + Vector2(-14, drip)]), white)
	cv.draw_circle(c, 52.0, white)
	cv.draw_arc(c, 52.0, 0.0, TAU, 40, Color("#8f8a7c"), 2.0)
	for k in range(12):
		var t := -PI / 2.0 + k * TAU / 12.0
		cv.draw_line(c + Vector2(cos(t), sin(t)) * 44.0, c + Vector2(cos(t), sin(t)) * 49.0, Color("#8f8a7c"), 2.0)
	if frost > 0.01:
		# A skin of ice over the eye, cracked in a few straight lines.
		cv.draw_circle(c, 50.0, Color(0.85, 0.93, 1.0, 0.25 * frost))
		for k in range(4):
			var d := Vector2.RIGHT.rotated(0.4 + k * 1.7)
			cv.draw_polyline(PackedVector2Array([c + d * 8.0, c + d * 26.0 + d.orthogonal() * 4.0, c + d * 48.0]), Color(1, 1, 1, 0.8 * frost), 1.5)
	cv.draw_line(c, c + Vector2(cos(a), sin(a)) * 38.0, Color("#2b2b2b"), 5.0)
	cv.draw_line(c, c + Vector2(cos(a * 3.0), sin(a * 3.0)) * 24.0, Color("#2b2b2b"), 6.0)
	cv.draw_circle(c, 6.0, Color("#2b2b2b"))

func _draw_closeup_door(cv: CanvasItem, sz: Vector2) -> void:
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#5a4636"), true)
	var frame := Rect2(70, 96, 200, sz.y - 96)
	var panel := Rect2(84, 110, 172, sz.y - 110)
	cv.draw_rect(frame, Color("#445866"), true)
	# Opening (the past way, with the key): the dark doorway and light beyond it.
	var t := -1.0
	if closeup_anim == "door":
		t = closeup_anim_t
	elif s01_gate_open and s01_exit_route == "past":
		t = 1.0
	var swing := clampf((t - 0.55) / 0.45, 0.0, 1.0) if t >= 0.0 else 0.0
	cv.draw_rect(panel, Color("#0e1620"), true)
	if swing > 0.0:
		cv.draw_colored_polygon(PackedVector2Array([panel.position + Vector2(40, 40), Vector2(panel.end.x - 30, panel.position.y + 40), Vector2(panel.end.x, panel.end.y), Vector2(panel.position.x, panel.end.y)]), Color(0.86, 0.93, 1.0, 0.18 * swing))
	# The door swings toward the viewer: its free edge comes past the frame on the left.
	var free_x := lerpf(panel.end.x, panel.position.x - 120.0, swing)
	var bulge := 50.0 * swing
	var door_pts := PackedVector2Array([panel.position, Vector2(free_x, panel.position.y - bulge), Vector2(free_x, panel.end.y + bulge), Vector2(panel.position.x, panel.end.y)])
	if free_x > panel.position.x + 1.0:
		cv.draw_colored_polygon(door_pts, Color("#1c2934"))
	elif free_x < panel.position.x - 1.0:
		cv.draw_colored_polygon(PackedVector2Array([door_pts[0], door_pts[3], door_pts[2], door_pts[1]]), Color("#253645"))
	# Rust (the future way).
	if s01_melt >= 2:
		for i in range(10 + s01_melt * 8):
			var p := panel.position + Vector2(fmod(i * 47.0, panel.size.x), fmod(i * 61.0, panel.size.y))
			cv.draw_circle(p, 6.0 + (i % 4) * 2.0, Color(0.55, 0.3, 0.16, 0.85))
	if swing <= 0.0:
		# The lock plate, with a key engraved above the keyhole.
		var plate := Rect2(206, 214, 40, 92)
		cv.draw_rect(plate, Color("#b59f73"), true)
		cv.draw_rect(plate, Color("#7a6a4a"), false, 2.0)
		_s01_draw_key_shape(cv, plate.position + Vector2(6, 22), Vector2(2.4, 3.0), Color("#5d4f36"), 1.4)
		cv.draw_circle(Vector2(226, 266), 5.0, Color("#1a1a1a"))
		cv.draw_colored_polygon(PackedVector2Array([Vector2(223, 268), Vector2(229, 268), Vector2(231, 286), Vector2(221, 286)]), Color("#1a1a1a"))
		if t >= 0.0:
			# The chalk key slides in from where Graham holds it, then turns.
			var slide := clampf(t / 0.3, 0.0, 1.0)
			var turn := clampf((t - 0.3) / 0.25, 0.0, 1.0)
			var tip := Vector2(226, 272) + Vector2(160, 90) * (1.0 - slide)
			_s01_draw_key_shape(cv, tip, Vector2(5.0, 6.0) * lerpf(1.0, 0.8, turn), Color("#fbfbf7"), 3.0, turn * TAU * 0.5)
	_draw_closeup_sign(cv, Vector2(sz.x * 0.5, 60))

func _draw_closeup_sign(cv: CanvasItem, s: Vector2) -> void:
	var font := ThemeDB.fallback_font
	if s01_melt >= 2:
		cv.draw_line(s + Vector2(-40, -40), s + Vector2(-40, -26), Color("#6d6250"), 3.0)
		return
	if s01_era == 2:
		cv.draw_line(s + Vector2(-44, -40), s + Vector2(-44, -24), Color("#6d6250"), 3.0)
		var pivot := s + Vector2(-48, -24)
		var pts := PackedVector2Array()
		for corner in [Vector2(0, 0), Vector2(96, 0), Vector2(96, 44), Vector2(0, 44)]:
			pts.append(pivot + corner.rotated(0.38))
		cv.draw_colored_polygon(pts, Color("#2f3f35"))
		cv.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("#56604f"), 2.0)
		return
	var glow := 0.25 if s01_era == 0 else 0.14
	var flicker := 1.0 if s01_era == 0 else 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.02)
	cv.draw_circle(s, 62.0 if s01_era == 0 else 52.0, Color(0.35, 1.0, 0.55, glow * 0.5 * flicker))
	cv.draw_circle(s, 44.0, Color(0.35, 1.0, 0.55, glow * flicker))
	for cx in [-36.0, 36.0]:
		cv.draw_line(s + Vector2(cx, -34), s + Vector2(cx, -22), Color("#8d7b5c"), 3.0)
	cv.draw_rect(Rect2(s - Vector2(48, 22), Vector2(96, 44)), Color("#3fdc7a") if s01_era == 0 else Color("#2fae5f"), true)
	cv.draw_string(font, s + Vector2(-30, 12), _t("sign.s01.06"), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)

## 《这不是一只眼睛》 up close. No hints here any more; but its cornea is curved like a fisheye lens,
## and Graham is in it (easter egg): a big head, small feet, the room bent around her.
func _draw_closeup_eye(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#c7a56f"), true)
	var inner := Rect2(Vector2(16, 16), sz - Vector2(32, 32))
	cv.draw_rect(inner, Color("#777f78"), true)
	var c := Vector2(sz.x * 0.5, 160)
	var white := _s01_ring(c, 150, 84, 40)
	white.remove_at(white.size() - 1)
	cv.draw_colored_polygon(white, Color("#ece6d6"))
	cv.draw_circle(c, 56.0, Color("#55718a"))
	for k in range(16):
		var a := k * TAU / 16.0
		cv.draw_line(c + Vector2(cos(a), sin(a)) * 26.0, c + Vector2(cos(a), sin(a)) * 52.0, Color(0.27, 0.4, 0.5, 0.6), 2.0)
	cv.draw_circle(c, 24.0 + 26.0 * s01_eye_zoom, Color("#151a1f"))
	if s01_eye_zoom > 0.8:
		# Right up close: a thin fold of skin shows along the top of the eyeball.
		var lid_a := (s01_eye_zoom - 0.8) / 0.2
		var fold := PackedVector2Array()
		for i in range(21):
			var a := PI + PI * i / 20.0
			fold.append(c + Vector2(cos(a) * 150.0, sin(a) * 84.0 + 6.0))
		cv.draw_polyline(fold, Color(0.86, 0.62, 0.56, 0.85 * lid_a), 7.0)
	# The reflection: the hall's ceiling lights and floor bent into curves, and Graham, where she stands.
	var side := clampf((player.position.x - S01_EYE_CENTER.x) / 500.0, -1.0, 1.0) if player else 0.0
	var refl := Color(0.85, 0.92, 1.0, 0.28)
	cv.draw_arc(c + Vector2(0, 70), 76.0, PI * 1.25, PI * 1.75, 16, refl, 2.0)
	cv.draw_arc(c + Vector2(0, -60), 70.0, PI * 0.3, PI * 0.7, 16, refl, 2.0)
	for lx in [-1.0, 0.0, 1.0]:
		cv.draw_circle(c + Vector2(lx * 24.0, -36.0 + absf(lx) * 6.0), 2.5, Color(1, 0.95, 0.8, 0.5))
	var gz := 1.0 + 1.6 * s01_eye_zoom
	var g := c + Vector2(side * 26.0, 6.0)
	var a_g := 0.62
	cv.draw_set_transform(Vector2.ZERO)
	cv.draw_set_transform_matrix(_closeup_xform() * Transform2D(0.0, Vector2(gz, gz), 0.0, g - g * gz))
	cv.draw_colored_polygon(PackedVector2Array([g + Vector2(-7, 8), g + Vector2(7, 8), g + Vector2(3, 22), g + Vector2(-3, 22)]), Color(0.29, 0.47, 0.66, a_g))
	cv.draw_circle(g, 11.0, Color(0.95, 0.78, 0.63, a_g))
	cv.draw_arc(g + Vector2(0, -3), 11.5, PI * 1.05, PI * 1.95, 12, Color(0.17, 0.21, 0.28, a_g + 0.2), 5.0)
	cv.draw_circle(g + Vector2(-4, -1), 1.6, Color(0.1, 0.12, 0.18, a_g))
	cv.draw_circle(g + Vector2(4, -1), 1.6, Color(0.1, 0.12, 0.18, a_g))
	cv.draw_set_transform_matrix(_closeup_xform())
	cv.draw_circle(c + Vector2(-22, -22), 8.0, Color(1, 1, 1, 0.55))
	cv.draw_circle(c + Vector2(-12, -30), 3.0, Color(1, 1, 1, 0.5))
	cv.draw_string(font, Vector2(sz.x * 0.5 - 70, sz.y - 40), _t("sign.s01.07"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#e8e2d0"))
	cv.draw_string(font, Vector2(sz.x * 0.5 - 90, -10), _t("sign.s01.08"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _closeup_xform() -> Transform2D:
	return closeup_xf

## --- 超写实插帧 (hyper-real inserts) -----------------------------------------------------------
## At a few peak beats the flat style hard-cuts, for under a second, to a still with far too much
## real detail (pores, wet eyeballs, dirt under nails, scratched brass), then cuts back. Used
## sparingly. These are placeholders: procedural noise standing in for photographed or painted
## stills that the real art will replace. Each one is labelled on screen as a placeholder.
const HYPER_RECT := Rect2(236, 80, 680, 400)

## Which insert is showing now, and how far into it (0..1); empty when none.
func _s01_hyper_now() -> Array:
	if hyper_flash_left > 0.0:
		return [hyper_flash, 1.0 - hyper_flash_left / HYPER_FLASH_TIME]
	if closeup == "":
		return []
	var t := closeup_anim_t
	match closeup_anim:
		"chalk":
			if t >= 0.42 and t <= 0.78:
				return ["hand", (t - 0.42) / 0.36]
		"glove":
			if t >= 0.25 and t <= 0.8:
				return ["marble", (t - 0.25) / 0.55]
		"door":
			if t >= 0.26 and t <= 0.6:
				return ["brass", (t - 0.26) / 0.34]
		"eyelid":
			if t >= 0.12 and t <= 0.86:
				return ["eyelid", (t - 0.12) / 0.74]
		"splat":
			return ["eyeball", t]
		"sponge":
			if t >= 0.3 and t <= 0.72:
				return ["sponge", (t - 0.3) / 0.42]
		"kent":
			if t >= 0.28 and t <= 0.8:
				return ["spider", (t - 0.28) / 0.52]
		"take":
			if t >= 0.22 and t <= 0.72:
				return ["aperture", (t - 0.22) / 0.5]
	return []

func _hyper_texture(kind: String) -> Texture2D:
	if hyper_textures.has(kind):
		return hyper_textures[kind]
	var w := 160
	var h := 110
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = kind.hash()
	noise.frequency = 0.06
	noise.fractal_octaves = 5
	var fine := FastNoiseLite.new()
	fine.seed = kind.hash() + 7
	fine.frequency = 0.45
	for y in range(h):
		for x in range(w):
			var n := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var f := fine.get_noise_2d(x, y) * 0.5 + 0.5
			var c := Color.WHITE
			if kind == "skin":
				c = Color(0.82, 0.60, 0.52).lerp(Color(0.62, 0.38, 0.34), n)
				c = c.lerp(Color(0.74, 0.40, 0.44), clampf(noise.get_noise_2d(x * 0.3 + 50.0, y * 0.3), 0.0, 1.0) * 0.5)
				if f > 0.76:
					c = c.darkened(0.28)
			elif kind == "marble":
				var vein := absf(noise.get_noise_2d(x * 0.7, y * 0.7))
				c = Color(0.93, 0.92, 0.89).lerp(Color(0.62, 0.62, 0.6), clampf(1.0 - vein * 9.0, 0.0, 1.0) * 0.8)
				c = c.lerp(Color(0.86, 0.85, 0.8), n * 0.3)
			elif kind == "eyeball":
				c = Color(0.97, 0.95, 0.91).lerp(Color(0.93, 0.78, 0.74), n * n)
				if f > 0.85:
					c = c.lerp(Color(0.85, 0.55, 0.55), 0.4)
			elif kind == "sponge":
				c = Color(0.86, 0.74, 0.36).lerp(Color(0.6, 0.48, 0.2), n)
				c = c.lerp(Color(0.45, 0.43, 0.38), clampf(noise.get_noise_2d(x * 0.4 + 90.0, y * 0.4), 0.0, 1.0) * 0.6)
				if f > 0.6:
					c = c.darkened(0.55)
			elif kind == "chitin":
				c = Color(0.1, 0.07, 0.05).lerp(Color(0.3, 0.21, 0.12), n)
				if f > 0.78:
					c = c.lightened(0.25)
			elif kind == "paint":
				var streak := noise.get_noise_2d(x * 0.25, y * 1.6) * 0.5 + 0.5
				c = Color(0.62, 0.48, 0.28).lerp(Color(0.24, 0.17, 0.11), streak * 0.8 + n * 0.2)
			else:
				var b := noise.get_noise_2d(x * 0.12, y * 2.5) * 0.5 + 0.5
				c = Color(0.42, 0.30, 0.10).lerp(Color(0.98, 0.84, 0.46), b)
				if f > 0.8:
					c = c.darkened(0.35)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	hyper_textures[kind] = tex
	return tex

func _hyper_poly(cv: CanvasItem, pts: PackedVector2Array, tex: Texture2D, area: Rect2) -> void:
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append((p - area.position) / area.size)
	cv.draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, tex)

func _hyper_capsule(base: Vector2, tip: Vector2, width: float) -> PackedVector2Array:
	var d := (tip - base).normalized()
	var n := d.orthogonal() * width * 0.5
	var pts := PackedVector2Array([base + n, tip + n])
	for i in range(1, 8):
		pts.append(tip + n.rotated(-PI * i / 8.0))
	pts.append(tip - n)
	pts.append(base - n)
	return pts

func _hyper_veins(cv: CanvasItem, area: Rect2, center: Vector2, count: int, seed_value: int, alpha: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(count):
		var a := rng.randf() * TAU
		var p := center + Vector2.RIGHT.rotated(a) * area.size.x * 0.45
		var line := PackedVector2Array([p])
		for k in range(6):
			p += (center - p).normalized().rotated(rng.randf_range(-0.9, 0.9)) * rng.randf_range(14.0, 30.0)
			p = p.clamp(area.position, area.end)
			line.append(p)
		cv.draw_polyline(line, Color(0.72, 0.12, 0.14, alpha), rng.randf_range(1.0, 2.6))

func _draw_hyperreal(cv: CanvasItem) -> void:
	# After the eyelid has shut, the whole screen is black until the gallery's darkness takes over.
	if closeup_anim == "eyelid" and closeup_anim_t > 0.86:
		cv.draw_rect(Rect2(0, 0, 1152, 648), Color(0, 0, 0, 0.97), true)
		return
	var now := _s01_hyper_now()
	if now.is_empty():
		return
	var kind: String = now[0]
	var p: float = now[1]
	var r := HYPER_RECT
	cv.draw_rect(Rect2(0, 58, 1152, 590), Color(0, 0, 0, 0.92), true)
	var label := ""
	match kind:
		"eyelid":
			label = "真实的眼睑合上"
			cv.draw_texture_rect(_hyper_texture("eyeball"), r, false)
			var c := r.get_center()
			_hyper_veins(cv, r, c, 14, 11, 0.75)
			cv.draw_circle(c, 92.0, Color(0.26, 0.36, 0.44))
			for k in range(48):
				var d := Vector2.RIGHT.rotated(k * TAU / 48.0)
				cv.draw_line(c + d * 40.0, c + d * 90.0, Color(0.55, 0.66, 0.72, 0.35), 1.5)
			cv.draw_circle(c, 38.0, Color(0.03, 0.03, 0.04))
			cv.draw_circle(c + Vector2(-30, -34), 16.0, Color(1, 1, 1, 0.85))
			cv.draw_circle(c + Vector2(-8, -44), 6.0, Color(1, 1, 1, 0.7))
			# The lid comes down: skin with pores, a crease, a wet pink rim and lashes.
			var e := p * p * (3.0 - 2.0 * p)
			var lid_h := r.size.y * minf(1.0, e * 1.05)
			if lid_h > 1.0:
				cv.draw_texture_rect_region(_hyper_texture("skin"), Rect2(r.position, Vector2(r.size.x, lid_h)), Rect2(0, 110.0 * (1.0 - lid_h / r.size.y), 160, 110.0 * lid_h / r.size.y))
				var edge := r.position.y + lid_h
				if lid_h > 30.0:
					cv.draw_polyline(PackedVector2Array([Vector2(r.position.x, edge - 26), Vector2(c.x, edge - 34), Vector2(r.end.x, edge - 26)]), Color(0.45, 0.25, 0.22, 0.6), 3.0)
				cv.draw_line(Vector2(r.position.x, edge), Vector2(r.end.x, edge), Color(0.85, 0.5, 0.5), 5.0)
				var rng := RandomNumberGenerator.new()
				rng.seed = 5
				for i in range(70):
					var x := r.position.x + i * r.size.x / 70.0 + rng.randf_range(-3, 3)
					var lash := rng.randf_range(14, 26)
					cv.draw_polyline(PackedVector2Array([Vector2(x, edge), Vector2(x + 3, edge + lash * 0.6), Vector2(x + 8, edge + lash)]), Color(0.08, 0.06, 0.05), rng.randf_range(1.2, 2.2))
		"eyeball":
			label = "湿眼球摊在地毯上"
			cv.draw_rect(r, Color("#4d1f1c"), true)
			var rng := RandomNumberGenerator.new()
			rng.seed = 3
			for i in range(260):
				cv.draw_line(r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y), r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y).lerp(r.get_center(), 0.97), Color(0.55, 0.22, 0.2, 0.25), 1.0)
			var c := r.get_center() + Vector2(0, 30)
			var squash := lerpf(0.9, 0.55, minf(1.0, p * 3.0))
			var blob := PackedVector2Array()
			for i in range(36):
				var a := TAU * i / 36.0
				var wob := 1.0 + 0.08 * sin(a * 5.0) + 0.05 * sin(a * 11.0)
				blob.append(c + Vector2(cos(a) * 190.0 * wob, sin(a) * 190.0 * squash * wob))
			cv.draw_colored_polygon(blob, Color(0.85, 0.75, 0.7, 0.35))
			var core := PackedVector2Array()
			for i in range(36):
				var a := TAU * i / 36.0
				core.append(c + Vector2(cos(a) * 150.0, sin(a) * 150.0 * squash))
			_hyper_poly(cv, core, _hyper_texture("eyeball"), r)
			_hyper_veins(cv, Rect2(c - Vector2(150, 150), Vector2(300, 300)), c, 12, 21, 0.8)
			var iris_c := c + Vector2(40, -10 * squash)
			var iris := PackedVector2Array()
			for i in range(28):
				var a := TAU * i / 28.0
				iris.append(iris_c + Vector2(cos(a) * 58.0, sin(a) * 58.0 * squash))
			cv.draw_colored_polygon(iris, Color(0.3, 0.38, 0.42))
			cv.draw_circle(iris_c, 20.0 * squash + 4.0, Color(0.03, 0.03, 0.04))
			cv.draw_circle(c + Vector2(-60, -50 * squash), 14.0, Color(1, 1, 1, 0.9))
			cv.draw_circle(c + Vector2(-30, -62 * squash), 5.0, Color(1, 1, 1, 0.8))
		"hand":
			label = "小孩的手，指甲缝里有粉笔灰"
			cv.draw_rect(r, Color(0.33, 0.27, 0.2), true)
			var skin := _hyper_texture("skin")
			var wrist := Vector2(r.position.x + 300, r.end.y + 10)
			var palm := PackedVector2Array()
			var pc := Vector2(r.position.x + 330, r.position.y + 250)
			for i in range(24):
				var a := TAU * i / 24.0
				palm.append(pc + Vector2(cos(a) * 110.0, sin(a) * 90.0))
			_hyper_poly(cv, _hyper_capsule(wrist, pc, 150.0), skin, r)
			_hyper_poly(cv, palm, skin, r)
			var tips := [Vector2(-90, -170), Vector2(-25, -200), Vector2(40, -190), Vector2(100, -150)]
			for i in range(4):
				var base := pc + Vector2(-75 + i * 50, -50)
				var tip: Vector2 = pc + (tips[i] as Vector2)
				_hyper_poly(cv, _hyper_capsule(base, tip, 44.0), skin, r)
				cv.draw_line(base.lerp(tip, 0.55) + Vector2(-14, 0), base.lerp(tip, 0.55) + Vector2(14, 2), Color(0.45, 0.27, 0.24, 0.6), 2.0)
				var nail := tip + (base - tip).normalized() * 22.0
				cv.draw_circle(nail, 13.0, Color(0.9, 0.78, 0.74, 0.8))
				cv.draw_arc(nail, 13.0, PI * 1.1, PI * 1.9, 10, Color(0.85, 0.85, 0.82), 3.0)
				cv.draw_arc(nail, 15.0, PI * 1.15, PI * 1.85, 10, Color(0.18, 0.13, 0.1), 2.0)
			# The thumb pins the chalk against the fingers.
			_hyper_poly(cv, _hyper_capsule(pc + Vector2(90, 40), pc + Vector2(190, -40), 50.0), skin, r)
			var chalk := PackedVector2Array([pc + Vector2(60, -120), pc + Vector2(210, -60), pc + Vector2(200, -36), pc + Vector2(50, -96)])
			cv.draw_colored_polygon(chalk, Color(0.96, 0.95, 0.92))
			var rng := RandomNumberGenerator.new()
			rng.seed = 9
			for i in range(60):
				var q := (pc + Vector2(60, -110)).lerp(pc + Vector2(200, -50), rng.randf()) + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6))
				cv.draw_circle(q, rng.randf_range(0.8, 2.0), Color(0.75, 0.74, 0.7))
		"marble":
			label = "大理石的手，被一只出汗的真手攥着"
			cv.draw_rect(r, Color(0.16, 0.18, 0.2), true)
			var marble_tex := _hyper_texture("marble")
			var skin := _hyper_texture("skin")
			var c := r.get_center()
			# The marble forearm and hand, polished, with fine cracks.
			_hyper_poly(cv, _hyper_capsule(c + Vector2(-330, 40), c + Vector2(150, -30), 120.0), marble_tex, r)
			for k in range(4):
				_hyper_poly(cv, _hyper_capsule(c + Vector2(150, -70 + k * 30), c + Vector2(290, -90 + k * 34), 34.0), marble_tex, r)
			cv.draw_polyline(PackedVector2Array([c + Vector2(-60, -10), c + Vector2(-20, 10), c + Vector2(10, -4), c + Vector2(60, 16)]), Color(0.35, 0.35, 0.34, 0.8), 1.5)
			# The guard's own fingers, sweaty, wrapped round it; the glove peels back off them.
			var slide := minf(1.0, p * 1.4)
			for k in range(4):
				var base := c + Vector2(-150 + k * 46, 110)
				_hyper_poly(cv, _hyper_capsule(base, base + Vector2(-10, -120), 42.0), skin, r)
				cv.draw_circle(base + Vector2(-8, -104), 7.0, Color(1, 1, 1, 0.5))
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(-260, 60) + Vector2(-260, 0) * slide, c + Vector2(40, 60) + Vector2(-260, 0) * slide, c + Vector2(40, 200), c + Vector2(-260, 200)]), Color(0.92, 0.91, 0.88))
		"painted_eye":
			label = "油画里的眼睛：龟裂、珍珠的反光"
			cv.draw_texture_rect(_hyper_texture("paint"), r, false)
			var c := r.get_center() + Vector2(-60, 0)
			var almond := PackedVector2Array()
			for i in range(32):
				var a := TAU * i / 32.0
				almond.append(c + Vector2(cos(a) * 200.0, sin(a) * 86.0 * (1.0 - 0.35 * absf(cos(a)))))
			cv.draw_colored_polygon(almond, Color(0.92, 0.88, 0.8))
			cv.draw_circle(c, 72.0, Color(0.33, 0.24, 0.16))
			for k in range(40):
				var d := Vector2.RIGHT.rotated(k * TAU / 40.0)
				cv.draw_line(c + d * 32.0, c + d * 70.0, Color(0.45, 0.33, 0.2, 0.6), 2.0)
			cv.draw_circle(c, 30.0, Color(0.05, 0.04, 0.03))
			cv.draw_circle(c + Vector2(-24, -26), 13.0, Color(1, 1, 1, 0.85))
			# The earphone (the pearl): a soft, pearly highlight.
			var pearl := r.end - Vector2(120, 110)
			for k in range(8):
				cv.draw_circle(pearl, 56.0 - k * 6.0, Color(0.85 + k * 0.015, 0.86 + k * 0.015, 0.84 + k * 0.016))
			cv.draw_circle(pearl + Vector2(-16, -18), 10.0, Color(1, 1, 1, 0.95))
			# Craquelure: the old paint has cracked into a fine net.
			var rng := RandomNumberGenerator.new()
			rng.seed = 17
			for i in range(70):
				var q := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
				var line := PackedVector2Array([q])
				for k in range(4):
					q = (q + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))).clamp(r.position, r.end)
					line.append(q)
				cv.draw_polyline(line, Color(0.12, 0.08, 0.05, 0.55), 1.2)
		"fluor":
			label = "皮肤上的核黄素，在紫外灯下发光"
			cv.draw_texture_rect(_hyper_texture("skin"), r, false, Color(0.5, 0.42, 0.85))
			cv.draw_rect(r, Color(0.3, 0.1, 0.6, 0.35), true)
			var rng := RandomNumberGenerator.new()
			rng.seed = 23
			for i in range(9):
				var c := r.position + Vector2(rng.randf_range(80, r.size.x - 80), rng.randf_range(60, r.size.y - 60))
				var big := rng.randf_range(20, 46)
				for k in range(7):
					cv.draw_circle(c, big * (2.2 - k * 0.2), Color(0.78, 1.0, 0.3, 0.05 + k * 0.03))
				cv.draw_circle(c, big * 0.8, Color(0.85, 1.0, 0.45, 0.9))
				cv.draw_line(c + Vector2(0, big * 0.6), c + Vector2(rng.randf_range(-6, 6), big * 0.6 + rng.randf_range(20, 60)), Color(0.85, 1.0, 0.45, 0.8), 4.0)
				cv.draw_circle(c + Vector2(-big * 0.3, -big * 0.3), big * 0.18, Color(1, 1, 1, 0.8))
		"sponge":
			label = "吸饱脏水的海绵，压在镜片上"
			_draw_hyper_sponge(cv, r, p)
		"spider":
			label = "跳蛛的主眼"
			_draw_hyper_spider(cv, r, p)
		"aperture":
			label = "八只镜头的光圈，对着格雷汉的手收紧"
			_draw_hyper_aperture(cv, r, p)
		_:
			label = "黄铜锁芯与粉笔灰"
			cv.draw_texture_rect(_hyper_texture("brass"), r, false)
			var c := r.get_center()
			for k in range(5):
				cv.draw_arc(c, 70.0 + k * 26.0, 0.0, TAU, 48, Color(0.3, 0.2, 0.05, 0.35), 2.0)
			cv.draw_circle(c, 60.0, Color(0.55, 0.42, 0.16))
			cv.draw_circle(c + Vector2(0, -12), 22.0, Color(0.02, 0.02, 0.02))
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(-12, 0), c + Vector2(12, 0), c + Vector2(18, 48), c + Vector2(-18, 48)]), Color(0.02, 0.02, 0.02))
			# The chalk blade goes in, crumbling.
			var depth := minf(1.0, p * 1.6)
			var blade := PackedVector2Array([c + Vector2(-9, 220 - 200 * depth), c + Vector2(9, 220 - 200 * depth), c + Vector2(9, 400), c + Vector2(-9, 400)])
			cv.draw_colored_polygon(blade, Color(0.95, 0.94, 0.9))
			var rng := RandomNumberGenerator.new()
			rng.seed = 13
			for i in range(70):
				var q := c + Vector2(rng.randf_range(-40, 40), rng.randf_range(20, 60) + p * rng.randf_range(40, 200))
				cv.draw_circle(q, rng.randf_range(0.8, 2.4), Color(0.93, 0.92, 0.88, 0.85))
	# Marked as a placeholder until the real still is made.
	var font := ThemeDB.fallback_font
	cv.draw_rect(Rect2(r.position + Vector2(10, r.size.y - 34), Vector2(330, 24)), Color(0, 0, 0, 0.65), true)
	cv.draw_string(font, r.position + Vector2(18, r.size.y - 16), "超写实插帧（占位）· " + label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.9))

## --- Close-ups in the second hall (S02/S03) -------------------------------------------------
## 保安 (a person), 《那喀索斯》 with its picture lamp (big: Graham's hand, WASD), 《机械维纳斯》 with
## 《光》 above her (arms are dragged on with LAN's chalk, then E tries poses), and two close-ups seen
## by LAN while it rides the belt, drawn in the blue-lake layer.
const NARC_REGION := Rect2(230, 185, 200, 130)        # the part of the hall the 《那喀索斯》 close-up shows
const NARC_SCALE := 3.0
const VENUS_SHOULDER := {"left": Vector2(205, 145), "right": Vector2(315, 145)}
const VENUS_ARM_REST := {"left": Vector2(95, 312), "right": Vector2(425, 312)}   # where each arm waits
const VENUS_DROP := 46.0
# Poses (elbow, hand) for the left and right arm, in the close-up's space. Four that are not it,
# then the one that is: palms together, then a little apart, and the mirror's edge between them.
const VENUS_POSES := [
	{"name": "金苹果", "left": [Vector2(168, 108), Vector2(186, 58)], "right": [Vector2(326, 214), Vector2(318, 282)],
		"line": "s03.venus.01"},
	{"name": "比耶", "left": [Vector2(176, 204), Vector2(214, 238)], "right": [Vector2(362, 150), Vector2(322, 96)],
		"line": "s03.venus.02"},
	{"name": "思想者", "left": [Vector2(222, 232), Vector2(292, 236)], "right": [Vector2(300, 232), Vector2(276, 124)],
		"line": "s03.venus.03"},
	{"name": "盾牌", "left": [Vector2(174, 192), Vector2(150, 222)], "right": [Vector2(290, 202), Vector2(192, 230)],
		"line": "s03.venus.04"},
	{"name": "镜子", "left": [Vector2(214, 214), Vector2(256, 188)], "right": [Vector2(306, 214), Vector2(264, 188)], "line": ""}
]
const VENUS_REST_ARMS := {"left": [Vector2(194, 214), Vector2(204, 280)], "right": [Vector2(326, 214), Vector2(316, 280)]}

func _closeup_local(screen: Vector2) -> Vector2:
	var target: Rect2 = CLOSEUP_RECTS[_closeup_kind()]
	return screen - target.position

func _narc_map(p: Vector2) -> Vector2:
	return (p - NARC_REGION.position) * NARC_SCALE

## Opening the close-ups from the hall (E on the guard, 《那喀索斯》, Venus).
func _hall_open(id: String, from: Rect2) -> void:
	_open_closeup(id, from)
	if id == "narcissus":
		closeup_hand = Vector2(420, 250)

func _hall_closeup_press_e() -> void:
	if closeup == "" or closeup_closing or closeup_anim != "":
		return
	if s04_active and not s04_lines.is_empty():
		_s04_next_line()
		return
	if s04_active and _s04_closeup_press_e():
		return
	if _sensor_hall() and not s05_lines.is_empty():
		_s05_next_line()
		return
	if _sensor_hall() and _sensor_closeup_press_e():
		return
	match closeup:
		"guard":
			if s03_active and s03_hands_seen and not s03_glove_off and not blue_lake_active:
				_s01_play("glove")
				_show_dialogue(_t("s03.guard_arm.01"))
				return
		"narcissus":
			var spot := _narc_spot_at(closeup_hand)
			if spot == "lamp":
				if s03_active:
					_s03_use_picture_lamp()
				elif s02_active and not s02_completion_started:
					_s02_lamp_found_first()
				else:
					_show_dialogue(_t("s02.narcissus.01"))
				return
			if spot == "water":
				_s01_play("ripple")
				s02_ripple_left = 6.0
				chapter_state.mark_event(&"s02_water_touched")
				_show_dialogue(_t("s02.narcissus.02") if (s03_eye_lit or s03_mirror_held) else _t("s02.narcissus.03"))
				return
		"venus":
			if s03_arms_returned and not s03_mirror_held:
				_venus_next_pose()
				return
	_close_closeup()

func _hall_closeup_hint() -> String:
	if closeup_closing or closeup_anim != "":
		return ""
	if s04_active:
		return _t("hint.shared.01") if not s04_lines.is_empty() else _s04_closeup_hint()
	if _sensor_hall():
		return _t("hint.shared.01") if not s05_lines.is_empty() else _sensor_closeup_hint()
	match closeup:
		"guard":
			if s03_active and s03_hands_seen and not s03_glove_off and not blue_lake_active:
				return _t("hint.s02.01")
		"narcissus":
			return _t("hint.shared.02") if _narc_spot_at(closeup_hand) != "" else _t("hint.shared.03")
		"venus":
			if _venus_arm_waiting():
				return _t("hint.s02.02") if blue_lake_active else _t("hint.shared.04")
			if s03_arms_returned and not s03_mirror_held:
				return _t("hint.s02.03")
	return _t("hint.shared.05")

## Space in the Venus close-up: LAN's chalk drags her arms onto her shoulders. Before that (her eye
## just lit), Space puts the close-up away and borrows her eye in the hall as before.
func _hall_closeup_space() -> void:
	if closeup_closing or closeup_anim != "":
		return
	if _sensor_hall() and _sensor_closeup_space():
		return
	if closeup == "bench":
		if not blue_lake_transform_completed:
			_show_dialogue(_t("s04.bench.01"))
			return
		blue_lake_active = not blue_lake_active
		chalk_cursor.set_active(blue_lake_active)
		visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
		_show_dialogue(_t("s04.bench.02") if blue_lake_active else _t("common.put_away"))
		_update_ui()
		return
	if closeup == "venus" and _venus_arm_waiting() and blue_lake_transform_completed:
		blue_lake_active = not blue_lake_active
		chalk_cursor.set_active(blue_lake_active)
		visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
		_show_dialogue(_t("s03.venus.05") if blue_lake_active else _t("common.put_away"))
		_update_ui()
		return
	if closeup == "venus" and s03_active:
		closeup = ""
		closeup_t = 0.0
		player.input_locked = false
		_try_toggle_s03_blue_lake()
		return
	if s03_ride_active or s03_pov_active:
		return
	closeup = ""
	closeup_t = 0.0
	player.input_locked = false
	if s03_active:
		_try_toggle_s03_blue_lake()
	elif s04_active:
		_try_toggle_s04_blue_lake()
	elif s05_active:
		_try_toggle_s05_blue_lake()
	elif s06_active:
		_try_toggle_s06_blue_lake()
	elif s07_active:
		_try_toggle_s07_blue_lake()
	elif s08_active:
		_try_toggle_s08_blue_lake()

func _venus_arm_waiting() -> bool:
	return s03_active and ((s03_left_arm_ready and not s03_left_installed) or (s03_right_arm_ready and not s03_right_installed))

func _venus_grab(local: Vector2) -> void:
	for side in ["left", "right"]:
		var ready: bool = s03_left_arm_ready if side == "left" else s03_right_arm_ready
		var done: bool = s03_left_installed if side == "left" else s03_right_installed
		var rest: Vector2 = VENUS_ARM_REST[side]
		if ready and not done and local.distance_to(rest) <= 60.0:
			venus_drag = side
			return

func _venus_drop(local: Vector2) -> void:
	var side := venus_drag
	venus_drag = ""
	if side == "":
		return
	var other := "right" if side == "left" else "left"
	var stump: Vector2 = VENUS_SHOULDER[side]
	var wrong: Vector2 = VENUS_SHOULDER[other]
	if local.distance_to(stump) <= VENUS_DROP:
		_venus_install(side)
	elif local.distance_to(wrong) <= VENUS_DROP:
		_show_dialogue(_t("s03.venus.06") if side == "left" else _t("s03.venus.07"))

func _venus_install(side: String) -> void:
	if side == "left":
		s03_left_installed = true
		chapter_state.mark_event(&"s03_marble_arm_installed")
		_show_dialogue(_t("s03.venus.08"))
	else:
		s03_right_installed = true
		chapter_state.mark_event(&"s03_iron_arm_installed")
		_show_dialogue(_t("s03.venus.09"))
	if s03_left_installed and s03_right_installed:
		s03_arms_returned = true
		chapter_state.mark_event(&"s03_arms_returned")
		blue_lake_active = false
		chalk_cursor.set_active(false)
		visual_mode = "Standard"
		venus_pose = -1
		objective_label.text = _t("goal.s03.01")
		_show_dialogue(_t("s03.venus.10"))
		_update_ui()
	else:
		_s03_update_objective()

func _venus_next_pose() -> void:
	venus_pose_prev = venus_pose
	venus_pose += 1
	chapter_state.mark_event(StringName("s03_venus_pose_%d" % venus_pose))
	if venus_pose >= VENUS_POSES.size() - 1:
		venus_pose = VENUS_POSES.size() - 1
		_s01_play("mirror_pose")
		_show_dialogue(_t("s03.venus.11"))
		return
	_s01_play("pose")
	var line: String = VENUS_POSES[venus_pose].line
	_show_dialogue(_t(line))

func _venus_mirror_done() -> void:
	s03_mirror_held = true
	chapter_state.mark_event(&"s03_mirror_held")
	chapter_state.learn(&"s03_visual_is_not_reality")
	s03_mirror_line_pending = true
	objective_label.text = _t("goal.s03.02")
	_show_dialogue(_t("s03.venus.12"))

## The arms (elbow, hand) for the current pose, eased from the previous one while a pose plays.
func _venus_arms(side: String) -> Array:
	var to: Array = VENUS_REST_ARMS[side] if venus_pose < 0 else VENUS_POSES[venus_pose][side]
	var from: Array = VENUS_REST_ARMS[side] if venus_pose_prev < 0 else VENUS_POSES[venus_pose_prev][side]
	var k := 1.0
	if closeup_anim == "pose":
		k = closeup_anim_t
	elif closeup_anim == "mirror_pose":
		k = minf(1.0, closeup_anim_t / 0.4)
	k = k * k * (3.0 - 2.0 * k)
	var elbow: Vector2 = (from[0] as Vector2).lerp(to[0], k)
	var hand: Vector2 = (from[1] as Vector2).lerp(to[1], k)
	# The mirror pose: palms together, then a little apart.
	if venus_pose == VENUS_POSES.size() - 1 and (closeup_anim != "mirror_pose" or closeup_anim_t > 0.45):
		var apart := 1.0 if closeup_anim != "mirror_pose" else clampf((closeup_anim_t - 0.45) / 0.25, 0.0, 1.0)
		hand += Vector2(-8.0 if side == "left" else 8.0, 0) * apart
	return [elbow, hand]

## --- 《那喀索斯》 close-up spots (its own space, 600 × 390) -----------------------------------------
func _narc_spot_at(p: Vector2) -> String:
	if p.distance_to(_narc_map(S03_PICTURE_LAMP)) <= 34.0:
		return "lamp"
	if p.y >= 330.0 and p.y <= 372.0 and p.x >= 160.0 and p.x <= 440.0:
		return "water"
	return ""

## --- Drawing ---------------------------------------------------------------------------------------
func _draw_closeup_guard(cv: CanvasItem, sz: Vector2) -> void:
	var dark := _s02_darkness()
	var font := ThemeDB.fallback_font
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#3a3128"), true)
	var uniform := Color("#566b7a")
	var skin := Color("#bba88c")
	var marble := Color("#e8e4da")
	# Head and cap: he has not blinked in years.
	cv.draw_circle(Vector2(170, 110), 52.0, skin)
	cv.draw_rect(Rect2(110, 52, 120, 26), Color("#2d3a46"), true)
	cv.draw_rect(Rect2(100, 74, 140, 8), Color("#1f2933"), true)
	cv.draw_circle(Vector2(152, 112), 5.0, Color("#2a2420"))
	cv.draw_circle(Vector2(190, 112), 5.0, Color("#2a2420"))
	cv.draw_line(Vector2(156, 140), Vector2(186, 140), Color("#6b5a48"), 3.0)
	cv.draw_rect(Rect2(90, 160, 160, 220), uniform, true)
	cv.draw_rect(Rect2(160, 168, 20, 30), Color("#c9b16a"), true)
	# The arm he has held up for years, pointing across, out of the close-up.
	cv.draw_line(Vector2(240, 190), Vector2(360, 150), uniform, 34.0)
	var t := closeup_anim_t if closeup_anim == "glove" else (1.0 if s03_glove_off else 0.0)
	if s03_glove_off and closeup_anim != "glove":
		cv.draw_line(Vector2(360, 150), Vector2(430, 128), marble, 26.0)
		cv.draw_circle(Vector2(432, 127), 15.0, marble)
	else:
		cv.draw_line(Vector2(360, 150), Vector2(430, 128), marble.darkened(0.1), 26.0)
		var off := Vector2(60, -20) * clampf((t - 0.2) / 0.4, 0.0, 1.0)
		cv.draw_line(Vector2(360, 150) + off, Vector2(430, 128) + off, Color("#efeae0"), 30.0)
		cv.draw_circle(Vector2(434, 126) + off, 19.0, Color("#efeae0"))
		cv.draw_line(Vector2(360, 140) + off, Vector2(360, 160) + off, Color("#b8b2a6"), 2.0)
	cv.draw_string(font, Vector2(20, 30), _t("sign.s02.01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#e8dfc8"))
	if dark > 0.01:
		cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.03, 0.05, 0.55 * dark), true)
		cv.draw_arc(Vector2(170, 110), 53.0, PI * 1.1, PI * 1.6, 16, Color(1, 0.85, 0.6, 0.35 * dark), 2.0)

func _draw_closeup_narcissus(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var lit := s03_eye_lit or s03_mirror_held
	var time := Time.get_ticks_msec() * 0.001
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#4a3c2e"), true)
	var frame := Rect2(_narc_map(S02_NARCISSUS_RECT.position), S02_NARCISSUS_RECT.size * NARC_SCALE)
	cv.draw_rect(frame, Color("#b49464"), true)
	var inner := frame.grow(-21.0)
	cv.draw_rect(inner, Color("#3a2e24"), true)
	# The boy, kneeling, bent over the bottom of the frame.
	var skin := Color("#d9b89a")
	var body := PackedVector2Array()
	for p in [Vector2(310, 252), Vector2(336, 258), Vector2(340, 284), Vector2(312, 292)]:
		body.append(_narc_map(p))
	cv.draw_colored_polygon(body, Color("#8a5a3c"))
	cv.draw_circle(_narc_map(Vector2(345, 262)), 21.0, skin)
	cv.draw_line(_narc_map(Vector2(337, 266)), _narc_map(Vector2(354, 294)), skin, 9.0)
	cv.draw_rect(Rect2(_narc_map(Vector2(304, 286)), Vector2(120, 24)), Color("#5d4030"), true)
	# The water is real: it runs along the bottom of the frame.
	var water := Rect2(inner.position.x, 334, inner.size.x, inner.end.y - 334 + 14)
	cv.draw_rect(water, Color(0.25, 0.42, 0.5, 0.95), true)
	for i in range(4):
		var y := water.position.y + 5.0 + i * 7.0
		var off := sin(time * 2.0 + i) * 8.0
		cv.draw_line(Vector2(water.position.x + 10 + off, y), Vector2(water.end.x - 10 + off, y), Color(0.85, 0.95, 1.0, 0.25 + (0.35 if lit else 0.1)), 1.5)
	var ripple := closeup_anim_t if closeup_anim == "ripple" else -1.0
	if s07_active and s07_room == "s02" and not s07_found.get("s02", true):
		# A small blue-and-white fish; touched, it darts off and comes back.
		var fx := water.position.x + 40.0 + fmod(time * 30.0, water.size.x - 80.0)
		if ripple >= 0.0:
			fx += sin(ripple * PI) * 160.0
		_draw_s07_egg("s02", Vector2(fx, water.position.y + 18), 3.2, cv)
	if lit:
		# The boy's reflection, upside down; a ripple breaks it, then it settles again.
		var shake := 0.0 if ripple < 0.0 else sin(ripple * 30.0) * 10.0 * (1.0 - ripple)
		var rc := _narc_map(Vector2(345, 262))
		rc.y = water.position.y + 16.0
		cv.draw_circle(rc + Vector2(shake, 0), 13.0, Color(0.85, 0.72, 0.6, 0.6 * (1.0 if ripple < 0.0 else 0.4 + 0.6 * ripple)))
		cv.draw_circle(rc + Vector2(-shake * 0.6, 8), 9.0, Color(0.85, 0.72, 0.6, 0.3))
	if ripple >= 0.0:
		var at := Vector2(clampf(closeup_hand.x, water.position.x + 20, water.end.x - 20), water.position.y + 14)
		for k in range(3):
			var rr := (ripple * 1.2 - k * 0.2) * 150.0
			if rr > 0.0:
				var ring := PackedVector2Array()
				for i in range(25):
					var a := TAU * i / 24.0
					ring.append(at + Vector2(cos(a) * rr, sin(a) * rr * 0.12))
				cv.draw_polyline(ring, Color(0.9, 0.97, 1.0, 0.6 * (1.0 - ripple)), 2.0)
	# The picture lamp on its arm.
	var lamp := _narc_map(S03_PICTURE_LAMP)
	var mount := _narc_map(Vector2(S02_NARCISSUS_RECT.position.x + 10.0, S02_NARCISSUS_RECT.position.y))
	cv.draw_line(mount, lamp, Color("#8d7b5c"), 6.0)
	cv.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-20, -12), lamp + Vector2(20, -12), lamp + Vector2(28, 14), lamp + Vector2(-28, 14)]), Color("#c8a35a"))
	if s03_lamp_fixed:
		var hit := _narc_map(_s03_water_hit(s03_lamp_angle))
		hit.y = water.position.y
		var end := _narc_map(_s03_reflection_end(s03_lamp_angle))
		# The reflected ray only shows up to the close-up's edge: whether it reaches the prism, you see
		# from the hall.
		if end.y < 0.0:
			end = hit + (end - hit) * ((0.0 - hit.y) / (end.y - hit.y))
		var warm := Color(1.0, 0.85, 0.55, 0.45)
		cv.draw_circle(lamp + Vector2(0, 10), 18.0, Color(1.0, 0.9, 0.6, 0.6))
		cv.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-10, 12), lamp + Vector2(10, 12), hit + Vector2(14, 0), hit + Vector2(-14, 0)]), Color(1.0, 0.85, 0.55, 0.18))
		cv.draw_line(hit, end, warm, 8.0)
		cv.draw_circle(hit, 9.0, Color(1, 1, 1, 0.6))
	elif _s02_darkness() > 0.5:
		cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.03, 0.05, 0.55), true)
		# In the dark, only the water glimmers.
		for i in range(5):
			var gx := water.position.x + fmod(i * 61.0 + time * 20.0, water.size.x)
			cv.draw_circle(Vector2(gx, water.position.y + 8), 2.0, Color(0.85, 0.95, 1.0, 0.5))
	var spot := _narc_spot_at(closeup_hand) if closeup_anim == "" else ""
	if spot == "lamp":
		cv.draw_arc(lamp, 36.0, 0.0, TAU, 28, Color(1, 1, 1, 0.55), 2.0)
	elif spot == "water":
		cv.draw_rect(Rect2(160, 330, 280, 42), Color(1, 1, 1, 0.45), false, 2.0)
	_draw_closeup_hand(cv, sz.y + 70.0)
	cv.draw_string(font, Vector2(sz.x * 0.5 - 60, -10), _t("sign.s02.02"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _draw_closeup_venus(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var marble := Color("#cfc8b8")
	var rust := Color("#7c4a2c")
	var lit := s03_eye_lit or s03_mirror_held
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#2b2620") if not s03_mirror_held else Color("#5a4c3a"), true)
	cv.draw_rect(Rect2(sz.x * 0.5, 0, sz.x * 0.5, sz.y), Color(0.3, 0.45, 0.6, 0.12), true)
	cv.draw_rect(Rect2(180, 340, 80, 60), marble.darkened(0.2), true)
	cv.draw_rect(Rect2(260, 340, 80, 60), rust.darkened(0.2), true)
	var left := PackedVector2Array([Vector2(260, 120), Vector2(240, 124), Vector2(205, 140), Vector2(196, 162), Vector2(212, 192), Vector2(216, 240), Vector2(196, 290), Vector2(204, 340), Vector2(260, 340)])
	var right := PackedVector2Array()
	for p in left:
		right.append(Vector2(520.0 - p.x, p.y))
	cv.draw_colored_polygon(left, marble)
	cv.draw_colored_polygon(right, rust)
	var head_l := PackedVector2Array()
	var head_r := PackedVector2Array()
	for i in range(13):
		var a := PI * 0.5 + PI * i / 12.0
		head_l.append(Vector2(260, 88) + Vector2(cos(a), sin(a)) * 32.0)
		head_r.append(Vector2(260, 88) + Vector2(-cos(a), sin(a)) * 32.0)
	cv.draw_colored_polygon(head_l, marble)
	cv.draw_colored_polygon(head_r, rust)
	for i in range(6):
		cv.draw_circle(Vector2(268 + fmod(i * 13.0, 40.0), 160 + i * 28.0), 3.0, Color("#5a2f1a"))
	# The shoulders: two clean breaks.
	for side in ["left", "right"]:
		var s: Vector2 = VENUS_SHOULDER[side]
		cv.draw_circle(s, 13.0, (marble if side == "left" else rust).darkened(0.25))
	# 《光》: the inverted prism over her head, and the two beams crossing in her eye.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(222, 8), Vector2(298, 8), Vector2(260, 46)]), Color(0.8, 0.9, 1.0, 0.35))
	cv.draw_polyline(PackedVector2Array([Vector2(222, 8), Vector2(298, 8), Vector2(260, 46), Vector2(222, 8)]), Color(0.85, 0.95, 1.0, 0.8), 2.0)
	var eye := Vector2(260, 86)
	if lit:
		cv.draw_line(Vector2(240, 30), eye, Color(1.0, 0.85, 0.55, 0.55), 6.0)
		cv.draw_line(Vector2(280, 30), eye, Color(0.6, 0.8, 1.0, 0.55), 6.0)
		var glow := 1.0
		if closeup_anim == "mirror_pose" and closeup_anim_t > 0.7:
			glow = 1.0 + 2.0 * sin((closeup_anim_t - 0.7) / 0.3 * PI)
		cv.draw_circle(eye, 9.0 * glow, Color(1.0, 0.97, 0.85, 0.85))
		cv.draw_circle(eye, 18.0 * glow, Color(1.0, 0.95, 0.8, 0.25))
	else:
		cv.draw_circle(eye + Vector2(-12, 0), 4.0, Color("#2a2420"))
		cv.draw_circle(eye + Vector2(12, 0), 4.0, Color("#1c1410"))
	# The arms: on her, or waiting at the bottom (the guard holds the marble one; the iron one lies
	# among fallen rust leaves), or being dragged by LAN's chalk.
	for side in ["left", "right"]:
		var col := marble if side == "left" else rust
		var installed: bool = s03_left_installed if side == "left" else s03_right_installed
		var ready: bool = s03_left_arm_ready if side == "left" else s03_right_arm_ready
		var shoulder: Vector2 = VENUS_SHOULDER[side]
		if installed:
			var arm := _venus_arms(side)
			var elbow: Vector2 = arm[0]
			var hand: Vector2 = arm[1]
			cv.draw_line(shoulder, elbow, col, 22.0)
			cv.draw_line(elbow, hand, col, 18.0)
			cv.draw_circle(elbow, 10.0, col)
			cv.draw_circle(hand, 11.0, col.lightened(0.05))
		elif ready:
			var at: Vector2 = VENUS_ARM_REST[side]
			if venus_drag == side:
				at = _closeup_local(get_viewport().get_mouse_position())
			cv.draw_line(at + Vector2(-50, 10), at + Vector2(40, -8), col, 20.0)
			cv.draw_circle(at + Vector2(46, -10), 12.0, col.lightened(0.05))
			if side == "left" and venus_drag != side:
				cv.draw_circle(at + Vector2(-6, 18), 10.0, Color("#bba88c"))
				cv.draw_circle(at + Vector2(14, 14), 10.0, Color("#bba88c"))
			if blue_lake_active:
				cv.draw_arc(VENUS_SHOULDER[side], VENUS_DROP, 0.0, TAU, 28, Color(0.75, 0.91, 1.0, 0.7), 2.0)
	# The mirror's edge appears between her palms: from the front only its thickness shows.
	if s03_mirror_held or (closeup_anim == "mirror_pose" and closeup_anim_t > 0.65):
		var grow := 1.0 if s03_mirror_held else clampf((closeup_anim_t - 0.65) / 0.3, 0.0, 1.0)
		cv.draw_line(Vector2(260, 188 - 46 * grow), Vector2(260, 188 + 46 * grow), Color(0.9, 0.97, 1.0, 0.95), 3.0)
		cv.draw_line(Vector2(258, 188 - 46 * grow), Vector2(258, 188 + 46 * grow), Color(0.55, 0.65, 0.7, 0.9), 1.0)
	if closeup_anim != "pose" or closeup_anim_t > 0.5:
		_draw_venus_prop(cv)
	if not lit:
		cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.03, 0.05, 0.55), true)
	cv.draw_string(font, Vector2(sz.x * 0.5 - 80, -10), _t("sign.s02.03"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _draw_venus_prop(cv: CanvasItem) -> void:
	if venus_pose < 0 or venus_pose >= VENUS_POSES.size() - 1:
		return
	var name_now: String = VENUS_POSES[venus_pose].name
	var arm_l := _venus_arms("left")
	var arm_r := _venus_arms("right")
	var hl: Vector2 = arm_l[1]
	var hr: Vector2 = arm_r[1]
	match name_now:
		"金苹果":
			cv.draw_circle(hl + Vector2(0, -14), 13.0, Color("#e0b23c"))
			cv.draw_line(hl + Vector2(0, -27), hl + Vector2(3, -33), Color("#5b4a2a"), 2.0)
		"比耶":
			cv.draw_line(hr, hr + Vector2(-8, -24), Color("#7c4a2c"), 5.0)
			cv.draw_line(hr, hr + Vector2(6, -24), Color("#7c4a2c"), 5.0)
		"盾牌":
			var c := hl.lerp(hr, 0.5) + Vector2(-6, 8)
			cv.draw_circle(c, 50.0, Color(0.78, 0.62, 0.3, 0.9))
			cv.draw_arc(c, 50.0, 0.0, TAU, 32, Color(0.5, 0.38, 0.16), 3.0)
			cv.draw_arc(c + Vector2(-8, -6), 18.0, 0.0, TAU, 20, Color(1, 1, 1, 0.35), 3.0)

## LAN's close-ups, drawn in the blue-lake layer: #0078D7 and chalk.
func _draw_closeup_lan(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var chalk := Color(0.95, 0.97, 1.0, 0.95)
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#0078D7"), true)
	for i in range(14):
		cv.draw_string(font, Vector2(14, 22 + i * 26), ["0x0332", "rust.fe", "belt -> 0", "mirror?", "0779", "里", "if (left) right", "water.y"][i % 8], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.12))
	if closeup == "lan_tag":
		var tag := Rect2(110, 90, 200, 120)
		cv.draw_rect(tag, chalk, false, 3.0)
		cv.draw_circle(Vector2(130, 110), 8.0, Color("#0078D7"))
		cv.draw_arc(Vector2(130, 110), 8.0, 0.0, TAU, 16, chalk, 2.0)
		cv.draw_line(Vector2(130, 102), Vector2(70, 40), chalk, 2.0)
		cv.draw_string(font, Vector2(150, 130), "No.0779", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, chalk)
		cv.draw_string(font, Vector2(150, 162), _t("sign.s02.04"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, chalk)
		cv.draw_string(font, Vector2(150, 192), _t("sign.s02.05"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, chalk)
		for k in range(8):
			cv.draw_line(Vector2(120 + k * 8, 220), Vector2(120 + k * 8, 244), chalk, 1.0 + (k % 2))
		cv.draw_string(font, Vector2(sz.x * 0.5 - 60, -10), _t("sign.s02.06"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#bfe8ff"))
	else:
		var frame := Rect2(60, 30, 300, 230)
		cv.draw_rect(frame, chalk, false, 3.0)
		var skull := Vector2(250, 100)
		cv.draw_arc(skull, 26.0, 0.0, TAU, 28, chalk, 2.5)
		cv.draw_circle(skull + Vector2(-9, -2), 6.0, chalk)
		cv.draw_circle(skull + Vector2(8, -2), 6.0, chalk)
		cv.draw_line(Vector2(228, 116), Vector2(170, 196), chalk, 2.0)
		for i in range(5):
			cv.draw_line(Vector2(215 - i * 4, 140 + i * 12), Vector2(175 + i * 3, 150 + i * 12), chalk, 1.5)
		cv.draw_line(Vector2(80, 214), Vector2(340, 214), chalk, 2.0)
		# Its water reflects the boy, not the skull.
		var boy := Vector2(250, 236)
		cv.draw_arc(boy, 14.0, 0.0, TAU, 20, Color(1.0, 0.86, 0.6, 0.9), 2.0)
		cv.draw_line(boy + Vector2(-6, 2), boy + Vector2(-2, 2), Color(1.0, 0.86, 0.6, 0.9), 2.0)
		cv.draw_line(boy + Vector2(3, 2), boy + Vector2(7, 2), Color(1.0, 0.86, 0.6, 0.9), 2.0)
		cv.draw_string(font, Vector2(sz.x * 0.5 - 60, -10), _t("sign.s02.07"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#bfe8ff"))

## --- S04 close-ups ------------------------------------------------------------------------------
## 修复台 (big: Graham's gaze, WASD — the centre of the gaze sees detail and stillness, only the
## corner of the eye sees the signal move), 抹核黄素 (big: a brush on Graham's front, the joints make
## a point-light walker), 《窗》, 《戴珍珠耳机的少女》 (many faces), 参观者, 《双生》.
const S04_BENCH_STARRY := Vector2(165, 170)            # 《星空下的神经》's centre in the bench close-up
const S04_BENCH_STARRY_SCALE := 3.0
const S04_FOVEA := 58.0
# Graham's front, in the riboflavin close-up: shoulders, elbows, wrists, hips, knees, ankles (L, R).
const S04_JOINTS := [Vector2(140, 120), Vector2(220, 120), Vector2(120, 185), Vector2(240, 185), Vector2(112, 245), Vector2(248, 245),
	Vector2(155, 238), Vector2(205, 238), Vector2(150, 315), Vector2(210, 315), Vector2(148, 388), Vector2(212, 388),
	Vector2(180, 70)]
const S04_DROPS := 5
const S04_HANDS_FEET := [12, 4, 5, 10, 11]   # the points that count: face, wrists, ankles (the mouse: face and four feet)
const S04_JOINT_REACH := 40.0
const S04_BRUSH_SPEED := 420.0
const S04_RECOGNISE_JOINTS := 5
# The girl's faces, by where the story is.
const S04_GIRL_FACES := {
	"before": [["wink", "s04.girl_faces.01"], ["tongue", "s04.girl_faces.02"], ["headphones", "s04.girl_faces.03"], ["still", "s04.girl_faces.04"]],
	"repaired": [["pout", "s04.girl_faces.05"], ["eyeroll", "s04.girl_faces.06"], ["arms", "s04.girl_faces.07"]],
	"caught": [["cry", "s04.girl_faces.08"], ["lan", "s04.girl_faces.09"], ["shh", "s04.girl_faces.10"]]
}
const HYPER_FLASH_TIME := 0.9

func _s04_bench_node(i: int) -> Vector2:
	var node: Vector2 = S04_SIGNAL_NODES[i]
	return S04_BENCH_STARRY + (node - S04_STARRY_CENTER) * S04_BENCH_STARRY_SCALE

## In the bench close-up: how much of the signal shows at a point. It needs the rods (dusk or dark),
## and only the corner of the eye sees it: inside the gaze's centre it holds still.
func _s04_bench_signal_alpha(p: Vector2) -> float:
	if s04_starry_repaired:
		return 1.0
	var rods := clampf((s04_win_t - 0.25) / 0.25, 0.0, 1.0)
	var aside := clampf((p.distance_to(closeup_hand) - S04_FOVEA) / 50.0, 0.0, 1.0)
	return rods * aside

func _s04_bench_spot(p: Vector2) -> String:
	if Rect2(318, 72, 76, 100).has_point(p):
		return "front"
	if Rect2(394, 60, 70, 250).has_point(p):
		return "side"
	if s04_has_riboflavin and p.distance_to(Vector2(500, 286)) <= 26.0:
		return "bottle"
	if p.distance_to(Vector2(556, 290)) <= 26.0:
		return "uv"
	return ""

func _s04_bench_chalk(local: Vector2) -> void:
	for i in range(S04_SIGNAL_NODES.size()):
		if local.distance_to(_s04_bench_node(i)) <= 24.0:
			_s04_trace(i)
			return

func _s04_open_smear() -> void:
	s04_dabs.clear()
	s04_riboflavin_applied = false
	_open_closeup("smear", Rect2(756, 354, 40, 40))
	closeup_hand = Vector2(180, 240)
	_show_dialogue(_t("s04.smear.open", {"n": S04_DROPS}))

func _s04_dab() -> void:
	# A drop close to a joint settles right on it.
	var at := closeup_hand
	for j in S04_HANDS_FEET:
		var joint: Vector2 = S04_JOINTS[j]
		if joint.distance_to(at) <= S04_JOINT_REACH:
			at = joint
			break
	s04_dabs.append(at)
	if s04_dabs.size() < S04_DROPS:
		return
	s04_riboflavin_applied = true
	chapter_state.mark_event(&"s04_pigment_applied")
	var hits := _s04_joint_hits()
	chapter_state.mark_event(StringName("s04_pigment_joints_%d" % hits))
	var said := _t("s04.smear.done") if hits >= S04_RECOGNISE_JOINTS else _t("s04.smear.done_missed")
	if s04_mouse == "table":
		# It has watched her copy its dots; now it is off, to the visitors.
		s04_mouse = "running"
		s04_mouse_x = S04_BENCH_X + 30.0
		said += "\n" + _t("s04.mouse.07")
	_show_dialogue(said)
	closeup_closing = true

func _s04_joint_hits() -> int:
	var hits := 0
	for j in S04_JOINTS:
		var joint: Vector2 = j
		for d in s04_dabs:
			if joint.distance_to(d) <= S04_JOINT_REACH:
				hits += 1
				break
	return hits

## The girl's faces in her close-up; each E shows the next one, after the last E puts it away.
func _s04_girl_phase() -> String:
	if s04_girl_caught:
		return "caught"
	if s04_starry_repaired:
		return "repaired"
	return "before"

func _s04_girl_in_frame() -> bool:
	return not s04_girl_out

func _s04_girl_next_face() -> bool:
	if not _s04_girl_in_frame():
		if s04_girl_face >= 0:
			s04_girl_face = -1
			return false
		s04_girl_face = 0
		_show_dialogue(_t("s04.girl_faces.11"))
		return true
	var faces: Array = S04_GIRL_FACES[_s04_girl_phase()]
	s04_girl_face += 1
	if s04_girl_face >= faces.size():
		s04_girl_face = -1
		return false
	var face: Array = faces[s04_girl_face]
	chapter_state.mark_event(StringName("s04_girl_face_" + str(face[0])))
	_s01_play("face")
	_show_dialogue(_t(face[1]))
	return true

func _s04_girl_face_name() -> String:
	if s04_girl_face < 0:
		return ""
	var faces: Array = S04_GIRL_FACES[_s04_girl_phase()]
	if s04_girl_face >= faces.size():
		return ""
	return faces[s04_girl_face][0]

func _s04_window_actionable() -> bool:
	return (s04_uv_on and s04_win_t >= 0.5 and not s04_handle_found) \
		or (s04_girl_caught and not s04_frame_installed) \
		or (s04_uv_on and not chapter_state.has_event(&"s04_blue_handprint_seen"))

func _s04_closeup_press_e() -> bool:
	match closeup:
		"bench":
			var spot := _s04_bench_spot(closeup_hand)
			match spot:
				"front":
					_s04_talk_to_restorer()
					return true
				"side":
					_s04_talk_to_restorer()
					return true
				"bottle":
					if s04_mouse == "bottle":
						_s01_play("tail")
						_show_dialogue(_t("s04.bench.05"))
					elif not chapter_state.has_event(&"s04_mouse_caught") and not s04_riboflavin_applied:
						_show_dialogue(_t("s04.smear.too_early"))
					else:
						_s04_open_smear()
					return true
				"uv":
					_s04_use_uv()
					return true
		"smear":
			_s04_dab()
			return true
		"girl":
			return _s04_girl_next_face()
		"twins":
			if s04_mouse == "eating":
				_s04_scare_mouse()
				return true
		"window":
			if _s04_window_actionable():
				_s04_look_at_window()
				return true
	return false

func _s04_closeup_hint() -> String:
	match closeup:
		"bench":
			if blue_lake_active:
				return _t("hint.s04.01")
			match _s04_bench_spot(closeup_hand):
				"front":
					return _t("hint.shared.06")
				"side":
					return _t("hint.shared.06")
				"bottle":
					if s04_mouse == "bottle":
						return _t("hint.s04.03")
					return _t("hint.s04.04") if s04_riboflavin_applied else _t("hint.s04.05")
				"uv":
					return _t("hint.s04.06") if s04_uv_on else _t("hint.s04.07")
			return _t("hint.s04.08")
		"smear":
			return _t("hint.s04.smear", {"n": S04_DROPS - s04_dabs.size()})
		"girl":
			var faces: Array = S04_GIRL_FACES[_s04_girl_phase()]
			if not _s04_girl_in_frame():
				return _t("hint.s04.09") if s04_girl_face < 0 else _t("hint.shared.05")
			return _t("hint.s04.10") if s04_girl_face < faces.size() - 1 else _t("hint.shared.05")
		"twins":
			if s04_mouse == "eating":
				return _t("hint.s04.11")
		"window":
			if s04_girl_caught and not s04_frame_installed and not (s04_uv_on and s04_win_t >= 0.5 and not s04_handle_found):
				return _t("hint.s04.12")
			return _t("hint.s04.13") if _s04_window_actionable() else _t("hint.shared.05")
	return _t("hint.shared.05")

func _s04_use_uv() -> void:
	if not s04_girl_caught:
		if s04_starry_repaired:
			_show_dialogue(_t("s04.bench_tools.01"))
		else:
			_show_dialogue(_t("s04.bench_tools.02"))
		return
	s04_uv_on = not s04_uv_on
	if s04_uv_on:
		chapter_state.mark_event(&"s04_uv_on")
	_show_dialogue(_t("s04.bench_tools.03") if s04_uv_on else _t("s04.bench_tools.04"))

func _hyper_flash_start(kind: String) -> void:
	hyper_flash = kind
	hyper_flash_left = HYPER_FLASH_TIME
	chapter_state.mark_story_event(StringName("hyperreal_" + kind))

## --- Point-light walker: the riboflavin dots, under ultraviolet in the dark ----------------------
func _s04_point_light_on() -> bool:
	return s04_active and s04_riboflavin_applied and s04_uv_on and s04_win_t > 0.6 and player != null

func _s04_joint_now(j: int, phase: float) -> Vector2:
	var p: Vector2 = S04_JOINTS[j]
	var left := j % 2 == 0
	var s := sin(phase) * (1.0 if left else -1.0)
	match floori(j / 2.0):
		1:
			p += Vector2(-s * 10.0, 0)
		2:
			p += Vector2(-s * 22.0, -absf(s) * 4.0)
		4:
			p += Vector2(s * 18.0, 0)
		5:
			p += Vector2(s * 34.0, -maxf(0.0, s) * 14.0)
		6:
			p += Vector2(0, -absf(s) * 3.0)     # the face bobs a little
	return p

func _draw_point_light(cv: CanvasItem) -> void:
	if not _s04_point_light_on():
		return
	var k := 0.16
	var origin := player.position + Vector2(-180.0 * k, 26.0 - 400.0 * k)
	var now := Time.get_ticks_msec() * 0.001
	for i in range(s04_dabs.size()):
		var d: Vector2 = s04_dabs[i]
		var at := d
		var best := -1
		for j in range(S04_JOINTS.size()):
			var joint: Vector2 = S04_JOINTS[j]
			if joint.distance_to(d) <= S04_JOINT_REACH:
				best = j
				break
		if best >= 0:
			at = _s04_joint_now(best, s04_walk_phase) + (d - (S04_JOINTS[best] as Vector2))
		else:
			at = d + Vector2(sin(now * 1.7 + i) * 9.0, cos(now * 1.3 + i * 2.0) * 9.0)
		var sp := origin + at * k
		cv.draw_circle(sp, 6.0, Color(0.78, 1.0, 0.35, 0.18))
		cv.draw_circle(sp, 2.6, Color(0.9, 1.0, 0.55, 0.95))

## --- Drawing ---------------------------------------------------------------------------------------
func _draw_closeup_bench(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var now := Time.get_ticks_msec() * 0.001
	cv.draw_rect(Rect2(Vector2.ZERO, sz), _s04_c(Color("#3b4250")), true)
	# 《星空下的神经》.
	cv.draw_rect(Rect2(30, 40, 270, 260), _s04_c(Color("#b49464")), true)
	cv.draw_rect(Rect2(46, 56, 238, 228), _s04_c(Color("#2c3a5a")), true)
	cv.draw_arc(S04_BENCH_STARRY, 72.0, 0.0, 5.2, 40, _s04_c(Color("#c8c1a8")), 6.0)
	cv.draw_arc(S04_BENCH_STARRY, 36.0, 1.0, 6.0, 30, _s04_c(Color("#c8c1a8")), 4.0)
	cv.draw_circle(S04_BENCH_STARRY + Vector2(-80, -76), 7.0, _s04_c(Color("#f2e2a0")))
	cv.draw_circle(S04_BENCH_STARRY + Vector2(86, 70), 6.0, _s04_c(Color("#f2e2a0")))
	# The signal: a pulse running along the fibre, seen only with the corner of the eye.
	var pts := PackedVector2Array()
	for i in range(S04_SIGNAL_NODES.size()):
		pts.append(_s04_bench_node(i))
	for i in range(pts.size() - 1):
		var mid := pts[i].lerp(pts[i + 1], 0.5)
		cv.draw_line(pts[i], pts[i + 1], Color(0.62, 0.92, 1.0, 0.35 * _s04_bench_signal_alpha(mid)), 4.0)
	var seg := pts.size() - 1
	var f := fmod(now * 0.6, 1.0) * seg
	var si := mini(int(f), seg - 1)
	var pulse := pts[si].lerp(pts[si + 1], f - si)
	cv.draw_circle(pulse, 9.0, Color(0.75, 0.97, 1.0, 0.9 * _s04_bench_signal_alpha(pulse)))
	if blue_lake_active and not s04_signal_traced:
		for i in range(pts.size()):
			cv.draw_arc(pts[i], 16.0, 0.0, TAU, 20, Color(0.75, 0.91, 1.0, 0.25 + 0.6 * _s04_bench_signal_alpha(pts[i])), 2.0)
	for i in range(s04_signal_progress - 1):
		cv.draw_line(pts[i], pts[i + 1], Color("#dff5ff"), 5.0)
	if s04_signal_progress >= 1:
		cv.draw_circle(pts[0], 6.0, Color("#dff5ff"))
	# The restorer, facing the painting: she only sees what is right in front of her.
	var a := maxf(_s04_cone_alpha(), 0.25)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(392, 104), Vector2(448, 104), Vector2(420, 52)]), _s04_c(Color(0.85, 0.75, 0.55, a)))
	cv.draw_circle(Vector2(420, 128), 28.0, _s04_c(Color(0.8, 0.66, 0.54, a)))
	cv.draw_circle(Vector2(402, 124), 4.5, Color(0.15, 0.15, 0.2, a))
	cv.draw_rect(Rect2(388, 158, 64, 48), _s04_c(Color(0.25, 0.45, 0.85, a)), true)
	cv.draw_rect(Rect2(388, 206, 64, 48), _s04_c(Color(0.3, 0.7, 0.4, a)), true)
	cv.draw_rect(Rect2(388, 254, 64, 48), _s04_c(Color(0.85, 0.3, 0.3, a)), true)
	cv.draw_line(Vector2(390, 190), Vector2(350, 140), _s04_c(Color(0.75, 0.8, 0.85, a)), 6.0)
	cv.draw_arc(Vector2(344, 130), 14.0, 0.0, TAU, 20, _s04_c(Color(0.75, 0.9, 1.0, a)), 3.0)
	# Her workbench: the riboflavin, the ultraviolet lamp, 《窗》's empty frame.
	cv.draw_rect(Rect2(466, 300, 128, 22), _s04_c(Color("#8a7a62")), true)
	cv.draw_rect(Rect2(476, 322, 108, 60), _s04_c(Color("#665d50")), true)
	cv.draw_rect(Rect2(530, 282, 52, 14), Color(0.6, 0.35, 1.0, 0.95) if s04_uv_on else _s04_c(Color("#5c5470")), true)
	if s04_uv_on:
		cv.draw_circle(Vector2(556, 289), 40.0, Color(0.55, 0.3, 1.0, 0.25))
	if s04_has_riboflavin:
		cv.draw_rect(Rect2(490, 268, 20, 32), _s04_c(Color("#e8c832")), true)
		cv.draw_rect(Rect2(494, 260, 12, 8), _s04_c(Color("#6b5a3a")), true)
		if s04_mouse == "bottle" and closeup_anim != "tail":
			var neck := Vector2(500, 260)
			cv.draw_polyline(PackedVector2Array([neck, neck + Vector2(6, -12), neck + Vector2(18, -16), neck + Vector2(26, -6) + Vector2(sin(mouse_t * 5.0) * 2.0, 0)]), Color(0.95, 0.66, 0.7), 3.0)
		if closeup_anim == "tail":
			# Pulled out by the tail, dripping yellow; it shakes, and the paint stays only in its joints.
			var t := closeup_anim_t
			var at := Vector2(500, lerpf(262.0, 170.0, smoothstep(0.0, 0.3, t)))
			var shake := sin(t * 60.0) * 6.0 * clampf((t - 0.35) * 4.0, 0.0, 1.0) * clampf((0.7 - t) * 4.0, 0.0, 1.0)
			cv.draw_set_transform_matrix(closeup_xf * Transform2D(PI * 0.5, at + Vector2(shake, 0)))
			var coated := 1.0 - smoothstep(0.35, 0.7, t)
			_draw_mouse(cv, Vector2(28, 0), 3.2, 1.0, 1.0, smoothstep(0.45, 0.8, t), true)
			if coated > 0.0:
				cv.draw_circle(Vector2(28, -19.2), 34.0, Color(0.91, 0.78, 0.2, 0.75 * coated))
			cv.draw_set_transform_matrix(closeup_xf)
			if t > 0.4 and t < 0.75:
				for k in range(10):
					var fa := k * 0.63 + t * 3.0
					cv.draw_circle(at + Vector2(cos(fa), sin(fa)) * (30.0 + (t - 0.4) * 300.0), 3.0, Color(0.91, 0.78, 0.2, 0.8))
	if s04_mouse == "table" and closeup_anim != "tail":
		_draw_mouse(cv, Vector2(536, 297), 1.6, -1.0, 1.0, 1.0, false)
	if not s04_frame_installed:
		cv.draw_rect(Rect2(560, 180, 34, 118), _s04_c(Color("#c7a56f")), false, 6.0)
	if s04_win_t > 0.01:
		cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.03, 0.05, 0.09, 0.35 * s04_win_t), true)
	# The gaze: a soft ring around the centre of vision.
	var g := closeup_hand
	cv.draw_arc(g, S04_FOVEA, 0.0, TAU, 40, Color(1, 1, 1, 0.35), 2.0)
	cv.draw_circle(g, 3.0, Color(1, 1, 1, 0.6))
	var spot := _s04_bench_spot(g)
	if spot == "bottle":
		cv.draw_arc(Vector2(500, 286), 28.0, 0.0, TAU, 24, Color(1, 1, 1, 0.55), 2.0)
	elif spot == "uv":
		cv.draw_arc(Vector2(556, 290), 28.0, 0.0, TAU, 24, Color(1, 1, 1, 0.55), 2.0)
	cv.draw_string(font, Vector2(sz.x * 0.5 - 110, -10), _t("sign.s04_closeup.01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _draw_closeup_smear(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#2a2f3a"), true)
	# Graham, from the front: hair, face, overalls, sleeves.
	var skin := Color("#f2c6a0")
	cv.draw_circle(Vector2(180, 62), 34.0, skin)
	cv.draw_arc(Vector2(180, 56), 36.0, PI * 1.05, PI * 1.95, 18, Color("#2b3547"), 14.0)
	cv.draw_circle(Vector2(168, 64), 3.0, Color("#17202e"))
	cv.draw_circle(Vector2(192, 64), 3.0, Color("#17202e"))
	cv.draw_circle(Vector2(197, 70), 1.6, Color("#3a2a20"))   # the mole at the corner of her right eye
	cv.draw_colored_polygon(PackedVector2Array([Vector2(140, 110), Vector2(220, 110), Vector2(212, 240), Vector2(148, 240)]), Color("#4b79a8"))
	for side in [-1.0, 1.0]:
		cv.draw_line(Vector2(180 + side * 40, 120), Vector2(180 + side * 60, 185), Color("#4b79a8"), 22.0)
		cv.draw_line(Vector2(180 + side * 60, 185), Vector2(180 + side * 68, 245), Color("#4b79a8"), 18.0)
		cv.draw_circle(Vector2(180 + side * 68, 252), 11.0, skin)
		cv.draw_line(Vector2(180 + side * 25, 240), Vector2(180 + side * 30, 315), Color("#3a4a5a"), 26.0)
		cv.draw_line(Vector2(180 + side * 30, 315), Vector2(180 + side * 32, 388), Color("#3a4a5a"), 22.0)
		cv.draw_rect(Rect2(180 + side * 32 - 16, 388, 32, 14), Color("#2a2420"), true)
	# The mouse sits on the bench to be looked at: its yellow left only on its face and four feet.
	if s04_mouse == "table":
		_draw_mouse(cv, Vector2(300, 372), 2.6, -1.0, 1.0, 1.0, false)
	# The dabs of riboflavin.
	for d in s04_dabs:
		var dp: Vector2 = d
		cv.draw_circle(dp, 7.0, Color(0.91, 0.78, 0.2, 0.9))
	# The brush.
	var b := closeup_hand
	cv.draw_line(b, b + Vector2(36, -48), Color("#8a6a3a"), 5.0)
	cv.draw_circle(b, 6.0, Color(0.91, 0.78, 0.2, 1.0))
	cv.draw_string(font, Vector2(sz.x - 110, 30), "%d / %d" % [s04_dabs.size(), S04_DROPS], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#e8c832"))
	cv.draw_string(font, Vector2(sz.x * 0.5 - 50, -10), _t("sign.s04_closeup.02"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _draw_closeup_s04_girl(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	cv.draw_rect(Rect2(Vector2.ZERO, sz), _s04_c(Color("#b49464")), true)
	cv.draw_rect(Rect2(Vector2(22, 22), sz - Vector2(44, 44)), _s04_c(Color("#20242c")), true)
	var c := Vector2(sz.x * 0.5, 170)
	if not _s04_girl_in_frame():
		# An empty chair, and a trail of small yellow footprints out of the frame.
		cv.draw_rect(Rect2(c.x - 40, 230, 80, 12), _s04_c(Color("#6b4a2a")), true)
		cv.draw_line(Vector2(c.x - 34, 242), Vector2(c.x - 34, 300), _s04_c(Color("#6b4a2a")), 6.0)
		cv.draw_line(Vector2(c.x + 34, 242), Vector2(c.x + 34, 300), _s04_c(Color("#6b4a2a")), 6.0)
		cv.draw_rect(Rect2(c.x - 40, 150, 10, 80), _s04_c(Color("#6b4a2a")), true)
		for i in range(6):
			var fp := Vector2(c.x + 10 + i * 26, 330 + (i % 2) * 14)
			cv.draw_circle(fp, 6.0, Color(0.91, 0.78, 0.2, 0.85))
		_s07_girl_paper(cv, sz)
		cv.draw_string(font, Vector2(sz.x * 0.5 - 90, -10), _t("sign.s04_closeup.03"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))
		return
	var face := _s04_girl_face_name()
	var t := closeup_anim_t if closeup_anim == "face" else 1.0
	var dusk := clampf(1.0 - absf(s04_win_t - 0.5) * 4.0, 0.0, 1.0)
	var skin := _s04_c(Color("#e2c3a3"))
	# Shoulders, the yellow dress.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 90, 340), Vector2(c.x + 90, 340), Vector2(c.x + 70, 240), Vector2(c.x - 70, 240)]), _s04_c(Color("#d9b23a")))
	var head := c + Vector2(0, -10)
	if face == "still":
		head += Vector2(0, -6) * t
	cv.draw_circle(head, 62.0, skin)
	# The blue headscarf; the earphone (the "pearl"), off in one face.
	cv.draw_colored_polygon(PackedVector2Array([head + Vector2(-70, -10), head + Vector2(-30, -78), head + Vector2(46, -64), head + Vector2(20, -12)]), _s04_c(Color("#2f5fb8")))
	if s04_uv_on:
		cv.draw_colored_polygon(PackedVector2Array([head + Vector2(-70, -10), head + Vector2(-30, -78), head + Vector2(46, -64), head + Vector2(20, -12)]), Color(0.78, 1.0, 0.35, 0.7))
	var ear := head + Vector2(58, 18)
	if face == "headphones":
		ear = head + Vector2(70, 60).lerp(Vector2(58, 18), absf(sin(t * PI)))
	cv.draw_circle(ear, 16.0, _s04_c(Color("#eeeadc")).lerp(Color(0.4, 0.75, 1.0), dusk))
	cv.draw_arc(head + Vector2(0, -6), 64.0, PI * 1.2, PI * 1.9, 16, _s04_c(Color("#5a5a5a")), 5.0)
	# Eyes.
	var eye_col := _s04_c(Color("#3a2a20")).lerp(Color(0.25, 0.55, 1.0), dusk)
	var le := head + Vector2(-22, -6)
	var re := head + Vector2(22, -6)
	match face:
		"wink":
			cv.draw_circle(le, 7.0, eye_col)
			cv.draw_arc(re + Vector2(0, 2), 9.0, PI * 1.1, PI * 1.9, 10, eye_col, 3.0)
		"eyeroll":
			cv.draw_circle(le, 9.0, Color("#f4f0e6"))
			cv.draw_circle(re, 9.0, Color("#f4f0e6"))
			cv.draw_circle(le + Vector2(0, -5), 5.0, eye_col)
			cv.draw_circle(re + Vector2(0, -5), 5.0, eye_col)
		"cry":
			cv.draw_arc(le, 8.0, PI * 0.1, PI * 0.9, 10, eye_col, 3.0)
			cv.draw_arc(re, 8.0, PI * 0.1, PI * 0.9, 10, eye_col, 3.0)
			var tear := Color(0.78, 1.0, 0.35, 0.9) if s04_uv_on else Color(0.7, 0.85, 1.0, 0.9)
			cv.draw_line(le + Vector2(0, 8), le + Vector2(-2, 40 * t), tear, 3.0)
			cv.draw_line(re + Vector2(0, 8), re + Vector2(2, 40 * t), tear, 3.0)
		"lan":
			cv.draw_circle(le, 9.0, eye_col)
			cv.draw_circle(re, 9.0, eye_col)
			cv.draw_circle(le + Vector2(-3, -3), 2.5, Color(1, 1, 1, 0.9))
			cv.draw_circle(re + Vector2(-3, -3), 2.5, Color(1, 1, 1, 0.9))
		_:
			cv.draw_circle(le, 7.0, eye_col)
			cv.draw_circle(re, 7.0, eye_col)
	cv.draw_circle(head + Vector2(30, 6), 2.0, Color("#3a2a20"))
	# Mouth.
	var lips := _s04_c(Color("#c0303a")).lerp(Color(0.12, 0.1, 0.12), dusk)
	var m := head + Vector2(4, 30)
	match face:
		"tongue":
			cv.draw_circle(m, 9.0, lips)
			cv.draw_circle(m + Vector2(0, 8 * t), 7.0, Color("#e07a8a"))
		"pout":
			cv.draw_circle(m + Vector2(4, 0), 7.0, lips)
		"still":
			cv.draw_line(m + Vector2(-10, 0), m + Vector2(10, 0), lips, 3.0)
		"cry":
			cv.draw_arc(m + Vector2(0, 8), 10.0, PI * 1.15, PI * 1.85, 10, lips, 3.0)
		"lan":
			cv.draw_arc(m, 12.0, PI * 0.15, PI * 0.85, 12, lips, 4.0)
		"shh":
			cv.draw_circle(m, 6.0, lips)
			cv.draw_line(m + Vector2(0, 30), m + Vector2(0, -16), skin.darkened(0.08), 9.0)
		_:
			cv.draw_arc(m, 9.0, PI * 0.2, PI * 0.8, 10, lips, 4.0)
	if face == "arms":
		cv.draw_line(Vector2(c.x - 80, 300), Vector2(c.x + 60, 280), skin.darkened(0.05), 22.0)
		cv.draw_line(Vector2(c.x + 80, 300), Vector2(c.x - 60, 280), skin.darkened(0.12), 22.0)
	if s04_girl_caught and s04_uv_on and face != "cry":
		cv.draw_line(le + Vector2(0, 8), le + Vector2(-2, 40), Color(0.78, 1.0, 0.35, 0.8), 2.0)
		cv.draw_line(re + Vector2(0, 8), re + Vector2(2, 40), Color(0.78, 1.0, 0.35, 0.8), 2.0)
	_s07_girl_paper(cv, sz)
	cv.draw_string(font, Vector2(sz.x * 0.5 - 90, -10), _t("sign.s04_closeup.03"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

## S07: a corner of paper behind the frame (her drawing); E pulls it out.
func _s07_girl_paper(cv: CanvasItem, sz: Vector2) -> void:
	if not (s07_active and s07_room == "s04" and not s07_found.get("s04", true)):
		return
	var out := closeup_anim_t if closeup_anim == "peel" else 0.0
	var corner := Vector2(sz.x - 34, sz.y - 54) + Vector2(70, 30) * out
	cv.draw_colored_polygon(PackedVector2Array([corner, corner + Vector2(40, -6), corner + Vector2(46, 34), corner + Vector2(4, 40)]), Color("#f4f6f8"))
	cv.draw_line(corner + Vector2(12, 10), corner + Vector2(20, 26), Color("#2f86e0"), 2.0)
	cv.draw_circle(corner + Vector2(30, 18), 5.0, Color("#2f86e0"))

func _draw_closeup_window(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.05, 0.06, 0.08), true)
	var pane := Rect2(60, 40, 300, 320)
	if s04_frame_installed:
		cv.draw_rect(pane.grow(18), _s04_c(Color("#c7a56f")), false, 24.0)
	# Inside the painting, only a window: sky and grass.
	cv.draw_rect(Rect2(pane.position, Vector2(pane.size.x, pane.size.y * 0.62)), _s04_c(Color("#8fc3ea")), true)
	cv.draw_rect(Rect2(pane.position + Vector2(0, pane.size.y * 0.62), Vector2(pane.size.x, pane.size.y * 0.38)), _s04_c(Color("#6aa85a")), true)
	cv.draw_rect(pane, Color(1.0, 0.9, 0.62, 0.2).lerp(Color(0.2, 0.25, 0.35, 0.45), s04_win_t), true)
	cv.draw_line(Vector2(pane.get_center().x, pane.position.y), Vector2(pane.get_center().x, pane.end.y), _s04_c(Color("#8a6a4a")), 8.0)
	cv.draw_line(Vector2(pane.position.x, pane.get_center().y - 16), Vector2(pane.end.x, pane.get_center().y - 16), _s04_c(Color("#8a6a4a")), 8.0)
	var cover: float = 0.14 + 0.86 * s04_win_t
	var half: float = pane.size.x * 0.5 * cover
	cv.draw_rect(Rect2(pane.position, Vector2(half, pane.size.y)), _s04_c(Color("#8a3b3b")), true)
	cv.draw_rect(Rect2(Vector2(pane.end.x - half, pane.position.y), Vector2(half, pane.size.y)), _s04_c(Color("#8a3b3b")), true)
	var handle := Vector2(pane.end.x - 40, pane.get_center().y)
	if s04_handle_found:
		cv.draw_rect(Rect2(handle - Vector2(9, 30), Vector2(18, 60)), Color("#f6e5a7"), true)
	elif s04_uv_on:
		cv.draw_rect(Rect2(handle - Vector2(30, 46), Vector2(60, 92)), Color(0.78, 1.0, 0.35, 0.75), true)
		cv.draw_rect(Rect2(handle - Vector2(9, 30), Vector2(18, 60)), Color(0.2, 0.3, 0.15, 0.8), true)
	if s04_uv_on:
		cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.42, 0.22, 0.9, 0.12), true)
		# The blind spot: LAN's blue handprint in the middle.
		var bp := pane.get_center() + Vector2(-10, -70)
		var blue := Color(0.0, 0.47, 0.84, 0.9)
		cv.draw_circle(bp + Vector2(0, 18), 24.0, blue)
		for k in range(4):
			cv.draw_line(bp + Vector2(-18 + k * 12, 0), bp + Vector2(-24 + k * 15, -33 + absf(k - 1.5) * 6.0), blue, 9.0)
		cv.draw_line(bp + Vector2(21, 18), bp + Vector2(39, 0), blue, 9.0)
		if s04_girl_caught:
			var gp := pane.get_center() + Vector2(-60, 60)
			cv.draw_circle(gp, 16.0, Color(0.78, 1.0, 0.35, 0.6))
	cv.draw_string(font, Vector2(sz.x * 0.5 - 30, -10), _t("sign.s04_closeup.04"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _draw_closeup_visitor(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var now := Time.get_ticks_msec() * 0.001
	var rod_a := maxf(_s04_rod_alpha(), 0.3)
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.06, 0.07, 0.1), true)
	var x := sz.x * 0.5 + sin(now * 1.3) * 4.0 * rod_a
	var col := Color(0.49, 0.56, 0.64, rod_a)
	cv.draw_rect(Rect2(x - 40, 170, 80, 220), col, true)
	# A head like a stack of plates; no face.
	for k in range(5):
		cv.draw_rect(Rect2(x - 55 + sin(now * 0.8 + k) * 3.0, 60 + k * 20, 110, 14), Color(0.6, 0.66, 0.74, rod_a), true)
	cv.draw_circle(Vector2(x, 120), 30.0, Color(0.7, 0.74, 0.8, rod_a * 0.3))
	if s04_visitors_recognized:
		cv.draw_circle(Vector2(x, 120), 14.0, Color(1.0, 0.9, 0.6, 0.7))
		cv.draw_circle(Vector2(x, 120), 28.0, Color(1.0, 0.9, 0.6, 0.18))
	cv.draw_string(font, Vector2(sz.x * 0.5 - 40, -10), _t("sign.s04_closeup.05"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _draw_closeup_twins(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.12, 0.13, 0.16), true)
	cv.draw_rect(Rect2(sz.x * 0.5 - 70, 220, 140, 110), _s04_c(Color("#4b5966")), true)
	var bitten := chapter_state.has_event(&"s04_mouse_eating")
	_draw_apple(cv, Vector2(sz.x * 0.5 - 48, 160), 52.0, Color(0.82, 0.12, 0.12, _s04_cone_alpha()), bitten)
	_draw_apple(cv, Vector2(sz.x * 0.5 + 48, 160), 52.0, Color(0.55, 0.8, 0.5, _s04_rod_alpha()), bitten)
	if s04_mouse == "eating":
		_draw_mouse(cv, Vector2(sz.x * 0.5 + 6, 216 + sin(mouse_t * 18.0) * 2.0), 3.0, -1.0, 1.0, 0.0, false)
	cv.draw_rect(Rect2(sz.x * 0.5 - 90, 300, 180, 26), _s04_c(Color("#c9b16a")), true)
	if s04_uv_on:
		cv.draw_string(font, Vector2(sz.x * 0.5 - 84, 318), _t("sign.s04_closeup.06"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.78, 1.0, 0.35, 0.95))
		cv.draw_string(font, Vector2(sz.x * 0.5 + 10, 320), _t("sign.s04_closeup.07"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.78, 1.0, 0.35, 0.95))
	else:
		cv.draw_string(font, Vector2(sz.x * 0.5 - 40, 318), _t("sign.s04_closeup.08"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.2, 0.16, 0.1))
	cv.draw_string(font, Vector2(sz.x * 0.5 - 30, -10), _t("sign.s04_closeup.09"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

## The door in S03, opening toward the viewer: beyond it, another Graham, from behind, pushing open
## the far door at the same moment.
func _draw_closeup_swap(cv: CanvasItem, sz: Vector2) -> void:
	var t := closeup_anim_t if closeup_anim == "swap" else 1.0
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#2b2620"), true)
	var frame := Rect2(70, 50, 220, 340)
	cv.draw_rect(frame, Color("#5a4636"), true)
	var opening := frame.grow(-14)
	cv.draw_rect(opening, Color(0.75, 0.8, 0.86), true)
	# Beyond the door: the cold 里 side, and Graham from behind, pushing the far door.
	var far := Rect2(opening.get_center() - Vector2(30, 70), Vector2(60, 140))
	cv.draw_rect(far, Color("#6f7a80"), true)
	var g := Vector2(opening.get_center().x, far.end.y - 4)
	cv.draw_rect(Rect2(g + Vector2(-9, -34), Vector2(18, 28)), Color("#4b79a8"), true)
	cv.draw_circle(g + Vector2(0, -42), 9.0, Color("#2b3547"))
	cv.draw_line(g + Vector2(8, -28), g + Vector2(22, -40), Color("#4b79a8"), 5.0)
	var far_open := clampf((t - 0.5) / 0.4, 0.0, 1.0)
	cv.draw_rect(Rect2(far.position, Vector2(far.size.x * (1.0 - far_open), far.size.y)), Color("#4a535a"), true)
	# This side's door swings toward the viewer.
	var swing := clampf(t / 0.6, 0.0, 1.0)
	var free_x := lerpf(opening.end.x, opening.position.x - 150.0, swing)
	var bulge := 60.0 * swing
	var door := PackedVector2Array([opening.position, Vector2(free_x, opening.position.y - bulge), Vector2(free_x, opening.end.y + bulge), Vector2(opening.position.x, opening.end.y)])
	if free_x > opening.position.x + 1.0:
		cv.draw_colored_polygon(door, Color("#7a5236"))
	elif free_x < opening.position.x - 1.0:
		cv.draw_colored_polygon(PackedVector2Array([door[0], door[3], door[2], door[1]]), Color("#8a6040"))

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
	_draw_s02_mouse()
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
	draw_string(ThemeDB.fallback_font, Vector2(116, 175), _t("sign.s02.08"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d8c7a8"))
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
		draw_string(ThemeDB.fallback_font, Vector2(door.position.x + 12, door.position.y - 6), _t("sign.s02.09"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d9d4b6"))
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
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 12, r.end.y + 38), _t("sign.s02.02"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
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
	if not cold and s02_ripple_left > 0.0:
		var k := 1.0 - s02_ripple_left / 6.0
		for i in range(3):
			var rr := fmod(k * 3.0 + i * 0.33, 1.0) * 30.0
			draw_arc(Vector2(330, r.position.y + 2.0), rr, 0.0, PI, 12, Color(0.9, 0.97, 1.0, 0.6 * (1.0 - k)), 1.0)
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
		draw_string(ThemeDB.fallback_font, Vector2(gx - 18, 290), _t("sign.s02.01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e8dfc8"))
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
	draw_string(ThemeDB.fallback_font, Vector2(ax - 44, 392), _t("sign.s02.10"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))

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
	draw_string(ThemeDB.fallback_font, Vector2(ax - 78, 168), _t("sign.s02.11"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
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
	draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 16, r.position.y + 24), _t("sign.s02.12"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bfe8ff"))

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
	draw_string(ThemeDB.fallback_font, Vector2(100, 175), _t("sign.s04.01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, _s04_c(Color("#b8c7d4")))
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
	draw_string(ThemeDB.fallback_font, Vector2(150, 278), _t("sign.s04.02"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.88, 0.92, maxf(rod_a, 0.35)))
	draw_string(ThemeDB.fallback_font, Vector2(935, 278), _t("sign.s04.03"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.88, 0.92, maxf(rod_a, 0.35)))
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
	_draw_s04_mouse()
	if s04_active and player and s04_riboflavin_applied and s04_uv_on and not _s04_point_light_on():
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
		draw_string(ThemeDB.fallback_font, Vector2(570, 362), _t("sign.s04.04"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e8dfc8"))
	if s04_active and s04_window_seen:
		draw_string(ThemeDB.fallback_font, Vector2(w.x - 62.0, 220), _t({"cone": "sign.s04.preset_cone", "mid": "sign.s04.preset_mid", "rod": "sign.s04.preset_rod"}[s04_window]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#bfe8ff") if blue_lake_active else Color("#9fb0bf"))
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
	draw_string(ThemeDB.fallback_font, Vector2(c.x - 45.0, 352), _t("sign.s04.05"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
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
	draw_string(ThemeDB.fallback_font, Vector2(x - 20, 276), _t("sign.s04.06"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.91, 0.87, 0.78, maxf(cone_a, 0.35)))

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
	draw_string(ThemeDB.fallback_font, Vector2(x - 20, 392), _t("sign.s04.07"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))

func _draw_s04_girl_painting(t: float) -> void:
	var x := S04_GIRL_FRAME_X
	draw_rect(Rect2(x - 45, 225, 90, 90), _s04_c(Color("#b49464")), true)
	draw_rect(Rect2(x - 38, 232, 76, 76), _s04_c(Color("#20242c")), true)
	if not s04_girl_out:
		var dusk := clampf(1.0 - absf(t - 0.5) * 4.0, 0.0, 1.0)   # strongest at the dusk window
		draw_rect(Rect2(x - 14, 280, 28, 28), _s04_c(Color("#d9b23a")), true)
		draw_circle(Vector2(x, 266), 14.0, _s04_c(Color("#e2c3a3")))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 16, 262), Vector2(x - 6, 246), Vector2(x + 12, 250), Vector2(x + 4, 262)]), _s04_c(Color("#2f5fb8")))
		if s04_uv_on:
			# Her headscarf is painted with riboflavin: under ultraviolet it glows.
			draw_colored_polygon(PackedVector2Array([Vector2(x - 16, 262), Vector2(x - 6, 246), Vector2(x + 12, 250), Vector2(x + 4, 262)]), Color(0.78, 1.0, 0.35, 0.7))
		# Purkinje shift: at dusk the red lips go dark and the blue earphone lights up; her eyes turn blue.
		draw_circle(Vector2(x + 3, 274), 2.5, _s04_c(Color("#c0303a")).lerp(Color(0.12, 0.1, 0.12), dusk))
		draw_circle(Vector2(x + 13, 268), 4.5, _s04_c(Color("#eeeadc")).lerp(Color(0.4, 0.75, 1.0), dusk))
		var eye := _s04_c(Color("#3a2a20")).lerp(Color(0.25, 0.55, 1.0), dusk)
		draw_circle(Vector2(x - 4, 264), 1.8, eye)
		draw_circle(Vector2(x + 5, 264), 1.8, eye)
		if s04_uv_on and s04_girl_caught:
			draw_line(Vector2(x - 4, 267), Vector2(x - 5, 278), Color(0.78, 1.0, 0.35, 0.8), 1.5)
			draw_line(Vector2(x + 5, 267), Vector2(x + 6, 278), Color(0.78, 1.0, 0.35, 0.8), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(x - 44, 352), _t("sign.s04.08"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))

func _draw_s04_girl_walking(x: float, rod_a: float) -> void:
	# Out of her frame: a small grey shadow that moves (rod layer); when the bright window
	# catches her she holds still, in full colour (cone layer).
	var a := 1.0 if s04_girl_frozen else maxf(rod_a, 0.0)
	if a <= 0.01:
		return
	var bob := 0.0 if s04_girl_frozen else sin(Time.get_ticks_msec() * 0.012) * 1.5
	draw_rect(Rect2(x - 8, 442 + bob, 16, 26), _s04_c(Color(0.85, 0.7, 0.23, a)), true)
	draw_circle(Vector2(x, 434 + bob), 8.0, _s04_c(Color(0.89, 0.76, 0.64, a)))
	draw_colored_polygon(PackedVector2Array([Vector2(x - 9, 432 + bob), Vector2(x - 3, 423 + bob), Vector2(x + 7, 425 + bob), Vector2(x + 3, 432 + bob)]), Color(0.78, 1.0, 0.35, 0.9) if s04_uv_on else _s04_c(Color(0.18, 0.37, 0.72, a)))
	draw_circle(Vector2(x + 7, 436 + bob), 2.5, _s04_c(Color(0.93, 0.92, 0.86, a)))

func _draw_s04_twins(cone_a: float, rod_a: float) -> void:
	# 《双生》: two apples side by side. The red one lives in the bright layer (cones), the green one in
	# the dark (rods: in dim light green looks brighter and red goes black). Only at dusk are both there.
	var x := S04_TWINS_X
	draw_rect(Rect2(x - 20, 326, 40, 46), _s04_c(Color("#4b5966")), true)
	var bitten := chapter_state.has_event(&"s04_mouse_eating")
	_draw_apple(self, Vector2(x - 10, 314), 11.0, Color(0.82, 0.12, 0.12, cone_a), bitten)
	_draw_apple(self, Vector2(x + 10, 314), 11.0, Color(0.55, 0.8, 0.5, rod_a), bitten)
	if s04_uv_on:
		draw_line(Vector2(x - 16, 362), Vector2(x - 4, 358), Color(0.78, 1.0, 0.35, 0.8), 1.5)
		draw_line(Vector2(x + 4, 360), Vector2(x + 16, 364), Color(0.78, 1.0, 0.35, 0.8), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(x - 18, 392), _t("sign.s04.09"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))

func _draw_apple(ci: CanvasItem, c: Vector2, r: float, col: Color, bitten: bool) -> void:
	if col.a <= 0.01:
		return
	ci.draw_circle(c, r, col)
	ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.35), r * 0.25, Color(1, 1, 1, 0.35 * col.a))
	ci.draw_line(c + Vector2(0, -r * 0.9), c + Vector2(r * 0.15, -r * 1.45), Color(0.35, 0.22, 0.12, col.a), maxf(r * 0.12, 1.0))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.15, -r * 1.3), c + Vector2(r * 0.6, -r * 1.6), c + Vector2(r * 0.45, -r * 1.2)]), Color(0.3, 0.55, 0.25, col.a))
	if bitten:
		ci.draw_circle(c + Vector2(r * 0.85, r * 0.1), r * 0.38, Color(0.93, 0.88, 0.74, col.a))
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
	# Above the close-ups (z 50): LAN's chalk is used inside Venus's and the bench's close-ups too.
	chalk_cursor.z_index = 100
	add_child(chalk_cursor)

func _build_transition() -> void:
	transition = TransitionScript.new()
	transition.finished.connect(_finish_transition)
	add_child(transition)

func _build_blue_lake_transform() -> void:
	blue_lake_transform = BlueLakeTransformScript.new()
	blue_lake_transform.finished.connect(_finish_blue_lake_transformation)
	add_child(blue_lake_transform)

## Close-ups are drawn on their own layer so they cover Graham; the map's maze is built here too.
func _build_closeup_layer() -> void:
	closeup_layer = Node2D.new()
	closeup_layer.name = "Closeup"
	closeup_layer.z_index = 50
	add_child(closeup_layer)
	closeup_layer.draw.connect(_draw_closeup)
	for path in S01_MAZE_PATHS:
		for i in range(path.size() - 1):
			var a: Vector2i = path[i]
			var b: Vector2i = path[i + 1]
			_s01_maze_link(a, b)
	s01_maze_path.clear()
	s01_maze_path.append(S01_MAZE_START)

func _start_blue_lake_intro() -> void:
	blue_lake_intro_started = true
	player.input_locked = true
	_show_dialogue(_t("legacy.flow.02"))
	await get_tree().create_timer(0.75).timeout
	_show_dialogue(_t("legacy.flow.03"))
	await get_tree().create_timer(0.85).timeout
	_show_dialogue(_t("legacy.flow.04"))
	await get_tree().create_timer(0.85).timeout
	blue_lake_intro_ready = true
	player.input_locked = false
	_show_space_prompt()

func _show_space_prompt() -> void:
	if not interaction_hint_label:
		return
	space_prompt_visible = true
	interaction_hint_label.text = _t("hint.general.02")
	interaction_hint_label.position = Vector2(500, 455)
	interaction_hint_label.show()
	var prompt_timer := get_tree().create_timer(4.0)
	prompt_timer.timeout.connect(_hide_space_prompt)

func _hide_space_prompt() -> void:
	space_prompt_visible = false
	if interaction_hint_label and not blue_lake_active:
		interaction_hint_label.hide()

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_needs_e and event.is_action_pressed("interact") and (_dlg_has_more() or dlg_wait_ack):
		_dlg_page()
		return
	if not LEGACY_PROTOTYPE_FLOW_ENABLED:
		if closeup != "":
			if event.is_action_pressed("interact") and Engine.get_process_frames() - hand_drawn_frame <= 2:
				touch_pulse_t = 0.0
				touch_pulse_at = closeup_hand
			if s01_active:
				_s01_closeup_input(event)
			elif closeup == "eyepiece" and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
				_s05_lens_step(1 if event.is_action_pressed("move_right") else -1)
			elif event.is_action_pressed("interact"):
				_hall_closeup_press_e()
			elif event.is_action_pressed("blue_lake"):
				_hall_closeup_space()
			return
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
		_show_dialogue(_t("legacy.flow.lake_mode_on") if blue_lake_active else _t("legacy.flow.lake_mode_off"))
		_update_ui()
	if event.is_action_pressed("interact"):
		_try_interact()

func _start_blue_lake_transformation() -> void:
	blue_lake_intro_ready = false
	player.input_locked = true
	_hide_space_prompt()
	_show_dialogue(_t("common.lake.01"))
	blue_lake_transform.play()

func _finish_blue_lake_transformation() -> void:
	blue_lake_active = true
	blue_lake_transform_completed = true
	blue_lake_intro_ready = true
	visual_mode = "Chalk Interaction"
	chalk_cursor.set_active(true)
	player.input_locked = false
	if s03_active:
		_show_dialogue(_t("s03.lake.01"))
	elif s04_active:
		_show_dialogue(_t("s04.lake.chalk_window"))
	elif s05_active:
		_show_dialogue(_t("s05.lake.01"))
	elif s06_active:
		_show_dialogue(_t(_s06_chalk_hint()))
	elif s07_active:
		_show_dialogue(_t("s07.windows.chalk_hall") if s07_room == "hall" else _t("s07.windows.chalk_room"))
	else:
		_show_dialogue(_t("common.lake.02"))
	_update_ui()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if closeup == "smear" and not closeup_closing and closeup_anim == "" and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		closeup_hand = _closeup_local(event.position)
		_s04_dab()
		return
	if not blue_lake_active or transition_started:
		return
	if closeup != "":
		var mb := event as InputEventMouseButton
		if closeup == "venus" and mb and mb.button_index == MOUSE_BUTTON_LEFT and closeup_anim == "" and not closeup_closing:
			var local := _closeup_local(mb.position)
			if mb.pressed:
				_venus_grab(local)
			else:
				_venus_drop(local)
		elif closeup == "bench" and mb and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not closeup_closing:
			_s04_bench_chalk(_closeup_local(mb.position))
		elif _sensor_hall():
			_sensor_closeup_mouse(mb)
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
			_show_dialogue(_t("legacy.flow.05"))
		else:
			_interact_mirror()
	elif nearest == "Painting":
		_interact_painting()
	elif nearest == "Window":
		if blue_lake_active:
			_show_dialogue(_t("legacy.flow.06"))
		else:
			_interact_window()
	else:
		_show_dialogue(_t("legacy.flow.07"))

func _try_s01_interact() -> void:
	if not s01_active or scene_state != "gallery" or transition_started or s01_eyelid_closed:
		return
	if closeup != "":
		_s01_closeup_press_e()
		return
	var nearest := _get_nearest_s01_interactable()
	if nearest.is_empty():
		return
	s01_idle_time = 0.0
	var object_name: String = nearest.get("name", "")
	match object_name:
		"EntrancePhoto":
			chapter_state.mark_event(&"s01_photo_observed")
			_open_closeup("photo", S01_PHOTO_RECT)
			closeup_hand = S01_HAND_START
			_show_dialogue(_s01_photo_text())
		"CommunityMap":
			chapter_state.mark_event(&"s01_map_observed")
			_open_closeup("map", S01_MAP_RECT)
			_show_dialogue(_s01_map_text())
		"ClockBack", "ClockForward":
			_open_closeup("clock_back" if object_name == "ClockBack" else "clock_forward", S01_CLOCKS_RECT)
			_s01_turn_clock(object_name == "ClockForward")
		"ExitDoor":
			if s01_gate_open:
				_enter_s02_after_s01()
				return
			_open_closeup("door", Rect2(680, 250, 80, 122))
			_show_dialogue(_s01_door_text())
		"NotAnEye":
			_s01_look_at_eye()

## --- Close-ups (特写) -------------------------------------------------------------------------
## E opens a close-up: the thing grows from where it hangs to the middle of the screen. If there is
## something to do in it, E does that; otherwise (and afterwards) E puts it away. Graham stands still
## while she looks. A "big" close-up (the map) also takes WASD.
func _open_closeup(id: String, from: Rect2) -> void:
	closeup = id
	closeup_t = 0.0
	closeup_age = 0.0
	closeup_closing = false
	closeup_from = from
	closeup_anim = ""
	closeup_anim_t = 0.0
	if player:
		player.input_locked = true

func _close_closeup() -> void:
	if closeup == "" or closeup_anim != "":
		return
	closeup_closing = true

func _closeup_kind() -> String:
	if closeup.begins_with("clock"):
		return "clocks"
	if closeup.begins_with("lan_"):
		return "lan"
	return closeup

func _update_closeup(delta: float) -> void:
	if closeup_layer:
		closeup_layer.queue_redraw()
	s02_ripple_left = maxf(0.0, s02_ripple_left - delta)
	hyper_flash_left = maxf(0.0, hyper_flash_left - delta)
	s05_lens_pos = move_toward(s05_lens_pos, float(s05_lens_notch), delta * 5.0)
	mouse_t += delta
	if touch_pulse_t >= 0.0:
		touch_pulse_t += delta
		if touch_pulse_t > 0.3:
			touch_pulse_t = -1.0
	if s03_crossed and s02_mouse_run < 600.0:
		s02_mouse_run += delta * (player.speed if player else 200.0)
	if closeup == "":
		return
	if closeup_closing:
		closeup_t = maxf(0.0, closeup_t - delta / CLOSEUP_CLOSE_TIME)
		if closeup_t <= 0.0:
			var was := closeup
			closeup = ""
			closeup_closing = false
			venus_drag = ""
			s06_drag = ""
			if player and not s01_eyelid_closed:
				player.input_locked = false
			if was in ["venus", "pile", "rack"] and blue_lake_active:
				blue_lake_active = false
				chalk_cursor.set_active(false)
				visual_mode = "Standard"
				_update_ui()
			if s03_mirror_line_pending:
				s03_mirror_line_pending = false
				_show_dialogue(_t("s03.cross.01"))
		return
	closeup_t = minf(1.0, closeup_t + delta / CLOSEUP_OPEN_TIME)
	closeup_age += delta
	# Big close-ups: WASD moves Graham's hand over the photo or 《那喀索斯》.
	# The riboflavin brush follows the mouse; a click puts a drop (tests set the brush directly).
	if closeup == "smear" and dialogue_needs_e and not closeup_closing:
		closeup_hand = _closeup_local(get_viewport().get_mouse_position()).clamp(Vector2(10, 10), CLOSEUP_RECTS["smear"].size - Vector2(10, 10))
	if closeup in ["photo", "narcissus", "bench", "cleaner"] and closeup_anim == "":
		var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var bound: Vector2 = CLOSEUP_RECTS[closeup].size - Vector2(24, 24)
		var speed := S04_BRUSH_SPEED if closeup == "smear" else S01_HAND_SPEED
		closeup_hand = (closeup_hand + v * speed * delta).clamp(Vector2(24, 24), bound)
	# 《这不是一只眼睛》: W/S lean in and back; right up close, the eyelid shows.
	if closeup == "eye" and closeup_anim == "":
		var lean := -Input.get_axis("move_up", "move_down")
		s01_eye_zoom = clampf(s01_eye_zoom + lean * delta * 0.9, 0.0, 1.0)
		if s01_eye_zoom >= 0.95 and not s01_eyelid_seen:
			s01_eyelid_seen = true
			_show_dialogue(_t("s01.eye.01"))
	if closeup_anim != "":
		var duration: float = CLOSEUP_ANIM_TIME.get(closeup_anim, 1.0)
		closeup_anim_t = minf(1.0, closeup_anim_t + delta / duration)
		if closeup_anim_t >= 1.0:
			var done := closeup_anim
			closeup_anim = ""
			_s01_closeup_anim_done(done)

## True when the close-up took the event.
func _s01_closeup_input(event: InputEvent) -> bool:
	if event.is_action_pressed("interact"):
		_s01_closeup_press_e()
		return true
	if _s01_maze_active():
		for step in [["move_left", Vector2i(-1, 0)], ["move_right", Vector2i(1, 0)], ["move_up", Vector2i(0, -1)], ["move_down", Vector2i(0, 1)]]:
			var action: String = step[0]
			if event.is_action_pressed(action, true):
				var dir: Vector2i = step[1]
				_s01_maze_step(dir)
				return true
	return false

func _s01_closeup_press_e() -> void:
	if closeup == "" or closeup_closing or closeup_anim != "":
		return
	s01_idle_time = 0.0
	if closeup == "photo":
		var spot := _s01_photo_spot_at(closeup_hand)
		if spot != "":
			_s01_photo_touch(spot)
			return
	if closeup == "door" and s01_has_key and not s01_gate_open:
		_s01_play("door")
		_show_dialogue(_t("s01.closeup.01"))
		return
	if closeup == "eye" and s01_eye_zoom >= 0.95:
		_s01_play("eyelid")
		_show_dialogue(_t("s01.closeup.02"))
		return
	_close_closeup()

func _s01_play(anim: String) -> void:
	closeup_anim = anim
	closeup_anim_t = 0.0

func _s01_closeup_anim_done(done: String) -> void:
	if _sensor_anim_done(done):
		return
	match done:
		"chalk":
			s01_has_chalk = true
			chapter_state.mark_story_event(&"s01_got_chalk")
			_show_dialogue(_t("s01.photo_anim.01"))
		"snip":
			s01_ribbon_cut = true
			chapter_state.mark_story_event(&"s01_ribbon_cut")
			_show_dialogue(_t("s01.photo_anim.02"))
		"dab":
			s01_restorer_dab = true
			chapter_state.mark_story_event(&"s01_restorer_dab")
			_show_dialogue(_t("s01.photo_anim.03"))
		"heads":
			s01_visitors_turned = true
			chapter_state.mark_story_event(&"s01_visitors_turned")
			_show_dialogue(_t("s01.photo_anim.04"))
		"giant":
			s01_cleaner_waved = true
			chapter_state.mark_story_event(&"s01_cleaner_giant")
			_show_dialogue(_t("s01.photo_anim.05"))
		"lamp":
			s01_lamp_fixed = true
			chapter_state.mark_story_event(&"s01_lamp_fixed")
			_show_dialogue(_t("s01.photo_anim.06"))
		"shovel":
			s01_snow_out = true
			chapter_state.mark_story_event(&"s01_snow_out")
			_show_dialogue(_t("s01.photo_anim.07"))
		"pages":
			s01_book_open = true
			chapter_state.mark_story_event(&"s01_book_open")
			_show_dialogue(_t("s01.photo_anim.08"))
		"key":
			s01_has_key = true
			chapter_state.mark_event(&"s01_key_drawn")
			_show_dialogue(_t("s01.photo_anim.09"))
			closeup_closing = true
		"door":
			_complete_s01("past")
			closeup_closing = true
		"turn":
			if closeup_prev_melt < 2 and s01_melt >= 2:
				# The eye has dropped onto the carpet: a hyper-real insert.
				_s01_play("splat")
		"eyelid":
			closeup = ""
			closeup_t = 0.0
			_s01_close_eyelid()
		"glove":
			s03_glove_off = true
			chapter_state.mark_event(&"s03_glove_removed")
			closeup_closing = true
			_s03_guard_brings_arm()
		"mirror_pose":
			_venus_mirror_done()
		"swap":
			closeup_closing = true

func _s01_closeup_hint() -> String:
	if closeup_closing or closeup_anim != "":
		return ""
	if closeup == "photo":
		return _t("hint.shared.02") if _s01_photo_spot_at(closeup_hand) != "" else _t("hint.shared.03")
	if closeup == "door" and s01_has_key and not s01_gate_open:
		return _t("hint.s01.01")
	if closeup == "eye":
		return _t("hint.s01.02") if s01_eye_zoom >= 0.95 else _t("hint.s01.03")
	if _s01_maze_active():
		return _t("hint.s01.04")
	return _t("hint.shared.05")

## --- The people in 《美术馆开幕日》 ----------------------------------------------------------
## The photo is a big close-up: Graham's hand moves over it (WASD) and E touches whoever is under it.
## Each touch leaves a visible change somewhere else: in the other eras of the photo, on another
## exhibit in the hall, or on the hall's floor.
func _s01_photo_spots() -> Array:
	match s01_era:
		0:
			return [
				{"id": "girl", "pos": Vector2(205, 312), "r": 22.0},
				{"id": "guard", "pos": Vector2(320, 300), "r": 26.0},
				{"id": "restorer", "pos": Vector2(70, 300), "r": 24.0},
				{"id": "visitors", "pos": Vector2(112, 300), "r": 20.0},
				{"id": "visitors", "pos": Vector2(424, 300), "r": 40.0},
				{"id": "cleaner", "pos": Vector2(482, 304), "r": 22.0}
			]
		1:
			return [
				{"id": "graham", "pos": Vector2(289, 248), "r": 26.0},
				{"id": "shoveler", "pos": Vector2(96, 300), "r": 26.0},
				{"id": "bear", "pos": Vector2(200, 318), "r": 22.0},
				{"id": "snow", "pos": Vector2(420, 350), "r": 30.0}
			]
	return [{"id": "book", "pos": Vector2(259, 337), "r": 22.0}]

func _s01_photo_spot_at(p: Vector2) -> String:
	var best := ""
	var best_d := 99999.0
	for spot in _s01_photo_spots():
		var pos: Vector2 = spot.pos
		var r: float = spot.r
		var d := p.distance_to(pos)
		if d < r and d < best_d:
			best_d = d
			best = spot.id
	return best

func _s01_photo_touch(id: String) -> void:
	chapter_state.mark_event(StringName("s01_photo_touched_" + id))
	match id:
		"girl":
			if s01_has_chalk:
				_show_dialogue(_t("s01.photo_touch.01"))
			elif not s01_ribbon_cut:
				_show_dialogue("")
			else:
				_s01_play("chalk")
				_show_dialogue("")
		"guard":
			if not s01_restorer_dab:
				_show_dialogue(_t("s01.photo_touch.04"))
			elif s01_ribbon_cut:
				_show_dialogue(_t("s01.photo_touch.05"))
			else:
				_s01_play("snip")
				_show_dialogue(_t("s01.photo_touch.06"))
		"restorer":
			if s01_restorer_dab:
				_show_dialogue(_t("s01.photo_touch.07"))
			else:
				_s01_play("dab")
				_show_dialogue(_t("s01.photo_touch.08"))
		"visitors":
			if s01_visitors_turned:
				_show_dialogue(_t("s01.photo_touch.09"))
			else:
				_s01_play("heads")
				_show_dialogue(_t("s01.photo_touch.10"))
		"cleaner":
			_s01_play("giant")
			_show_dialogue(_t("s01.photo_touch.11"))
		"graham":
			if s01_lamp_fixed:
				_show_dialogue(_t("s01.photo_touch.12"))
			else:
				_s01_play("lamp")
				_show_dialogue(_t("s01.photo_touch.13"))
		"shoveler":
			if s01_snow_out:
				_show_dialogue(_t("s01.photo_touch.14"))
			else:
				_s01_play("shovel")
				_show_dialogue(_t("s01.photo_touch.15"))
		"bear":
			chapter_state.mark_story_event(&"s01_bear_tilted")
			_show_dialogue(_t("s01.photo_touch.16"))
		"snow":
			_show_dialogue(_t("s01.photo_touch.19"))
		"book":
			if s01_book_open:
				_show_dialogue(_t("s01.photo_touch.17"))
			else:
				_s01_play("pages")
				_show_dialogue(_t("s01.photo_touch.18"))

## --- The map maze: the "你在这里" dot walks the sulci, the chalk follows ----------------------
func _s01_maze_active() -> bool:
	return closeup == "map" and not closeup_closing and closeup_anim == "" and s01_has_chalk and not s01_has_key

func _s01_maze_link(a: Vector2i, b: Vector2i) -> void:
	if not s01_maze_adj.has(a):
		s01_maze_adj[a] = []
	if not s01_maze_adj.has(b):
		s01_maze_adj[b] = []
	s01_maze_adj[a].append(b)
	s01_maze_adj[b].append(a)

## The grooves form a tree, so the chalk line (start → dot) is always the one path there; stepping
## back the way it came wipes the last stroke. The way to the front of the head draws the key's
## blade and teeth; the round gyrus printed around "你在这里" is its bow.
func _s01_maze_step(dir: Vector2i) -> void:
	var cur: Vector2i = s01_maze_path[s01_maze_path.size() - 1]
	var next: Vector2i = cur + dir
	var links: Array = s01_maze_adj.get(cur, [])
	if not links.has(next):
		return
	if s01_maze_path.size() >= 2 and s01_maze_path[s01_maze_path.size() - 2] == next:
		s01_maze_path.pop_back()
	elif not s01_maze_path.has(next):
		s01_maze_path.append(next)
	else:
		return
	s01_idle_time = 0.0
	if next == S01_MAZE_GOAL:
		chapter_state.mark_event(&"s01_maze_solved")
		closeup_anim = "key"
		closeup_anim_t = 0.0
		_show_dialogue(_t("s01.map.01"))

func _s01_photo_text() -> String:
	if s01_era == 0:
		if s01_has_chalk:
			return _t("s01.photo.opening_day_chalk_taken")
		var first_open := not chapter_state.has_story_event(&"s01_saw_lan_in_photo")
		chapter_state.mark_story_event(&"s01_saw_lan_in_photo")
		return _t("s01.photo.opening_day_first") if first_open else _t("s01.photo.opening_day")
	if s01_era == 1:
		var first := not chapter_state.has_story_event(&"s01_saw_self_in_photo")
		chapter_state.mark_story_event(&"s01_saw_self_in_photo")
		return _t("s01.photo.winter_first") if first else _t("s01.photo.winter")
	return _t("s01.photo.years_later")

func _s01_map_text() -> String:
	if s01_has_key:
		return _t("s01.map.key_taken")
	if s01_has_chalk:
		if s01_maze_path.size() > 1:
			return _t("s01.map.chalk_again")
		return _t("s01.map.chalk_first")
	return _t("s01.map.look")

func _s01_door_text() -> String:
	chapter_state.mark_event(&"s01_exit_area_observed")
	# The text is the door's line, then the "出口" lamp's line: one ID for each pair (see data/dialogue_ch1.md).
	var sign := "fixed" if s01_lamp_fixed else "humming"
	if s01_melt >= 2:
		sign = "fallen"
	elif s01_era == 2:
		sign = "dead"
	elif s01_era == 0:
		sign = "new"
	if s01_has_key:
		return _t("s01.door.key")
	if s01_melt >= 1:
		return _t({"new": "s01.door.rusting_new", "humming": "s01.door.rusting_humming", "fixed": "s01.door.rusting_fixed", "dead": "s01.door.rusting_dead", "fallen": "s01.door.rusting_fallen"}[sign])
	if chapter_state.has_story_event(&"s01_door_tried"):
		return _t({"new": "s01.door.tried_new", "humming": "s01.door.tried_humming", "fixed": "s01.door.tried_fixed", "dead": "s01.door.tried_dead"}[sign])
	chapter_state.mark_story_event(&"s01_door_tried")
	return _t({"new": "s01.door.first_new", "humming": "s01.door.first_humming", "fixed": "s01.door.first_fixed", "dead": "s01.door.first_dead"}[sign])

## Each E on a clock-eye opens 《观看的永恒》 and turns one hand by one notch; the painting changes
## with the photo's era (warm and festive / snow / dust and a crack), but the photo itself is across
## the room: to see what changed there, Graham has to put the painting away and go and look.
func _s01_turn_clock(forward: bool) -> void:
	if not s01_clocks_seen:
		s01_clocks_seen = true
		chapter_state.mark_event(&"s01_clocks_observed")
		_show_dialogue(_t("s01.clock.01"))
		return
	closeup_prev_era = s01_era
	closeup_prev_melt = s01_melt
	if not forward:
		if s01_era == 0:
			_show_dialogue(_t("s01.clock.02"))
			return
		s01_era -= 1
		if s01_melt > 0:
			_show_dialogue(_t("s01.clock.back_to_opening_day_melted") if s01_era == 0 else _t("s01.clock.back_to_winter_melted"))
		else:
			_show_dialogue(_t("s01.clock.back_to_opening_day") if s01_era == 0 else _t("s01.clock.back_to_winter"))
	else:
		if s01_era < 2:
			s01_era += 1
			_show_dialogue(_t("s01.clock.03") if s01_era == 1 else _t("s01.clock.04"))
		else:
			s01_melt += 1
			chapter_state.mark_event(StringName("s01_melt_%d" % s01_melt))
			if s01_melt == 1:
				_show_dialogue(_t("s01.clock.05"))
			elif s01_melt == 2:
				_show_dialogue(_t("s01.clock.06"))
			else:
				_show_dialogue(_t("s01.clock.07"))
				_complete_s01("future")
	closeup_anim = "turn"
	closeup_anim_t = 0.0
	queue_redraw()

func _s01_look_at_eye() -> void:
	s01_eye_visits += 1
	chapter_state.mark_event(&"s01_second_exhibit_observed")
	_open_closeup("eye", S01_EYE_RECT)
	s01_eye_zoom = 0.0
	s01_eyelid_seen = false
	if s01_eye_visits == 1:
		_show_dialogue(_t("s01.eye.02"))
	else:
		_show_dialogue(_t("s01.eye.03"))

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
	# The lid has already closed over the close-up: start dark.
	s01_dark_overlay.modulate.a = 0.97
	_show_dialogue(_t("s01.eye.04"))
	await get_tree().create_timer(1.6).timeout
	_show_dialogue(_t("s01.eye.05"))
	await get_tree().create_timer(1.8).timeout
	var back := create_tween()
	back.tween_property(s01_dark_overlay, "modulate:a", 0.0, 0.7)
	await back.finished
	s01_eyelid_closed = false
	player.input_locked = false
	_show_dialogue(_t("s01.eye.06"))
	_unlock_achievement("ACH_S01_CLOSE_THE_EYE")

## Achievements live on the game platform (Steam etc.); there is no in-game pop-up. Recorded here
## until the platform is wired in.
func _unlock_achievement(id: String) -> void:
	if achievements_unlocked.has(id):
		return
	achievements_unlocked.append(id)
	chapter_state.mark_story_event(StringName("achievement_" + id))
	print("ACHIEVEMENT " + id)

func _update_s01(delta: float) -> void:
	if not s01_active or not player or scene_state != "gallery":
		return
	s01_idle_time += delta
	var target := player.position
	if s01_idle_time >= S01_HINT_AFTER and not s01_completion_started:
		target = _s01_hint_target()
	s01_eye_look = s01_eye_look.lerp(target, minf(1.0, delta * 3.0))
	# Step back to the far left and the wall reads as a face.
	if closeup == "" and not s01_face_noticed and player.position.x <= 250.0 and s01_clocks_seen and s01_eye_visits > 0 and chapter_state.has_event(&"s01_exit_area_observed"):
		s01_face_noticed = true
		chapter_state.mark_story_event(&"s01_face_noticed")
		_show_dialogue(_t("s01.face.01"))

## Where 《这不是一只眼睛》 looks when Graham is stuck.
func _s01_hint_target() -> Vector2:
	if s01_has_key:
		return S01_DOOR_RECT.get_center()
	if s01_has_chalk:
		return S01_MAP_RECT.get_center()
	if not chapter_state.has_event(&"s01_photo_observed"):
		return S01_PHOTO_RECT.get_center()
	if not s01_clocks_seen:
		return S01_CLOCKS_RECT.get_center()
	if s01_melt > 0:
		return S01_DOOR_RECT.get_center()
	return S01_CLOCK_BACK if s01_era > 0 else S01_PHOTO_RECT.get_center()

## The door opens one of two ways: the chalk key drawn on the map (past) or rusted through (future).
func _complete_s01(route: String) -> void:
	if s01_completion_started:
		return
	s01_completion_started = true
	s01_exit_route = route
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
		_show_dialogue(_t("s01.exit.01"))
	else:
		_show_dialogue(_t("s01.exit.02"))
	objective_label.text = _t("goal.s01.03")
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
	objective_label.text = _t("goal.s02.01")
	_show_dialogue(_t("s02.enter.01"))
	_update_ui()
	queue_redraw()

func _try_s02_interact() -> void:
	if not s02_active or scene_state != "gallery" or transition_started or s02_completion_started:
		return
	var nearest := _get_nearest_s02_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	_hall_open_for(object_name)
	if object_name == "SecurityGuard":
		chapter_state.mark_event(&"s02_guard_observed")
		chapter_state.mark_event(&"s02_guard_directed_right")
		if s02_belt_stalled:
			_complete_s02_counterpart()
		elif s02_guard_asked:
			_show_dialogue(_t("s02.guard.01"))
		else:
			_show_dialogue(_t("s02.guard.02"))
		s02_guard_asked = true
	else:
		_s02_describe(object_name)

## What the second hall's pieces say on E, in S02 and S03 (it depends on the light).
func _s02_describe(object_name: String) -> void:
	var lit := s03_eye_lit or s03_mirror_held
	if object_name == "HallDoor":
		if s01_exit_route == "future":
			_show_dialogue(_t("s02.describe.01"))
		else:
			_show_dialogue(_t("s02.describe.02"))
	elif object_name == "Narcissus":
		if lit:
			_show_dialogue(_t("s02.describe.03"))
		elif s03_lamp_fixed:
			_show_dialogue(_t("s02.describe.04"))
		elif s03_active:
			_show_dialogue(_t("s02.describe.05"))
		else:
			_show_dialogue(_t("s02.describe.06"))
	elif object_name == "PictureLamp":
		_show_dialogue(_t("s02.describe.07"))
	elif object_name == "SculptureLight":
		if lit:
			_show_dialogue(_t("s02.describe.08"))
		else:
			_show_dialogue(_t("s02.describe.09"))
	elif object_name == "SculptureVenus":
		if s03_mirror_held:
			_show_dialogue(_t("s02.describe.10"))
		elif lit:
			_show_dialogue(_t("s02.describe.11"))
		else:
			_show_dialogue(_t("s02.describe.12"))

## In the dark the far figure strikes the guard's exact pose, like a reflection without Graham in it.
func _complete_s02_counterpart() -> void:
	if s02_completion_started:
		return
	s02_completion_started = true
	chapter_state.mark_event(&"s02_counterpart_noticed")
	await _say_wait(_t("s02.end.01"), 2.6)
	await _say_wait(_t("s02.end.02"), 2.6)
	chapter_state.mark_event(&"s02_space_loop_recognized")
	chapter_state.learn(&"s02_space_has_a_problem")
	chapter_state.set_player_goal(&"understand_the_space")
	chapter_state.complete_slice(ChapterState.Slice.S02_LOST)
	objective_label.text = _t("goal.s02.02")
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
			objective_label.text = _t("goal.s02.03")
			_show_dialogue(_t("s02.belt.01"))
		if s02_belt_stalled and not s02_carried_back and x <= S02_BELT_START + 12.0 and not Input.is_action_pressed("move_left"):
			s02_carried_back = true
			chapter_state.mark_event(&"s02_carried_back")
			if not s02_completion_started:
				_show_dialogue(_t("s02.belt.02"))
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
		_show_dialogue(_t("legacy.exhibits.01"))
	elif object_name == "PearlHeadphones":
		_show_dialogue(_t("legacy.exhibits.02"))
	elif object_name == "StarryNerves":
		_show_dialogue(_t("legacy.exhibits.03"))
	elif object_name == "SculptureGaze":
		_show_dialogue(_t("legacy.exhibits.04"))
	elif object_name == "SculptureVenus":
		_show_dialogue(_t("legacy.exhibits.05"))
	elif object_name == "SculptureTwins":
		_show_dialogue(_t("legacy.exhibits.06"))
	elif object_name == "SculptureLight":
		_show_dialogue(_t("legacy.exhibits.07"))
	elif object_name == "SculptureBlind":
		_show_dialogue(_t("legacy.exhibits.08"))

func _try_s03_interact() -> void:
	if not s03_active or scene_state != "gallery" or transition_started or s03_busy:
		return
	if s03_pov_active:
		_s03_advance_pov()      # E, like a click, brings the next thing overheard
		return
	if s03_crossed and absf(player.position.x - _s03_far_door_x()) <= 70.0:
		_s03_leave()
		return
	if s03_ride_active:
		_s03_ride_interact()
		return
	var nearest := _get_nearest_s03_interactable()
	if nearest.is_empty():
		return
	var object_name: String = nearest.get("name", "")
	_hall_open_for(object_name)
	if object_name == "SculptureVenus" and _venus_arm_waiting():
		_show_dialogue(_t("s03.interact.01"))
	elif object_name == "SculptureVenus" and s03_arms_returned and not s03_mirror_held:
		_show_dialogue(_t("s03.interact.02"))
	elif object_name == "SculptureVenus" and s03_eye_lit and not s03_mirror_held:
		if s03_hands_seen:
			_show_dialogue(_t("s03.interact.03"))
		else:
			_show_dialogue(_t("s03.interact.04"))
		_show_space_prompt()
	elif object_name == "SecurityGuard":
		if s03_left_installed:
			_show_dialogue(_t("s03.interact.05"))
		elif s03_left_arm_ready:
			_show_dialogue(_t("s03.interact.06"))
		elif s03_hands_seen and not blue_lake_active:
			_show_dialogue(_t("s03.interact.07"))
		else:
			_show_dialogue(_t("s03.interact.08"))
	elif object_name == "HallDoor":
		if s03_mirror_held and not s03_crossed:
			_s03_cross_by_reflection()
		else:
			_s02_describe("HallDoor")
	else:
		_s02_describe(object_name)
	queue_redraw()

## E on the guard, 《那喀索斯》 or Venus opens its close-up (the door has none).
func _hall_open_for(object_name: String) -> void:
	match object_name:
		"SecurityGuard":
			var gx := s03_guard_x if s03_active else S02_GUARD_X
			_hall_open("guard", Rect2(gx - 30, 290, 90, 110))
		"Narcissus":
			_hall_open("narcissus", Rect2(240, 190, 150, 125))
		"SculptureVenus":
			_hall_open("venus", Rect2(S02_AXIS_X - 40, 160, 80, 230))

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
		_show_dialogue(_t("s03.lamp.01"))
		return
	if not s03_lamp_fixed:
		s03_lamp_fixed = true
		s03_lamp_angle = 0
		chapter_state.mark_event(&"s03_picture_lamp_fixed")
		_show_dialogue(_t("s03.lamp.02"))
		objective_label.text = _t("goal.s03.03")
		return
	s03_lamp_angle = (s03_lamp_angle + 1) % S03_WATER_HITS.size()
	var end := _s03_reflection_end(s03_lamp_angle)
	if s03_lamp_angle == S03_LAMP_GOOD:
		_s03_light_the_eye()
	elif end.y <= 143.0:
		_show_dialogue(_t("s03.lamp.03"))
	else:
		_show_dialogue(_t("s03.lamp.04"))

## Found the lamp before being stopped by the belt: S03 starts right here, with the lamp fixed.
func _s02_lamp_found_first() -> void:
	s02_completion_started = true
	chapter_state.mark_event(&"s02_lamp_found_first")
	chapter_state.learn(&"s02_space_has_a_problem")
	chapter_state.complete_slice(ChapterState.Slice.S02_LOST)
	_enter_s03_after_s02()
	_s03_use_picture_lamp()
	_show_dialogue(_t("s02.lamp.01"))

func _s03_light_the_eye() -> void:
	s03_eye_lit = true
	s03_busy = true
	chapter_state.mark_event(&"s03_venus_eye_lit")
	objective_label.text = _t("goal.s03.04")
	_show_dialogue(_t("s03.lamp.05"))
	_show_space_prompt()
	await get_tree().create_timer(0.6).timeout
	s03_busy = false

func _s03_cross_by_reflection() -> void:
	var reflected_x := _s02_mx(player.position.x)
	if absf(reflected_x - (_s02_mx(S02_DOOR_RECT.get_center().x))) > 30.0:
		_show_dialogue(_t("s03.cross.02"))
		return
	s03_crossed = true
	s03_busy = true
	player.input_locked = true
	chapter_state.mark_event(&"s03_crossed_by_reflection")
	_open_closeup("swap", S02_DOOR_RECT)
	_s01_play("swap")
	await _say_wait(_t("s03.cross.03"), 1.6)
	player.position.x = reflected_x
	player.input_locked = false
	s03_busy = false
	objective_label.text = _t("goal.s03.05")
	_show_dialogue(_t("s03.cross.04"))

func _try_toggle_s03_blue_lake() -> void:
	if s03_busy:
		return
	if not s03_eye_lit:
		_show_dialogue(_t("s03.lake.02"))
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue(_t("common.shared.01"))
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	if not blue_lake_active and s03_pov_active:
		_s03_end_pov()
	_show_dialogue(_t("s03.lake.chalk_eye") if blue_lake_active else _t("common.put_away"))
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
		_show_dialogue(_t("s03.pov.end"))
		return
	if s03_pov_line == 1:
		s03_hands_seen = true
		chapter_state.mark_event(&"s03_hands_seen")
		_s03_update_objective()
	_show_dialogue(_t(S03_POV_LINES[s03_pov_line]))

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
	await _say_wait(_t("s03.guard_arm.02"), 2.8)
	_show_dialogue(_t("s03.guard_arm.03"))
	s03_guard_walking = true
	while s03_guard_x < S03_GUARD_AT_VENUS:
		await get_tree().process_frame
		s03_guard_x = minf(s03_guard_x + get_process_delta_time() * 140.0, S03_GUARD_AT_VENUS)
	s03_guard_walking = false
	s03_left_arm_ready = true
	chapter_state.mark_event(&"s03_marble_arm_brought")
	_show_dialogue(_t("s03.guard_arm.04"))
	_s03_update_objective()
	player.input_locked = false
	s03_busy = false

func _s03_update_objective() -> void:
	if s03_mirror_held:
		return
	if s03_left_arm_ready and s03_right_arm_ready:
		objective_label.text = _t("goal.s03.arms_install")
	elif not s03_left_arm_ready and not s03_right_arm_ready:
		objective_label.text = _t("goal.s03.arms_both")
	elif not s03_left_arm_ready:
		objective_label.text = _t("goal.s03.arms_guard")
	else:
		objective_label.text = _t("goal.s03.arms_bonsai")

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
		_open_closeup("lan_tag", Rect2(_s02_mx(S02_DOOR_RECT.end.x), S02_DOOR_RECT.position.y, S02_DOOR_RECT.size.x, S02_DOOR_RECT.size.y))
		_show_dialogue(_t("s03.ride.01"))
	elif n == "SkeletonPainting":
		_open_closeup("lan_skull", Rect2(_s02_mx(S02_NARCISSUS_RECT.end.x), S02_NARCISSUS_RECT.position.y, S02_NARCISSUS_RECT.size.x, S02_NARCISSUS_RECT.size.y))
		_show_dialogue(_t("s03.ride.02"))
	elif n == "BonsaiPot":
		s03_pot_on_belt = true
		chapter_state.mark_event(&"s03_bonsai_pushed")
		_show_dialogue(_t("s03.ride.03"))

func _s03_start_ride() -> void:
	s03_ride_active = true
	s03_ride_x = _s02_mx(player.position.x)
	s02_figure_alpha = 1.0
	player.input_locked = true
	chapter_state.mark_event(&"s03_blue_lake_ride")
	_show_dialogue(_t("s03.ride.04"))

func _s03_end_ride() -> void:
	s03_ride_active = false
	s02_figure_alpha = 0.0
	s02_idle_time = 0.0
	player.input_locked = false
	if s03_pot_on_belt:
		s03_ride_done = true
		_show_dialogue(_t("s03.ride.05"))
	else:
		_show_dialogue(_t("s03.ride.06"))

func _update_s03(delta: float) -> void:
	if not s03_active:
		return
	# Not found the lamp on her own: after a while LAN points at it, once.
	if not s03_lamp_fixed and s03_dark_time >= 0.0:
		s03_dark_time += delta
		if s03_dark_time >= S03_LAMP_HINT_AFTER and closeup == "":
			s03_dark_time = -1.0
			chapter_state.mark_event(&"s03_lamp_hinted")
			_show_dialogue(_t("s03.update.01"))
	if s03_pov_active:
		s03_pov_timer += delta
		if not dialogue_needs_e and s03_pov_timer >= 3.0 and s03_pov_line < S03_POV_LINES.size():
			_s03_advance_pov()
	# Standing at the entrance puts the reflection — Blue Lake — at the far door. Once Graham knows
	# whose arm the bonsai holds, the belt carries Blue Lake through the 里 side toward the middle.
	if not s03_ride_active and not s03_ride_done and s03_hands_seen and not s03_mirror_held and not s03_busy \
			and not blue_lake_active and s02_figure_alpha >= 0.95 \
			and absf(_s02_mx(player.position.x) - _s02_mx(S02_DOOR_RECT.get_center().x)) <= 30.0:
		_s03_start_ride()
	if s03_ride_active and closeup == "":
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
				_show_dialogue(_t("s03.update.02"))

func _try_toggle_s04_blue_lake() -> void:
	if not s04_window_seen:
		_show_dialogue(_t("s04.bench.01"))
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue(_t("s04.lake.01"))
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_hide_space_prompt()
	_show_dialogue(_t("s04.lake.chalk_window") if blue_lake_active else _t("common.put_away"))
	_update_ui()
	queue_redraw()

func _update_s04(delta: float) -> void:
	if not s04_active:
		return
	s04_win_t = move_toward(s04_win_t, S04_PRESET_T[s04_window], delta * 2.2)
	_update_s04_mouse(delta)
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
	if player:
		s04_walk_phase += absf(player.velocity.x) * delta * 0.045
		player.modulate.a = 0.25 if _s04_point_light_on() else 1.0
	if s04_uv_on and s04_riboflavin_applied and not s04_fluor_shown:
		s04_fluor_shown = true
		_hyper_flash_start("fluor")
	if not s04_visitors_recognized and s04_win_t > 0.9 and s04_uv_on and s04_riboflavin_applied and player and absf(player.velocity.x) > 30.0:
		var near := false
		for vx in S04_VISITOR_XS:
			if absf(player.position.x - vx) < 70.0:
				near = true
				break
		if near and _s04_joint_hits() >= S04_RECOGNISE_JOINTS:
			_s04_recognized()
		elif near and not s04_firefly_said:
			s04_firefly_said = true
			_show_dialogue(_t("s04.visitors.01"))
		elif not near:
			s04_firefly_said = false

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
	if s04_girl_caught and s04_girl_out and line == _t("s04.catch.05"):
		s04_girl_out = false

func _s04_update_objective() -> void:
	if s04_girl_caught:
		var left: Array[String] = []
		if not s04_riboflavin_applied:
			left.append(_t("goal.s04.left_smear"))
		if not s04_visitors_recognized:
			left.append(_t("goal.s04.left_recognized"))
		if not s04_handle_found:
			left.append(_t("goal.s04.left_handle"))
		if not s04_frame_installed:
			left.append(_t("goal.s04.left_frame"))
		objective_label.text = "、".join(left) if not left.is_empty() else _t("goal.s04.window")
	elif s04_starry_repaired:
		objective_label.text = _t("goal.s04.01")
	elif s04_restorer_met:
		objective_label.text = _t("goal.s04.02")
	elif s04_window_seen:
		objective_label.text = _t("goal.s04.03")
	else:
		objective_label.text = _t("goal.s04.04")

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
			var vx: float = nearest.position.x
			_open_closeup("visitor", Rect2(vx - 30, 290, 60, 110))
			_s04_talk_to_visitors()
		"Bench":
			_open_closeup("bench", Rect2(300, 220, 240, 160))
			closeup_hand = Vector2(470, 150)
			if s04_starry_repaired:
				_show_dialogue(_t("s04.look.01"))
			else:
				_show_dialogue(_t("s04.look.02"))
		"Restorer":
			_s04_talk_to_restorer()
		"RestorerSide":
			if s04_win_t > 0.75:
				_show_dialogue(_t("s04.bench.03"))
			else:
				_show_dialogue(_t("s04.look.03"))
		"Workbench":
			_s04_use_bench()
		"Window":
			_open_closeup("window", Rect2(S05_WINDOW_CENTER - Vector2(45, 50), Vector2(90, 100)))
			_s04_look_at_window()
		"StarryNerves":
			if s04_starry_repaired:
				_show_dialogue(_t("s04.look.04"))
			elif s04_win_t < 0.25:
				_show_dialogue(_t("s04.look.05"))
			else:
				_show_dialogue(_t("s04.look.06"))
		"PearlHeadphones":
			_open_closeup("girl", Rect2(S04_GIRL_FRAME_X - 45, 225, 90, 90))
			s04_girl_face = -1
			_s04_look_at_girl()
		"SculptureTwins":
			_open_closeup("twins", Rect2(S04_TWINS_X - 25, 290, 50, 80))
			if s04_mouse == "eating":
				_show_dialogue(_t("s04.look.07"))
			elif s04_uv_on:
				_show_dialogue(_t("s04.look.08"))
			elif s04_win_t < 0.25:
				_show_dialogue(_t("s04.look.09"))
			elif s04_win_t > 0.75:
				_show_dialogue(_t("s04.look.10"))
			else:
				_show_dialogue(_t("s04.look.11"))
	_s04_update_objective()
	queue_redraw()

func _s04_talk_to_visitors() -> void:
	if s04_visitors_recognized:
		_show_dialogue(_t("s04.visitors.02"))
	elif s04_win_t < 0.25:
		chapter_state.mark_event(&"s04_visitor_observed")
		_show_dialogue(_t("s04.visitors.03"))
	elif s04_win_t <= 0.75:
		if s04_starry_repaired:
			_show_dialogue(_t("s04.visitors.04"))
		else:
			_show_dialogue(_t("s04.visitors.05"))
	elif s04_riboflavin_applied and s04_uv_on:
		_show_dialogue(_t("s04.visitors.06"))
	else:
		_show_dialogue(_t("s04.visitors.07"))

func _s04_talk_to_restorer() -> void:
	if s04_win_t > 0.75:
		_show_dialogue(_t("s04.bench.03"))
		return
	if not s04_restorer_met:
		s04_restorer_met = true
		chapter_state.mark_event(&"s04_restorer_observed")
		_s04_say([
			_t("s04.restorer.01"),
			_t("s04.restorer.02")
		])
	elif s04_signal_traced and not s04_starry_repaired:
		_s04_repair_starry()
	elif not s04_starry_repaired:
		_show_dialogue(_t("s04.restorer.03"))
	elif not s04_girl_caught:
		_show_dialogue(_t("s04.restorer.04"))
	else:
		_show_dialogue(_t("s04.restorer.05"))

func _s04_repair_starry() -> void:
	s04_starry_repaired = true
	s04_has_riboflavin = true
	chapter_state.mark_event(&"s04_starry_repaired")
	chapter_state.mark_event(&"s04_riboflavin_received")
	_s04_say([
		_t("s04.repair.01"),
		_t("s04.repair.02"),
		_t("s04.repair.03"),
		_t("s04.repair.04")
	])
	_s04_update_objective()

func _s04_use_bench() -> void:
	if s04_has_riboflavin and not s04_riboflavin_applied:
		s04_riboflavin_applied = true
		chapter_state.mark_event(&"s04_pigment_applied")
		_show_dialogue(_t("s04.bench_tools.05"))
	elif s04_girl_caught:
		s04_uv_on = not s04_uv_on
		if s04_uv_on:
			chapter_state.mark_event(&"s04_uv_on")
		_show_dialogue(_t("s04.bench_tools.03") if s04_uv_on else _t("s04.bench_tools.04"))
	elif s04_starry_repaired:
		_show_dialogue(_t("s04.bench_tools.01"))
	else:
		_show_dialogue(_t("s04.bench_tools.02"))

func _s04_look_at_window() -> void:
	if not s04_window_seen:
		s04_window_seen = true
		chapter_state.mark_event(&"s04_window_observed")
		_show_dialogue(_t("s04.window.01"))
		_show_space_prompt()
	elif s04_uv_on and s04_win_t >= 0.5 and not s04_handle_found:
		s04_handle_found = true
		chapter_state.mark_event(&"s04_window_handle_found")
		_show_dialogue(_t("s04.window.02"))
		_s04_check_complete()
	elif s04_uv_on and not chapter_state.has_event(&"s04_blue_handprint_seen"):
		chapter_state.mark_event(&"s04_blue_handprint_seen")
		_show_dialogue(_t("s04.window.03"))
	elif s04_girl_caught and not s04_frame_installed:
		s04_frame_installed = true
		chapter_state.mark_event(&"s04_window_frame_installed")
		_show_dialogue(_t("s04.window.04"))
		_s04_check_complete()
	elif s04_girl_caught and not s04_handle_found:
		_show_dialogue(_t("s04.window.05"))
	else:
		_show_dialogue(_t({"cone": "s04.window.preset_cone", "mid": "s04.window.preset_mid", "rod": "s04.window.preset_rod"}[s04_window]))

func _s04_look_at_girl() -> void:
	if s04_girl_out and not s04_girl_caught:
		if s04_girl_frozen:
			_show_dialogue(_t("s04.girl.01"))
		else:
			_show_dialogue(_t("s04.girl.02"))
	elif s04_uv_on and s04_girl_caught:
		_show_dialogue(_t("s04.girl.03"))
	elif s04_win_t < 0.25:
		_show_dialogue(_t("s04.girl.04"))
	elif s04_win_t <= 0.75:
		_show_dialogue(_t("s04.girl.05"))
	else:
		_show_dialogue(_t("s04.girl.06"))

func _try_s04_chalk_interaction() -> void:
	if chalk_hover_target == "S04Mouse":
		_s04_scare_mouse()
		return
	if chalk_hover_target.begins_with("Signal"):
		_s04_trace(int(chalk_hover_target.substr(6)))
		return
	if chalk_hover_target != "S04Window":
		return
	_s04_pull_curtain()

func _s04_trace(index: int) -> void:
	if s04_signal_traced:
		return
	if index != s04_signal_progress:
		_show_dialogue(_t("s04.trace.01"))
		return
	s04_signal_progress += 1
	if s04_signal_progress < S04_SIGNAL_NODES.size():
		_show_dialogue(_t("s04.trace.02"))
	else:
		s04_signal_traced = true
		chapter_state.mark_event(&"s04_signal_traced")
		if s04_window == "mid":
			_s04_repair_starry()
		else:
			_show_dialogue(_t("s04.trace.03"))
	queue_redraw()

func _s04_pull_curtain() -> void:
	var next: String = S04_PRESETS[(S04_PRESETS.find(s04_window) + 1) % S04_PRESETS.size()]
	s04_window = next
	chapter_state.mark_event(StringName("s04_window_" + next))
	match next:
		"cone":
			_show_dialogue(_t("s04.curtain.01"))
		"mid":
			_show_dialogue(_t("s04.curtain.02"))
		"rod":
			_show_dialogue(_t("s04.curtain.03"))
	if next == "cone" and s04_girl_out and not s04_girl_caught:
		if absf(s04_girl_x - S04_RESTORER_FRONT) <= S04_CATCH_RANGE:
			_s04_catch_girl()
		else:
			s04_girl_frozen = true
			_show_dialogue(_t("s04.curtain.04"))
	_s04_update_objective()
	queue_redraw()

func _s04_catch_girl() -> void:
	s04_girl_caught = true
	s04_girl_frozen = true
	chapter_state.mark_event(&"s04_girl_caught")
	_s04_say([
		_t("s04.catch.01"),
		_t("s04.catch.02"),
		_t("s04.catch.03"),
		_t("s04.catch.04"),
		_t("s04.catch.05"),
		_t("s04.catch.06")
	])
	s04_girl_x = S04_RESTORER_FRONT - 6.0   # she stays where she was caught until she runs back
	_s04_update_objective()

func _s04_recognized() -> void:
	s04_visitors_recognized = true
	chapter_state.mark_event(&"s04_visitor_recognized_by_light")
	_s04_say([
		_t("s04.recognized.01"),
		_t("s04.recognized.02"),
		_t("s04.recognized.03"),
		_t("s04.recognized.04")
	])
	_s04_update_objective()
	_s04_check_complete()

func _s04_check_complete() -> void:
	if s04_finish_pending or not (s04_visitors_recognized and s04_handle_found and s04_frame_installed):
		return
	if s04_mouse in ["escaping", "gone"]:
		return
	# Frame, handle, recognised: the mouse makes a dash for 《窗》 and is out through it.
	match s04_mouse:
		"pacing", "running":
			s04_mouse_x = _s04_mouse_pos().x
		"table", "bottle":
			s04_mouse_x = S04_BENCH_X + 20.0
		_:
			s04_mouse_x = S04_TWINS_X
	s04_mouse_climb = 0.0
	s04_mouse = "escaping"
	chapter_state.mark_event(&"s04_mouse_escaped_through_window")

func _s04_finish() -> void:
	s04_finish_pending = false
	if closeup != "":
		closeup = ""
		closeup_t = 0.0
		closeup_anim = ""
	player.input_locked = false
	player.modulate.a = 1.0
	chapter_state.mark_event(&"s04_window_unblocked")
	chapter_state.learn(&"s04_seeing_is_not_objective")
	chapter_state.complete_slice(ChapterState.Slice.S04_VISITOR)
	objective_label.text = _t("goal.s05.01")
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
	draw_string(ThemeDB.fallback_font, Vector2(100, 150), _t("sign.hall_room.01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#b8c7d4"))
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
	draw_string(ThemeDB.fallback_font, zone[0] + Vector2(-34, 4), _t("sign.hall_room.02"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#bfe8ff"))

func _draw_s05_footprints() -> void:
	# The one place from which the cleaner looks his normal size.
	var z := S05_FOOTPRINTS_Z
	var s := _s05_scale(z)
	var p := Vector2(_s05_px(S05_CLEANER_X, z), _s05_y(z))
	for k in range(2):
		var q := p + Vector2(-8 + k * 14, -2 + k * 3) * s
		draw_circle(q, 4.0 * s, Color(0.85, 0.82, 0.72, 0.5))
		draw_circle(q + Vector2(0, -7) * s, 2.5 * s, Color(0.85, 0.82, 0.72, 0.5))
	draw_string(ThemeDB.fallback_font, p + Vector2(-20, 18), _t("sign.hall_room.03"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.82, 0.72, 0.8))

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
	draw_string(ThemeDB.fallback_font, Vector2(x - 26, foot - 258 * s), _t("sign.hall_room.04"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))

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
	if s06_wipe_t >= 0.0:
		return   # he is inside the fifth case, wiping it
	var f := _s05_cleaner_factor()
	var cs := s * f
	var stand := Vector2(x, foot).lerp(top, 4.0 / 7.0)
	draw_rect(Rect2(stand.x - 9 * cs, stand.y - 30 * cs, 18 * cs, 30 * cs), Color("#5c7a6e"), true)
	draw_circle(Vector2(stand.x, stand.y - 38 * cs), 8.0 * cs, Color("#c9ad8e"))
	draw_line(Vector2(stand.x - 9 * cs, stand.y - 24 * cs), Vector2(stand.x - 26 * cs, stand.y - 40 * cs), Color("#5c7a6e"), maxf(3.0 * cs, 1.0))
	draw_rect(Rect2(stand.x - 32 * cs, stand.y - 46 * cs, 9 * cs, 7 * cs), Color("#8d8f86") if s05_lens_clean else Color("#e8e2c8"), true)
	draw_string(ThemeDB.fallback_font, Vector2(stand.x - 18, stand.y - 54 * cs - 4), _t("sign.hall_room.05"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))

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
			if s08_mouse_on:
				# Kicked over: on its side in a puddle.
				draw_colored_polygon(PackedVector2Array([Vector2(x - 26 * s, foot + 2 * s), Vector2(x + 18 * s, foot + 2 * s), Vector2(x + 26 * s, foot + 8 * s), Vector2(x - 30 * s, foot + 9 * s)]), Color(0.5, 0.75, 0.95, 0.35))
				draw_rect(Rect2(x - 16 * s, foot - 12 * s, 20 * s, 12 * s), Color("#6f7d88"), true)
				return
			draw_rect(Rect2(x - 8 * s, foot - 16 * s, 16 * s, 16 * s), Color("#6f7d88"), true)
			draw_line(Vector2(x - 6 * s, foot), Vector2(x - 20 * s, foot + 6 * s), Color(0.5, 0.75, 0.95, 0.6), 2.0)
			if s07_active and not s07_found.get("hall", true):
				var b := Vector2(x + 15 * s, foot - 3 * s)
				_draw_sparkle(self, b, 6.0 * s, true)
				_draw_s07_egg("hall", b, 1.9 * s)
				_draw_sparkle(self, b, 6.0 * s, false)
		"Eyepiece":
			draw_line(Vector2(x, foot), Vector2(x, foot - 34 * s), Color("#b08d57"), 4.0 * s)
			draw_circle(Vector2(x, foot - 38 * s), 6.0 * s, Color("#d9b36a"))
			draw_string(ThemeDB.fallback_font, Vector2(x - 16, foot - 50 * s), _t("sign.hall_room.06"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
		"Lens":
			draw_line(Vector2(x, foot), Vector2(x, foot - 44 * s), Color("#8a7a62"), 4.0 * s)
			draw_circle(Vector2(x, foot - 58 * s), 15.0 * s, Color(0.85, 0.87, 0.9, 0.85) if not s05_lens_clean else Color(0.7, 0.88, 1.0, 0.35))
			draw_arc(Vector2(x, foot - 58 * s), 15.0 * s, 0.0, TAU, 24, Color("#b08d57"), 3.0 * s)
			draw_string(ThemeDB.fallback_font, Vector2(x - 20, foot - 80 * s), _t("sign.hall_room.07"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
		"Pile":
			_draw_s06_pile()
		"Lamp":
			if s06_lamp_on:
				var heap := _s06_piece_floor_pos("body")
				draw_colored_polygon(PackedVector2Array([Vector2(x + 4 * s, foot - 108 * s), Vector2(heap.x + 40, heap.y - 40), Vector2(heap.x - 30, heap.y + 10)]), Color(1.0, 0.95, 0.75, 0.16))
			draw_line(Vector2(x, foot), Vector2(x, foot - 120 * s), Color("#8796a2"), 3.0 * s)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 12 * s, foot - 120 * s), Vector2(x + 12 * s, foot - 120 * s), Vector2(x + 20 * s, foot - 100 * s), Vector2(x - 4 * s, foot - 100 * s)]), Color("#d6c79f"))
			draw_string(ThemeDB.fallback_font, Vector2(x - 20, foot + 14), _t("sign.hall_room.08"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))
		_:
			if n.begins_with("Plinth_"):
				var room := n.substr(7)
				draw_rect(Rect2(x - 22 * s, foot - 46 * s, 44 * s, 46 * s), Color("#3d4a5a"), true)
				draw_rect(Rect2(x - 26 * s, foot - 50 * s, 52 * s, 6 * s), Color("#566674"), true)
				if s07_shelved.get(room, false):
					_draw_s07_egg(room, Vector2(x, foot - 58 * s), s * 2.2)
				draw_string(ThemeDB.fallback_font, Vector2(x - 26, foot + 14), _t(["sign.hall.plinth_0", "sign.hall.plinth_1", "sign.hall.plinth_2", "sign.hall.plinth_3"][S07_WINDOW_ROOMS.find(room)]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))

## The four hidden things, white and blue (Blue Lake's colours), drawn at `at` with scale `k`.
func _draw_s07_egg(room: String, at: Vector2, k: float, cv: CanvasItem = null) -> void:
	var ci: CanvasItem = cv
	if ci == null:
		ci = self
	var blue := Color("#2f86e0")
	match room:
		"s01":
			ci.draw_circle(at, 5.0 * k, blue)
			ci.draw_circle(at, 2.0 * k, Color("#f4f6f8"))
		"s02":
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-7, 0) * k, at + Vector2(2, -3) * k, at + Vector2(2, 3) * k]), Color("#f4f6f8"))
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(2, 0) * k, at + Vector2(7, -3) * k, at + Vector2(7, 3) * k]), blue)
		"s04":
			ci.draw_rect(Rect2(at - Vector2(7, 6) * k, Vector2(14, 12) * k), Color("#f4f6f8"), true)
			ci.draw_line(at + Vector2(-4, 4) * k, at + Vector2(-2, -3) * k, blue, 1.2)
			ci.draw_circle(at + Vector2(3, 0) * k, 2.5 * k, blue)
		"hall":
			ci.draw_circle(at, 4.5 * k, Color("#f4f6f8"))
			for q in [Vector2(-1.5, -1.5), Vector2(1.5, -1.5), Vector2(-1.5, 1.5), Vector2(1.5, 1.5)]:
				ci.draw_circle(at + q * k, 0.8 * k, blue)


## A small thing that wants finding: a soft halo under it (`under`), and every couple of seconds a glint over it.
func _draw_sparkle(ci: CanvasItem, at: Vector2, r: float, under: bool) -> void:
	var ph := fmod(Time.get_ticks_msec() * 0.001, 2.2)
	if under:
		ci.draw_circle(at, r * 1.8, Color(0.75, 0.88, 1.0, 0.14 + 0.08 * sin(ph / 2.2 * TAU)))
		return
	if ph < 0.5:
		var g := sin(ph / 0.5 * PI)
		ci.draw_line(at - Vector2(r * 2.4 * g, 0), at + Vector2(r * 2.4 * g, 0), Color(1, 1, 1, 0.9 * g), 1.5)
		ci.draw_line(at - Vector2(0, r * 2.4 * g), at + Vector2(0, r * 2.4 * g), Color(1, 1, 1, 0.9 * g), 1.5)

## Through the telescope, a window in focus shows a tiny view of its room and where its hidden thing is.
func _draw_s07_window_scene(room: String, w: Rect2, cv: CanvasItem = null) -> void:
	var ci: CanvasItem = cv
	if ci == null:
		ci = self
	ci.draw_rect(w, Color("#3a3026") if room != "s02" else Color("#1c2230"), true)
	var p := w.position
	match room:
		"s01":
			ci.draw_rect(Rect2(p + Vector2(8, 10), Vector2(14, 14)), Color("#d8cfb5"), true)
			_draw_s07_egg("s01", p + Vector2(12, 15), 0.6, cv)
		"s02":
			ci.draw_rect(Rect2(p + Vector2(10, 8), Vector2(18, 16)), Color("#2c3747"), true)
			ci.draw_line(p + Vector2(8, 28), p + Vector2(32, 28), Color(0.5, 0.75, 0.95), 2.0)
			_draw_s07_egg("s02", p + Vector2(20, 28), 0.6, cv)
		"s04":
			ci.draw_rect(Rect2(p + Vector2(18, 8), Vector2(18, 18)), Color("#b49464"), true)
			_draw_s07_egg("s04", p + Vector2(40, 18), 0.6, cv)
		"hall":
			ci.draw_rect(Rect2(p + Vector2(6, 6), Vector2(48, 20)), Color("#6aa84f"), true)
			ci.draw_rect(Rect2(p + Vector2(40, 26), Vector2(8, 8)), Color("#6f7d88"), true)
			_draw_s07_egg("hall", p + Vector2(50, 34), 0.6, cv)

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
		if s05_line_timer <= 0.0 and not s05_lines.is_empty():
			_s05_next_line()
	# A slice ends once its last line has been read and the close-up it ended in is put away.
	if s05_lines.is_empty() and s05_line_timer <= 0.0 and closeup == "":
		if s05_finish_pending:
			_s05_finish()
			return
		if s06_finish_pending:
			_s06_finish()
			return
	_update_s06_wipe(delta)
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
				_show_dialogue(_t("s05.walk_out.01"))
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
	var nearest: Dictionary = {}
	var best := 99999.0
	for item in s05_hall_items:
		if item.get("inert", false) and not (item.name == "Bucket" and s07_active and not s07_found.get("hall", true)):
			continue
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
	objective_label.text = _t("goal.s05.02")
	s05_labeled = true
	chapter_state.mark_event(&"s05_labeled_by_cleaner")
	_s05_say([
		_t("s05.walk_out.02"),
		_t("s05.walk_out.03"),
		_t("s05.walk_out.04")
	])

func _s05_hall_interact() -> void:
	var nearest := _get_nearest_s05_hall_item()
	if nearest.is_empty():
		if _s05_in_painting():
			_show_dialogue(_t("s05.walk_out.05"))
		return
	_hall_open_item(String(nearest.name))

## What the cleaner says depends on how big he looks from where Graham stands.
func _s05_cleaner_aside() -> String:
	if _s05_cleaner_size() == "giant":
		return _t("s05.cleaner.aside_giant")
	return _t("s05.cleaner.aside_tiny")

func _s05_talk_to_cleaner() -> void:
	if _s05_cleaner_size() != "normal":
		if not s05_cleaner_met:
			_show_dialogue(_t("s05.cleaner.aside_giant_first") if _s05_cleaner_size() == "giant" else _t("s05.cleaner.aside_tiny_first"))
		else:
			_show_dialogue(_s05_cleaner_aside())
		return
	if not s05_cleaner_met:
		s05_cleaner_met = true
		chapter_state.mark_event(&"s05_cleaner_met")
		objective_label.text = _t("goal.s05.03")
		_s05_say([
			_t("s05.cleaner.01"),
			_t("s05.cleaner.02"),
			_t("s05.cleaner.03"),
			_t("s05.cleaner.04"),
			_t("s05.cleaner.05")
		])
	elif not s05_lens_clean:
		_show_dialogue(_t("s05.cleaner.06"))
	elif not s05_cell_seen:
		_show_dialogue(_t("s05.cleaner.07"))
	else:
		_show_dialogue(_t("s05.cleaner.08"))



func _s05_finish() -> void:
	s05_finish_pending = false
	chapter_state.complete_slice(ChapterState.Slice.S05_WINDOW)
	_enter_s06_after_s05()

## --- S06 drawing ----------------------------------------------------------------------------
func _s06_piece_floor_pos(piece: String) -> Vector2:
	# The heap on the hall floor; a piece moved in the close-up moves a little here too.
	var base: Vector2 = S06_PIECE_FLOOR[piece]
	var off: Vector2 = (s06_pieces.get(piece, S06_PIECE_START[piece]) as Vector2) - _s06_piece_target(piece)
	var s := _s05_scale(S06_PILE_Z)
	var x := _s05_px(S06_PILE_X + base.x + off.x * 0.25, S06_PILE_Z)
	return Vector2(x, _s05_y(S06_PILE_Z) - (base.y - off.y * 0.1) * s)

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
	draw_string(ThemeDB.fallback_font, Vector2(_s05_px(S06_PILE_X, S06_PILE_Z) - 40, foot + 14), _t("sign.hall_room.09"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))


func _draw_s06_shadow() -> void:
	# The same shadows as in the pile's close-up, on the hall's (smaller) mural.
	draw_set_transform(Vector2(325, 91.5), 0.0, Vector2(0.77, 0.77))
	_cv_shadows(self, Vector2.ZERO, 1.0)
	draw_set_transform(Vector2.ZERO)
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
	if s06_wipe_t >= 0.0:
		# A speck moving inside the fogged case: the cleaner, wiping it from within.
		draw_circle(c + Vector2(sin(Time.get_ticks_msec() * 0.004) * r.size.x * 0.3, 0), 1.6, Color("#5c7a6e"))
		return
	if not s06_case_clean:
		return
	draw_rect(r, Color("#1c2836"), true)
	if s06_sensor_revealed and not s08_stolen:
		for k in range(8):
			draw_circle(c + Vector2(-4.5 + (k % 4) * 3.0, -2.0 + (k / 4) * 4.0), 1.2, Color("#9fe3ff"))
	draw_rect(r, Color(0.8, 0.92, 1.0, 0.7), false, 1.0)

func _draw_s06_hall() -> void:
	_draw_s05_hall()

## --- S06 logic ------------------------------------------------------------------------------
func _enter_s06_after_s05() -> void:
	if s06_active:
		return
	s05_active = false
	s06_active = true
	s06_lamp_on = false
	s06_has_card = false
	s06_pieces = S06_PIECE_START.duplicate()
	s06_shadow_done = false
	s06_case_clean = false
	s06_sensor_revealed = false
	s06_finish_pending = false
	s06_drag = ""
	s06_wipe_t = -1.0
	s06_lens_marked = [false, false, false, false, false, false, false, false]
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
	objective_label.text = _t("goal.s06.01")
	_hall_say([
		_t("s06.enter.01"),
		_t("s06.enter.02")
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
	_hall_open_item(String(item.name))
	queue_redraw()

func _s06_talk_to_cleaner() -> void:
	var size := _s05_cleaner_size()
	if s06_wipe_t >= 0.0:
		_show_dialogue(_t("s06.cleaner.01"))
	elif s06_case_clean:
		_show_dialogue(_t("s06.cleaner.02"))
	elif size == "giant":
		if not s06_has_card:
			s06_has_card = true
			chapter_state.mark_event(&"s06_card_received")
			_hall_say([
				_t("s06.cleaner.03"),
				_t("s06.cleaner.04")
			])
		else:
			_show_dialogue(_s05_cleaner_aside())
	elif not s06_shadow_done:
		if size == "normal":
			_show_dialogue(_t("s06.cleaner.05"))
		else:
			_show_dialogue(_s05_cleaner_aside())
	elif size == "tiny":
		_s06_cleaner_climbs_in()
	elif size == "normal":
		_show_dialogue(_t("s06.cleaner.06"))
	else:
		_show_dialogue(_s05_cleaner_aside())

func _try_toggle_s06_blue_lake() -> void:
	# LAN's chalk works up close in S06: in the pile's close-up and the rack's.
	if not s06_lamp_on:
		_show_dialogue(_t("s06.lake.01"))
	elif not s06_shadow_done:
		_show_dialogue(_t("s06.lake.02"))
	elif s06_case_clean and not s06_sensor_revealed:
		_show_dialogue(_t("s06.lake.03"))
	else:
		_show_dialogue(_t("s06.lake.chalk_none"))

func _s06_chalk_hint() -> String:
	if not s06_shadow_done:
		return "s06.lake.chalk_pile"
	if s06_case_clean and not s06_sensor_revealed:
		return "s06.lake.chalk_rack"
	return "s06.lake.chalk_none"

func _try_s06_chalk_interaction() -> void:
	pass

func _s06_shadow_is_kent() -> bool:
	for piece in S06_PIECES:
		if not _s06_piece_ok(piece):
			return false
	return true

func _s06_shadow_complete() -> void:
	s06_shadow_done = true
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Standard"
	chapter_state.mark_event(&"s06_shadow_is_kent")
	_hall_say([
		_t("s06.shadow.01"),
		_t("s06.shadow.02")
	])

func _s06_cleaner_climbs_in() -> void:
	s06_wipe_t = 0.0
	chapter_state.mark_event(&"s06_cleaner_climbed_in")
	objective_label.text = _t("goal.s06.02")
	_hall_say([
		_t("s06.wipe.01"),
		_t("s06.wipe.02")
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
		_t("s06.reveal.01"),
		_t("s06.reveal.02"),
		_t("s06.reveal.03")
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
	s07_fish_fled = false
	s07_achievement_time = -1.0
	blue_lake_active = false
	blue_lake_transform_completed = false
	chalk_cursor.set_active(false)
	chapter_state.advance_to(ChapterState.Slice.S07_RETURN)
	chapter_state.set_map_state(&"Museum_S07_RedHouse")
	chapter_state.set_player_goal(&"reobserve_old_areas")
	chapter_state.mark_story_event(&"s07_started")
	objective_label.text = _t("goal.s07.01")
	_hall_say([
		_t("s07.enter.01"),
		_t("s07.enter.02")
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
	_hall_open_item(String(item.name))
	queue_redraw()


func _try_toggle_s07_blue_lake() -> void:
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue(_t("s07.windows.01"))
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	if blue_lake_active:
		_show_dialogue(_t("s07.windows.chalk_hall") if s07_room == "hall" else _t("s07.windows.chalk_room"))
	else:
		_show_dialogue(_t("common.put_away"))
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
			_show_dialogue(_t("s07.windows.02"))
			return
		_s07_travel(room)
	elif s07_room != "hall" and chalk_hover_target == "ReturnWindow":
		_s07_travel("hall")

func _s07_travel(room: String) -> void:
	blue_lake_active = false
	chalk_cursor.set_active(false)
	visual_mode = "Standard"
	s07_travel_to = room
	s07_travel_anim = 0.0
	player.input_locked = true
	_show_dialogue(_t("s07.windows.03"))
	_update_ui()

func _s07_arrive(room: String) -> void:
	player.input_locked = false
	if room == "hall":
		s07_room = "hall"
		_s05_set_depth_mode(true)
		player.position = Vector2(_s05_px(S05_MURAL_CX, 0.88), _s05_y(0.88))
		_show_dialogue(_t("s07.windows.04"))
		_s07_shelve_new()
	else:
		s07_room = room
		_s05_set_depth_mode(false)
		player.position = Vector2(160.0, 470.0)
		chapter_state.mark_event(StringName("s07_visited_" + room))
		_show_dialogue(_t({"s01": "s07.windows.arrive_s01", "s02": "s07.windows.arrive_s02", "s04": "s07.windows.arrive_s04"}[room]))
	queue_redraw()

func _s07_room_interact() -> void:
	var nearest := _get_nearest_s07_interactable()
	if nearest.is_empty():
		return
	_s07_room_open(String(nearest.name))

func _s07_find(room: String) -> void:
	s07_found[room] = true
	chapter_state.mark_event(StringName("s07_found_" + room))
	if room != "hall":
		objective_label.text = _t("goal.s07.02")

## Back in the hall, the cleaner numbers and shelves what Graham found, with a remark.
func _s07_shelve_new() -> void:
	var lines: Array = []
	var remarks := {
		"s01": _t("s07.shelve.01"),
		"s02": _t("s07.shelve.02"),
		"s04": _t("s07.shelve.03"),
		"hall": _t("s07.shelve.04")
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
		lines.append(_t("s07.shelve.05"))
		chapter_state.mark_event(&"achievement_all_filed")
		_unlock_achievement("ACH_CH1_ALL_FILED")
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
	blue_lake_active = false
	chalk_cursor.set_active(false)
	# The guard comes in at the back, past the bucket.
	s08_guard = Vector2(_s05_px(960, 0.93), _s05_y(0.93))
	s08_mouse = Vector2(940, 0.95)
	s08_mouse_on = false
	s08_mouse_wp = 0
	s08_mouse_dir = -1.0
	s08_mouse_clock = 0.0
	s08_lost_time = 0.0
	s08_shout_t = 0.0
	s08_shout_i = 0
	chapter_state.advance_to(ChapterState.Slice.S08_TRUE_EXIT)
	chapter_state.set_map_state(&"Museum_S08_Escape")
	chapter_state.set_player_goal(&"escape")
	chapter_state.mark_story_event(&"s08_started")
	objective_label.text = _t("goal.s08.01")
	_show_dialogue(_t("s08.run.01"))
	_update_ui()
	queue_redraw()

func _update_s08_chase(delta: float) -> void:
	_update_s08_mouse(delta)
	# The circle only closes while she runs right behind the mouse; otherwise it holds.
	if _s08_following():
		s08_run += absf(player.velocity.x) * delta + absf(player.velocity.y) * delta
		s08_lost_time = 0.0
		s08_shout_t += delta
		if s08_shout_t > 6.0:
			s08_shout_t = 0.0
			_show_dialogue(_t(S08_SHOUTS[s08_shout_i % S08_SHOUTS.size()]))
			s08_shout_i += 1
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
	_draw_s08_mouse()
	var gz := clampf((S05_NEAR_Y - s08_guard.y) / (S05_NEAR_Y - S05_FAR_Y), 0.0, 1.0)
	var s := _s05_scale(gz)
	var g := s08_guard
	draw_rect(Rect2(g.x - 12 * s, g.y - 46 * s, 24 * s, 40 * s), Color("#566b7a"), true)
	draw_circle(Vector2(g.x, g.y - 54 * s), 10.0 * s, Color("#bba88c"))
	draw_line(Vector2(g.x + 10 * s, g.y - 40 * s), Vector2(g.x + 10 * s + signf(player.position.x - g.x) * 22 * s, g.y - 44 * s), Color("#566b7a"), 4.0 * s)
	draw_string(ThemeDB.fallback_font, Vector2(g.x - 20, g.y - 72 * s), _t("sign.s08.01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f0c6a5"))
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
	_show_dialogue(_t("s08.run.02"))

func _try_toggle_s08_blue_lake() -> void:
	_show_dialogue(_t("s08.run.03"))

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
	_show_dialogue(_t("s05.window.01"))
	_show_space_prompt()
	queue_redraw()

func _try_toggle_s05_blue_lake() -> void:
	if s05_room == "hall":
		_show_dialogue(_t("s05.lake.02"))
		return
	if not blue_lake_active and not blue_lake_transform_completed:
		player.input_locked = true
		_hide_space_prompt()
		_show_dialogue(_t("common.shared.01"))
		blue_lake_transform.play()
		return
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_hide_space_prompt()
	_show_dialogue(_t("s05.lake.chalk_window") if blue_lake_active else _t("common.put_away"))
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
	_show_dialogue("")
	objective_label.text = _t("goal.s05.04")
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
	objective_label.text = _t("goal.s05.05")
	_show_dialogue(_t("s05.enter.01"))
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
	s04_mouse = ""
	s04_mouse_climb = 0.0
	s04_mouse_seen = false
	s04_mouse_hint_t = 0.0
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
	objective_label.text = _t("goal.s04.04")
	_show_dialogue(_t("s04.enter.01"))
	_update_ui()
	queue_redraw()

func _update_route_transitions() -> void:
	if not player or scene_state != "gallery":
		return
	# S03: after trading places with her reflection, Graham leaves by the far (里) door on the right.
	if s03_active and s03_crossed and player.position.x >= 1005.0:
		_s03_leave()

func _s03_far_door_x() -> float:
	return _s02_mx(S02_DOOR_RECT.get_center().x)

func _s03_leave() -> void:
	if not s03_active:
		return
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
	s03_dark_time = 0.0
	s03_eye_lit = false
	s03_pov_active = false
	s03_hands_seen = false
	s03_glove_off = false
	s03_guard_x = S02_GUARD_X
	s03_arms_returned = false
	s03_mirror_held = false
	s03_crossed = false
	s02_mouse_run = 0.0
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
	objective_label.text = _t("goal.s03.06")
	_show_dialogue(_t("s03.enter.01"))
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
		_show_dialogue(_t("legacy.flow.08"))
		_update_ui()
		queue_redraw()
		return
	if chalk_hover_target == "Window" and mirror_solved and not handle_found:
		visual_mode = "Window Handle Layer"
		handle_found = true
		_show_dialogue(_t("legacy.flow.09"))
		_update_ui()
		queue_redraw()
		return
	if chalk_hover_target == "Window" and mirror_solved and handle_found and not window_open:
		visual_mode = "Open Window Layer"
		window_open = true
		_show_dialogue(_t("legacy.flow.10"))
		_update_ui()
		queue_redraw()
		await get_tree().create_timer(1.0).timeout
		_start_transition()
		return

func _interact_mirror() -> void:
	_show_dialogue(_t("legacy.flow.11"))

func _interact_painting() -> void:
	if not blue_lake_active:
		_show_dialogue(_t("legacy.flow.12"))
	else:
		_show_dialogue(_t("legacy.flow.13"))

func _interact_window() -> void:
	if not blue_lake_active:
		_show_dialogue(_t("legacy.flow.14"))
		return
	if not handle_found:
		visual_mode = "Wide View"
		handle_found = true
		_show_dialogue(_t("legacy.flow.15"))
		_update_ui()
		return
	if handle_found and not window_open:
		visual_mode = "High Contrast"
		window_open = true
		_show_dialogue(_t("legacy.flow.16"))
		queue_redraw()
		_update_ui()
		await get_tree().create_timer(1.0).timeout
		_start_transition()
		return
	_show_dialogue(_t("legacy.flow.17"))

func _start_transition() -> void:
	if transition_started:
		return
	transition_started = true
	player.input_locked = true
	_show_dialogue(_t("legacy.flow.18"))
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
		objective_label.text = _t("goal.s08.02")
		_show_dialogue(_t("s08.theater.01"))
	else:
		_show_dialogue(_t("legacy.flow.19"))
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
	draw_string(ThemeDB.fallback_font, Vector2(435, 405), _t("sign.s08.02"), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("#f0d6a1"))
	# Stage floor and the spotlight that follows Graham: she arrives being watched.
	draw_rect(Rect2(80, 460, 992, 60), Color("#4a3426"))
	if player:
		var spot_x := player.position.x
		draw_colored_polygon(PackedVector2Array([Vector2(spot_x - 18.0, 120), Vector2(spot_x + 18.0, 120), Vector2(spot_x + 70.0, 515), Vector2(spot_x - 70.0, 515)]), Color(1.0, 0.94, 0.75, 0.16))
		draw_circle(Vector2(spot_x, 505), 62.0, Color(1.0, 0.94, 0.75, 0.14))

	_draw_theater_reveal()
## --- Script: every line of dialogue and every sign is read by ID from data/dialogue_ch1.md ---------
const DialogueScript = preload("res://scripts/dialogue_script.gd")
const DIALOGUE_PATH := "res://data/dialogue_ch1.md"
var dialogue_lines: Dictionary = {}

## The text for an ID in the script file. {name} placeholders are filled from args.
func _t(id: String, args: Dictionary = {}) -> String:
	if dialogue_lines.is_empty():
		dialogue_lines = DialogueScript.load_file(DIALOGUE_PATH)
	if not dialogue_lines.has(id):
		push_error("dialogue_ch1.md has no line with ID " + id)
		return id
	var text: String = dialogue_lines[id]
	return text.format(args) if not args.is_empty() else text

func _show_dialogue(text: String) -> void:
	if dialogue_label:
		dialogue_label.text = text.replace("｛", "").replace("｝", "")
	_dlg_start(text)

## Dialogue playback: each line of a text is typed out on its own, then the next one replaces it.
## In the script, text inside ｛｝ types slowly; a line with "！" gives the box a small shake;
## a blank line is a short pause. LAN's lines are blue, narration is a warm grey.
func _dlg_start(text: String) -> void:
	dlg_lines.clear()
	var pause := 0.0
	for raw in text.split("\n"):
		if raw.strip_edges() == "":
			pause += 0.5
			continue
		var shown := ""
		var slow_mask: Array[bool] = []
		var slow := false
		for ch in raw:
			if ch == "｛":
				slow = true
				continue
			if ch == "｝":
				slow = false
				continue
			shown += ch
			slow_mask.append(slow)
		dlg_lines.append({"text": shown, "steps": _dlg_steps(shown, slow_mask), "pause": pause})
		pause = 0.0
	dlg_index = 0
	_dlg_apply_line()

## How a line comes out: a list of [characters visible, wait before showing them].
## Narration: all at once. Speech: a short line all at once; a long one phrase by phrase, the way
## it is said (pause after commas, longer after full stops); characters inside ｛｝ one by one.
func _dlg_speaker_end(text: String) -> int:
	var colon := text.find("：")
	if colon > 0 and colon <= 6 and not text.substr(0, colon).contains("，"):
		return colon + 1
	return -1

func _dlg_steps(text: String, slow_mask: Array[bool]) -> Array:
	var n := text.length()
	var body := _dlg_speaker_end(text)
	var any_slow := slow_mask.has(true)
	if body < 0 or (not any_slow and n - body <= 16):
		return [[n, 0.0]]
	var steps := []
	var cur := 0
	var wait := 0.0
	for i in range(n):
		if slow_mask[i]:
			if i > cur:
				steps.append([i, wait])
				wait = 0.15
			steps.append([i + 1, wait])
			wait = 0.22
			cur = i + 1
			continue
		var ch := text[i]
		if i >= body and "，。！？；、）".contains(ch):
			var strong := "。！？".contains(ch)
			if strong or i + 1 - cur >= 5:
				steps.append([i + 1, wait])
				cur = i + 1
				wait = 0.32 if strong else 0.16
	if cur < n:
		steps.append([n, wait])
	return steps

func _dlg_apply_line() -> void:
	if dialogue_view == null:
		return
	if dlg_lines.is_empty():
		dialogue_view.text = ""
		if dialogue_more:
			dialogue_more.visible = false
		return
	if dialogue_more:
		dialogue_more.visible = false
	var line: Dictionary = dlg_lines[dlg_index]
	var text: String = line.text
	dialogue_view.text = text
	dialogue_view.visible_characters = 0
	dlg_shown = 0
	dlg_t = 0.0
	var color := Color("#e4dccb")
	var colon := _dlg_speaker_end(text) - 1
	if colon > 0:
		var who := text.substr(0, colon)
		if who.begins_with("LAN"):
			color = Color("#9fd2ff")
		elif who == "格雷汉":
			color = Color("#ffffff")
		else:
			color = Color("#ffe6a8")
	dialogue_view.add_theme_color_override("font_color", color)

## True while the current text still has another line after this one.
func _dlg_has_more() -> bool:
	return dlg_index < dlg_lines.size() - 1

## E while lines are waiting: finish the line being shown, or go on to the next one.
func _dlg_page() -> void:
	if dlg_lines.is_empty():
		dlg_wait_ack = false
		return
	var steps: Array = dlg_lines[dlg_index].steps
	if dlg_shown < steps.size():
		dialogue_view.visible_characters = -1
		dlg_shown = steps.size()
		dlg_t = 0.0
		return
	if _dlg_has_more():
		dlg_index += 1
		_dlg_apply_line()
		return
	dlg_wait_ack = false

## For sequences that used to run on a timer: show the text and wait until the player has read it
## through with E. In tests (dialogue_needs_e off) it waits `secs`, as before.
func _say_wait(text: String, secs: float) -> void:
	_show_dialogue(text)
	if not dialogue_needs_e:
		await get_tree().create_timer(secs).timeout
		return
	dlg_wait_ack = true
	while dlg_wait_ack:
		await get_tree().process_frame

## True when E will bring the next thing to read (another line, the end of a waited text, Venus's next line).
func _dlg_e_continues() -> bool:
	return _dlg_has_more() or dlg_wait_ack or (s03_pov_active and s03_pov_line < S03_POV_LINES.size())

func _update_dialogue_view(delta: float) -> void:
	if dialogue_view == null:
		return
	if dlg_shake > 0.0:
		dlg_shake -= delta
		dialogue_view.position = dlg_base_pos + Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0))
	else:
		dialogue_view.position = dlg_base_pos
	if dlg_index >= dlg_lines.size():
		return
	var line: Dictionary = dlg_lines[dlg_index]
	var steps: Array = line.steps
	var n := String(line.text).length()
	dlg_t += delta
	if dlg_shown < steps.size():
		while dlg_shown < steps.size() and dlg_t >= float(steps[dlg_shown][1]):
			dlg_t -= float(steps[dlg_shown][1])
			dialogue_view.visible_characters = int(steps[dlg_shown][0])
			dlg_shown += 1
		if dlg_shown >= steps.size():
			dlg_t = 0.0
			if String(line.text).contains("！"):
				dlg_shake = 0.3
		return
	if dialogue_needs_e:
		if dialogue_more:
			dialogue_more.visible = _dlg_e_continues() and fmod(Time.get_ticks_msec() * 0.001, 1.0) < 0.7
		return
	if dlg_index < dlg_lines.size() - 1:
		var hold := 0.7 + 0.035 * n + float(dlg_lines[dlg_index + 1].pause)
		if dlg_t >= hold:
			dlg_index += 1
			_dlg_apply_line()

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
	if closeup != "":
		var closeup_hint := _s01_closeup_hint() if s01_active else _hall_closeup_hint()
		if closeup_hint == "":
			interaction_hint_label.hide()
		else:
			var shown: Rect2 = CLOSEUP_RECTS[_closeup_kind()]
			interaction_hint_label.text = closeup_hint
			interaction_hint_label.position = Vector2(shown.get_center().x - 7.0 * closeup_hint.length(), shown.end.y + 8.0)
			interaction_hint_label.show()
		return
	if blue_lake_active:
		if chalk_hover_target == "":
			interaction_hint_label.hide()
			return
		interaction_hint_label.text = _t("hint.general.03")
		if s04_active:
			interaction_hint_label.text = _t("hint.s04.14") if chalk_hover_target == "S04Window" else (_t("hint.s04.15") if chalk_hover_target == "S04Mouse" else _t("hint.s04.16"))
		elif s05_active and chalk_hover_target == "Window":
			interaction_hint_label.text = _t("hint.s05.01")
		interaction_hint_label.position = get_viewport().get_mouse_position() + Vector2(14, -22)
		interaction_hint_label.show()
		return
	if s03_active and s03_ride_active:
		var ride_item := _s03_nearest_ride_item()
		if ride_item.is_empty():
			interaction_hint_label.hide()
		else:
			interaction_hint_label.text = _t("hint.s02.04") if ride_item.name == "BonsaiPot" else _t("hint.shared.07")
			interaction_hint_label.position = Vector2(s03_ride_x - 20.0, 398.0)
			interaction_hint_label.show()
		return
	if space_prompt_visible:
		interaction_hint_label.text = _t("hint.general.02")
		interaction_hint_label.position = Vector2(500, 455)
		interaction_hint_label.show()
		return
	var nearest := _get_nearest_interactable()
	if nearest.is_empty():
		interaction_hint_label.hide()
		return
	interaction_hint_label.text = _t("hint.general.04")
	if s01_active:
		var n: String = nearest.get("name", "")
		if s01_clocks_seen and n == "ClockBack":
			interaction_hint_label.text = _t("hint.s01.05")
		elif s01_clocks_seen and n == "ClockForward":
			interaction_hint_label.text = _t("hint.s01.06")
		elif n == "ExitDoor" and s01_gate_open:
			interaction_hint_label.text = _t("hint.s01.07")
		elif n == "ExitDoor" and s01_has_key:
			interaction_hint_label.text = _t("hint.s01.08")
		elif n == "CommunityMap" and s01_has_chalk and not s01_has_key:
			interaction_hint_label.text = _t("hint.s01.09")
	if s03_active:
		var n3: String = nearest.get("name", "")
		if n3 == "SculptureVenus" and _venus_arm_waiting():
			interaction_hint_label.text = _t("hint.s02.05")
		elif n3 == "HallDoor" and s03_mirror_held and not s03_crossed:
			interaction_hint_label.text = _t("hint.s02.06")
		if s03_crossed and player and absf(player.position.x - _s03_far_door_x()) <= 70.0:
			interaction_hint_label.text = _t("hint.s03.exit")
	if s05_active or s06_active or s07_active or s08_active:
		var n5: String = nearest.get("name", "")
		if not s05_lines.is_empty():
			interaction_hint_label.text = _t("hint.shared.01")
		elif n5 == "Eyepiece":
			interaction_hint_label.text = _t("hint.shared.07")
	if s04_active:
		var n4: String = nearest.get("name", "")
		if not s04_lines.is_empty():
			interaction_hint_label.text = _t("hint.shared.01")
		elif n4 in ["Restorer", "Visitor", "VisitorGroup"]:
			interaction_hint_label.text = _t("hint.shared.06")
		elif n4 == "Workbench" and s04_has_riboflavin and not s04_riboflavin_applied:
			interaction_hint_label.text = _t("hint.s04.17")
		elif n4 == "Workbench" and s04_girl_caught:
			interaction_hint_label.text = _t("hint.s04.06") if s04_uv_on else _t("hint.s04.07")
		elif n4 == "Window" and s04_girl_caught and not s04_frame_installed and not (s04_uv_on and s04_win_t >= 0.5 and not s04_handle_found):
			interaction_hint_label.text = _t("hint.s04.12")
	var hint_y: float = nearest.get("hint_y", nearest.position.y - nearest.radius * 0.55)
	interaction_hint_label.position = Vector2(nearest.position.x - 28.0, hint_y)
	interaction_hint_label.show()

func _update_chalk_hover() -> void:
	var previous := chalk_hover_target
	chalk_hover_target = ""
	if closeup != "":
		return
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
		if chalk_hover_target == "" and s04_mouse == "eating" and mouse_position.distance_to(_s04_mouse_pos() + Vector2(0, -6)) <= 22.0:
			chalk_hover_target = "S04Mouse"
		if chalk_hover_target == "" and mouse_position.distance_to(S05_WINDOW_CENTER) <= 62.0:
			chalk_hover_target = "S04Window"
	elif S05_ENABLED and s05_active:
		# The whole framed painting (and a margin around it) opens it, not just the small handle.
		if s05_room == "window" and not s05_window_open and Rect2(S05_WINDOW_CENTER - Vector2(53, 58), Vector2(106, 116)).grow(28.0).has_point(mouse_position):
			chalk_hover_target = "Window"
	elif S06_ENABLED and s06_active:
		pass   # S06's chalk works inside the pile's and the rack's close-ups
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

## ===== Close-ups in the sensor hall (S05–S08) ===================================================
## Five things to look at up close, instead of twelve E points:
## - the eyepiece (big: A/D slides the lens along its rail; the blur changes as it goes),
## - the cleaner with his bucket (big: Graham's hand, WASD; how big he is depends on where she stood;
##   the bucket's water is 《那喀索斯》's water, and the boy looks up out of it),
## - the rack's last row (the fifth case, its card, the cleaner wiping inside it, and the sensor),
## - the pile of exhibits with the floor lamp (in S06 a big close-up seen from behind the lamp: LAN's
##   chalk drags the pieces and their shadows move over the mural),
## - the mural.
## The lens, the lamp, the bucket and the four plinths are no longer E points of their own.

func _sensor_hall() -> bool:
	return s05_active or s06_active or s07_active or s08_active

## Where an item of the hall stands on screen, for its close-up to grow from.
func _hall_item_rect(item_name: String) -> Rect2:
	if item_name == "Mural":
		return _s05_mural_rect()
	if item_name == "Rack":
		return _s06_case_rect().grow(30.0)
	var item := _s05_item(item_name)
	if item.is_empty():
		return Rect2(536, 260, 80, 80)
	var z := _s05_item_z(item)
	var s := _s05_scale(z)
	var x := _s05_px(float(item.x), z)
	var foot := _s05_y(z)
	if item_name == "Cleaner":
		var top := S05_MURAL_HORIZON - 30.0
		return Rect2(x - 30 * s, top, 60 * s, foot - top)
	return Rect2(x - 40 * s, foot - 80 * s, 80 * s, 80 * s)

func _hall_open_item(n: String) -> void:
	match n:
		"Eyepiece":
			chapter_state.mark_event(&"s05_eyepiece_used")
			_open_closeup("eyepiece", _hall_item_rect("Eyepiece"))
			s05_lens_pos = float(s05_lens_notch)
			_show_dialogue(_eyepiece_text())
		"Cleaner":
			_open_closeup("cleaner", _hall_item_rect("Cleaner"))
			var spot: Array = CLEANER_SPOT[_s05_cleaner_size()]
			closeup_hand = spot[0]
			_show_dialogue(_cleaner_look_text())
		"Rack":
			_open_closeup("rack", _hall_item_rect("Rack"))
			_show_dialogue(_rack_text())
		"Pile":
			chapter_state.mark_event(&"s05_pile_seen")
			_open_closeup("pile", _hall_item_rect("Pile"))
			_show_dialogue(_pile_text())
		"Bucket":
			_hall_bucket()
		"Mural":
			chapter_state.mark_event(&"s05_mural_seen")
			_open_closeup("mural", _hall_item_rect("Mural"))
			_show_dialogue(_mural_text())

## Puts a close-up away at once (when what happens in it leads straight on).
func _closeup_force_close() -> void:
	closeup = ""
	closeup_t = 0.0
	closeup_closing = false
	closeup_anim = ""
	venus_drag = ""
	s06_drag = ""
	if player and not s01_eyelid_closed:
		player.input_locked = false

## --- Texts --------------------------------------------------------------------------------------
func _eyepiece_text() -> String:
	if s07_active:
		return _s07_telescope_text()
	if not s05_lens_clean:
		if s05_cleaner_met:
			return _t("hall.eyepiece.01")
		return _t("hall.eyepiece.02")
	if s05_cell_seen and s05_lens_notch == S05_FOCUS_NOTCH:
		return _t("hall.eyepiece.03")
	return _t("hall.eyepiece.04")

func _cleaner_look_text() -> String:
	match _s05_cleaner_size():
		"giant":
			return _t("hall.cleaner.01")
		"tiny":
			return _t("hall.cleaner.02")
	return _t("hall.cleaner.03")

func _rack_text() -> String:
	if s08_stolen:
		return _t("hall.rack.01")
	if s07_active:
		return _t("hall.rack.02")
	if s06_sensor_revealed:
		return _t("hall.rack.03")
	if s06_wipe_t >= 0.0:
		return _t("hall.rack.04")
	if s06_case_clean:
		return _t("hall.rack.05")
	var dots := "dots" if s05_cell_seen else "plain"
	var card := "card" if s06_has_card else ("no_card" if s06_active else "none")
	return _t({"plain": {"none": "hall.rack.row", "card": "hall.rack.row_card", "no_card": "hall.rack.row_no_card"}, "dots": {"none": "hall.rack.row_dots", "card": "hall.rack.row_dots_card", "no_card": "hall.rack.row_dots_no_card"}}[dots][card])

func _pile_text() -> String:
	if s06_active and s06_shadow_done:
		return _t("hall.pile.01")
	if s06_active and s06_lamp_on:
		return _t("hall.pile.02")
	if s06_active:
		return _t("hall.pile.03")
	return _t("hall.pile.04")

func _mural_text() -> String:
	if s07_active:
		var lit := 0
		for room in S07_WINDOW_ROOMS:
			if s07_shelved[room]:
				lit += 1
		if lit == 0:
			return _t("hall.mural.01")
		return _t("hall.mural.lit", {"n": lit})
	if s06_shadow_done:
		return _t("hall.mural.02")
	return _t("hall.mural.03")

func _s07_telescope_text() -> String:
	if s05_lens_notch >= 4:
		return _t("s07.telescope.blurred")
	var room: String = S07_WINDOW_ROOMS[s05_lens_notch]
	return _t({"s01": "s07.telescope.s01", "s02": "s07.telescope.s02", "s04": "s07.telescope.s04", "hall": "s07.telescope.hall"}[room])

## --- E / Space / mouse inside the close-ups -------------------------------------------------------
func _sensor_closeup_press_e() -> bool:
	match closeup:
		"cleaner":
			match _cleaner_spot(closeup_hand):
				"him":
					if s05_active:
						_s05_talk_to_cleaner()
					elif s06_active:
						_s06_talk_to_cleaner()
					else:
						_s07_talk_to_cleaner()
					return true
				"bucket":
					_hall_bucket()
					return true
		"rack":
			if s07_active and not s08_stolen:
				if not s07_hesitated:
					_s01_play("reach")
					_show_dialogue(_t("s08.take.01"))
				else:
					_s01_play("take")
					_show_dialogue(_t("s08.take.02"))
				return true
		"pile":
			if s06_active and not s06_lamp_on:
				_s01_play("switch")
				return true
		"map", "narcissus", "girl":
			if s07_active and s07_room != "hall":
				return _s07_room_closeup_e()
	return false

func _sensor_closeup_hint() -> String:
	match closeup:
		"eyepiece":
			return _t("hint.hall.01")
		"cleaner":
			match _cleaner_spot(closeup_hand):
				"him":
					return _t("hint.shared.06")
				"bucket":
					return _t("hint.hall.02") if (s07_active and not s07_found.get("hall", true)) else _t("hint.hall.03")
			return _t("hint.shared.03")
		"rack":
			if s07_active and not s08_stolen:
				return _t("hint.hall.04") if s07_hesitated else _t("hint.hall.05")
			if s06_active and s06_case_clean and not s06_sensor_revealed:
				return _t("hint.hall.06") if blue_lake_active else _t("hint.shared.04")
		"pile":
			if s06_active and not s06_lamp_on:
				return _t("hint.hall.07")
			if s06_active and not s06_shadow_done:
				return _t("hint.hall.08") if blue_lake_active else _t("hint.shared.04")
		"map":
			if s07_active and s07_room == "s01" and not s07_found["s01"]:
				return _t("hint.hall.09")
		"girl":
			if s07_active and s07_room == "s04" and not s07_found["s04"]:
				return _t("hint.hall.10")
		"narcissus":
			return _t("hint.shared.02") if _narc_spot_at(closeup_hand) != "" else _t("hint.shared.03")
	return _t("hint.shared.05")

## Space in the pile or rack close-up: LAN's chalk. (No transformation scene here: LAN has been
## chalk before; S06 just hands it back.)
func _sensor_closeup_space() -> bool:
	if closeup == "pile" and s06_active and not s06_shadow_done:
		if not s06_lamp_on:
			_show_dialogue(_t("s06.lake.01"))
		else:
			_sensor_chalk_toggle(_t("s06.lake.04"))
		return true
	if closeup == "rack" and s06_active and s06_case_clean and not s06_sensor_revealed:
		_sensor_chalk_toggle(_t("s06.lake.05"))
		return true
	return false

func _sensor_chalk_toggle(on_line: String) -> void:
	if closeup_anim != "":
		return
	blue_lake_transform_completed = true
	blue_lake_active = not blue_lake_active
	chalk_cursor.set_active(blue_lake_active)
	visual_mode = "Chalk Interaction" if blue_lake_active else "Standard"
	_show_dialogue(on_line if blue_lake_active else _t("common.put_away"))
	_update_ui()

func _sensor_closeup_mouse(mb: InputEventMouseButton) -> bool:
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT or closeup_closing:
		return false
	var local := _closeup_local(mb.position)
	if closeup == "pile":
		if mb.pressed:
			_s06_grab(local)
		else:
			_s06_drop(local)
		return true
	if closeup == "rack" and mb.pressed:
		_s06_rack_chalk(local)
		return true
	return false

func _sensor_anim_done(done: String) -> bool:
	match done:
		"sponge":
			s05_lens_clean = true
			chapter_state.mark_event(&"s05_lens_cleaned")
			_show_dialogue(_t("s05.eyepiece.01"))
			return true
		"tail":
			chapter_state.mark_event(&"s04_mouse_caught")
			if s04_riboflavin_applied:
				s04_mouse = "running"
				s04_mouse_x = S04_BENCH_X + 14.0
				_show_dialogue(_t("s04.mouse.01_run"))
			else:
				s04_mouse = "table"
				_show_dialogue(_t("s04.mouse.01"))
			return true
		"switch":
			s06_lamp_on = true
			chapter_state.mark_event(&"s06_lamp_on")
			_show_dialogue(_t("s06.shadow.03"))
			return true
		"kent":
			_s06_shadow_complete()
			return true
		"reach":
			s07_hesitated = true
			chapter_state.mark_event(&"s07_hesitated")
			_show_dialogue(_t("s08.take.03"))
			return true
		"take":
			_closeup_force_close()
			_s08_steal()
			return true
		"peel":
			_s07_find(s07_room)
			match s07_room:
				"s01":
					_show_dialogue(_t("s07.rooms.peel_sticker"))
				"s04":
					_show_dialogue(_t("s07.rooms.pull_drawing"))
			return true
	return false

## --- The eyepiece: A/D slide the lens along its rail -----------------------------------------------
func _s05_lens_step(dir: int) -> void:
	if closeup_anim != "" or closeup_closing or closeup_t < 1.0:
		return
	var to := s05_lens_notch + dir
	if to < 0 or to >= S05_RAIL_NOTCHES:
		_show_dialogue(_t("s05.eyepiece.02"))
		return
	s05_lens_notch = to
	chapter_state.mark_event(&"s05_lens_moved")
	if s07_active:
		_show_dialogue(_s07_telescope_text())
		return
	if s05_lens_notch == S05_CLEAN_NOTCH and not s05_lens_clean:
		_s01_play("sponge")
		_show_dialogue(_t("s05.eyepiece.03"))
		return
	if s05_lens_clean and s05_lens_notch == S05_FOCUS_NOTCH and not s05_cell_seen and s05_active:
		s05_cell_seen = true
		s05_finish_pending = true
		chapter_state.mark_event(&"s05_last_cell_seen")
		_s05_say([
			_t("s05.eyepiece.04"),
			_t("s05.eyepiece.05"),
			_t("s05.eyepiece.06")
		])

## --- The cleaner and his bucket ------------------------------------------------------------------
func _cleaner_spot(p: Vector2) -> String:
	var spot: Array = CLEANER_SPOT[_s05_cleaner_size()]
	if p.distance_to(spot[0]) <= float(spot[1]):
		return "him"
	if p.distance_to(BUCKET_SPOT) <= 58.0:
		return "bucket"
	return ""

func _s07_talk_to_cleaner() -> void:
	if _s05_cleaner_size() != "normal":
		_show_dialogue(_s05_cleaner_aside())
	else:
		_show_dialogue(_t("s07.shelve.06"))

## The bucket's water is 《那喀索斯》's water: the boy looks up out of it. E touches it.
func _hall_bucket() -> void:
	if s07_active and not s07_found["hall"]:
		_s07_find("hall")
		_show_dialogue(_t("hall.bucket.01"))
		_s07_shelve_new()
		return
	if not chapter_state.has_event(&"s05_bucket_seen"):
		chapter_state.mark_event(&"s05_bucket_seen")
		_show_dialogue(_t("hall.bucket.02"))
		return
	_s01_play("ripple")
	chapter_state.mark_event(&"s05_bucket_touched")
	_show_dialogue(_t("hall.bucket.03"))

## --- The pile, seen from behind the lamp: dragging pieces moves their shadows on the mural -------
func _s06_piece_target(piece: String) -> Vector2:
	var s: Vector2 = S06_SHADOW_TARGET[piece]
	return S06_LAMP + (s - S06_LAMP) / S06_THROW

func _s06_shadow_at(p: Vector2) -> Vector2:
	return S06_LAMP + (p - S06_LAMP) * S06_THROW

func _s06_piece_pos(piece: String) -> Vector2:
	if s06_drag == piece and closeup == "pile" and closeup_anim == "":
		return _closeup_local(get_viewport().get_mouse_position()).clamp(S06_FLOOR.position, S06_FLOOR.end)
	return s06_pieces.get(piece, S06_PIECE_START[piece])

func _s06_piece_ok(piece: String) -> bool:
	var p: Vector2 = s06_pieces.get(piece, S06_PIECE_START[piece])
	return p.distance_to(_s06_piece_target(piece)) < 0.5

func _s06_grab(local: Vector2) -> void:
	if not (s06_active and s06_lamp_on and not s06_shadow_done) or closeup_anim != "":
		return
	var best := ""
	var best_d := 30.0
	for piece in S06_PIECES:
		if _s06_piece_ok(piece):
			continue
		var d := local.distance_to(s06_pieces[piece])
		if d < best_d:
			best_d = d
			best = piece
	s06_drag = best

func _s06_drop(local: Vector2) -> void:
	var piece := s06_drag
	s06_drag = ""
	if piece == "":
		return
	var p := local.clamp(S06_FLOOR.position, S06_FLOOR.end)
	chapter_state.mark_event(&"s06_piece_moved")
	var target: Vector2 = S06_SHADOW_TARGET[piece]
	if _s06_shadow_at(p).distance_to(target) <= S06_SNAP:
		# The right place: it settles there and its shadow lights up on the mural (no words).
		s06_pieces[piece] = _s06_piece_target(piece)
		if _s06_shadow_is_kent():
			_s01_play("kent")
			_show_dialogue(_t("s06.shadow.04"))
	else:
		s06_pieces[piece] = p

## --- The fifth case: the tiny cleaner wipes it from inside; LAN marks the eight lenses ------------
func _sensor_lens_at(i: int) -> Vector2:
	var spot: Vector2 = S06_LENS_SPOTS[i]
	return SENSOR_CASE.get_center() + spot * SENSOR_CASE.size

func _s06_rack_chalk(local: Vector2) -> void:
	if not (s06_active and s06_case_clean and not s06_sensor_revealed) or closeup_anim != "":
		return
	for i in range(S06_LENS_SPOTS.size()):
		if s06_lens_marked[i]:
			continue
		if local.distance_to(_sensor_lens_at(i)) <= 13.0:
			s06_lens_marked[i] = true
			chapter_state.mark_event(&"s06_lens_marked")
			if not s06_lens_marked.has(false):
				_s06_reveal_sensor()
			else:
				_show_dialogue(_t("s06.reveal.04") if s06_lens_marked.count(true) < 7 else _t("s06.reveal.05"))
			return
	if SENSOR_CASE.has_point(local):
		_show_dialogue(_t("s06.reveal.06"))

func _update_s06_wipe(delta: float) -> void:
	if s06_wipe_t < 0.0:
		return
	s06_wipe_t += delta / S06_WIPE_TIME
	if s06_wipe_t < 1.0:
		return
	s06_wipe_t = -1.0
	s06_case_clean = true
	chapter_state.mark_event(&"s06_case_cleaned")
	objective_label.text = _t("goal.s06.03")
	var line := _t("s06.wipe.03")
	if s05_lines.is_empty():
		_hall_say([line])
	else:
		s05_lines.append(line)

## --- S07: the old rooms' hidden things, found inside their old close-ups ---------------------------
func _s07_room_open(n: String) -> void:
	match n:
		"MapSticker":
			_open_closeup("map", S01_MAP_RECT)
			_show_dialogue(_t("s07.rooms.map_found") if s07_found["s01"] else _t("s07.rooms.map_unfound"))
		"BlueFish":
			_hall_open("narcissus", Rect2(240, 190, 150, 125))
			closeup_hand = Vector2(300, 300)
			_show_dialogue(_t("s07.rooms.narcissus_found") if s07_found["s02"] else _t("s07.rooms.narcissus_unfound"))
		"GirlDrawing":
			_open_closeup("girl", Rect2(S04_GIRL_FRAME_X - 45, 225, 90, 90))
			_show_dialogue(_t("s07.rooms.girl_found") if s07_found["s04"] else _t("s07.rooms.girl_unfound"))

func _s07_room_closeup_e() -> bool:
	match closeup:
		"map":
			if s07_room == "s01" and not s07_found["s01"]:
				_s01_play("peel")
				return true
		"girl":
			if s07_room == "s04" and not s07_found["s04"]:
				_s01_play("peel")
				return true
		"narcissus":
			var spot := _narc_spot_at(closeup_hand)
			if spot == "lamp":
				_show_dialogue(_t("s07.rooms.01"))
				return true
			if spot == "water" and s07_room == "s02" and not s07_found["s02"]:
				if not s07_fish_fled:
					s07_fish_fled = true
					_s01_play("ripple")
					_show_dialogue(_t("s07.rooms.02"))
				else:
					_s07_find("s02")
					_show_dialogue(_t("s07.rooms.take_fish"))
				return true
	return false

## --- Drawing: shared mural (the pile close-up and the mural close-up use the same picture) ---------
## Mural space (M): the house is 120 wide at (240, 80); the horizon is at y 150; 600 × 205 in all.
const MURAL_WINDOWS := [Vector2(252, 90), Vector2(328, 90), Vector2(252, 116), Vector2(328, 116)]
const MURAL_DOOR := Rect2(290, 124, 20, 26)

func _cv_mural(cv: CanvasItem, origin: Vector2, k: float, area: Rect2, lit_windows: bool) -> void:
	var hz: float = origin.y + 150.0 * k
	cv.draw_rect(Rect2(area.position, Vector2(area.size.x, hz - area.position.y)), Color("#8fc3ea"), true)
	cv.draw_rect(Rect2(Vector2(area.position.x, hz), Vector2(area.size.x, area.end.y - hz)), Color("#6aa84f"), true)
	cv.draw_circle(_mp(origin, k, Vector2(70, 34)), 14.0 * k, Color("#f3e3a0"))
	var spread := maxf(0.0, area.end.y - (origin.y + 205.0 * k)) / k
	cv.draw_colored_polygon(PackedVector2Array([_mp(origin, k, Vector2(294, 150)), _mp(origin, k, Vector2(306, 150)), _mp(origin, k, Vector2(370 + spread * 1.2, 205 + spread)), _mp(origin, k, Vector2(230 - spread * 1.2, 205 + spread))]), Color("#c9b98d"))
	cv.draw_rect(Rect2(_mp(origin, k, Vector2(240, 80)), Vector2(120, 70) * k), Color("#c2402f"), true)
	cv.draw_colored_polygon(PackedVector2Array([_mp(origin, k, Vector2(230, 80)), _mp(origin, k, Vector2(370, 80)), _mp(origin, k, Vector2(300, 46))]), Color("#7a2a22"))
	for i in range(4):
		var w := Rect2(_mp(origin, k, MURAL_WINDOWS[i]), Vector2(20, 16) * k)
		var lit: bool = lit_windows and s07_shelved.get(S07_WINDOW_ROOMS[i], false)
		if lit:
			cv.draw_rect(w.grow(4.0 * k), Color(1.0, 0.95, 0.6, 0.45), true)
		cv.draw_rect(w, Color("#fff6b0") if lit else Color("#f4e7b8"), true)
		cv.draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color("#7a2a22"), 1.0 * k)
		cv.draw_line(Vector2(w.position.x, w.get_center().y), Vector2(w.end.x, w.get_center().y), Color("#7a2a22"), 1.0 * k)
		if lit:
			_draw_s07_egg(S07_WINDOW_ROOMS[i], w.get_center(), 0.9 * k, cv)
	cv.draw_rect(Rect2(_mp(origin, k, MURAL_DOOR.position), MURAL_DOOR.size * k), Color("#5a2a1c"), true)

func _mp(origin: Vector2, k: float, p: Vector2) -> Vector2:
	return origin + p * k

## The five pieces' shadows on the mural (in mural space, mapped by origin + p·k). A piece in the
## right place has its shadow outlined in light.
func _cv_shadows(cv: CanvasItem, origin: Vector2, k: float) -> void:
	var shade := Color(0.04, 0.06, 0.1, 0.72)
	var snap := Color(1.0, 0.86, 0.45, 0.85)
	var pulse := 0.0
	if closeup_anim == "kent":
		pulse = sin(closeup_anim_t * PI * 3.0) * 0.5 + 0.5
	for piece in S06_PIECES:
		var s := _s06_shadow_at(_s06_piece_pos(piece))
		var ok := _s06_piece_ok(piece)
		var t := S06_THROW
		match piece:
			"body":
				cv.draw_circle(_mp(origin, k, s), 24.0 * k, shade)
				cv.draw_circle(_mp(origin, k, s + Vector2(0, 20)), 15.0 * k, shade)
				if ok:
					cv.draw_arc(_mp(origin, k, s), 26.0 * k, 0.0, TAU, 32, snap, 2.0)
			"head":
				cv.draw_rect(Rect2(_mp(origin, k, s - Vector2(10, 8) * t), Vector2(20, 16) * t * k), shade, true)
				if ok:
					cv.draw_rect(Rect2(_mp(origin, k, s - Vector2(10, 8) * t), Vector2(20, 16) * t * k).grow(2.0), snap, false, 2.0)
			"legs_l", "legs_r":
				var dir := -1.0 if piece == "legs_l" else 1.0
				for j in range(4):
					var knee := s + Vector2(dir * (14 + j * 3), -9 + j * 6) * t
					var tip := knee + Vector2(dir * 8, 12) * t
					cv.draw_line(_mp(origin, k, s), _mp(origin, k, knee), shade, 5.0 * k)
					cv.draw_line(_mp(origin, k, knee), _mp(origin, k, tip), shade, 4.0 * k)
					if ok:
						cv.draw_circle(_mp(origin, k, tip), 3.0 * k, snap)
			"eyes":
				# Light comes through the little lenses: eight bright spots, two to a window when right.
				var bright := Color(1.0, 0.95, 0.7, 0.95)
				if closeup_anim == "kent":
					bright = bright.lerp(Color(1, 1, 1), pulse)
				for off in S06_EYE_SPOTS:
					cv.draw_circle(_mp(origin, k, s + off), (2.6 + pulse * 1.5) * k, bright)
				if ok:
					for i in range(4):
						cv.draw_rect(Rect2(_mp(origin, k, MURAL_WINDOWS[i]), Vector2(20, 16) * k).grow(2.0), snap, false, 1.5)

## --- Drawing: the five close-ups --------------------------------------------------------------------
func _draw_closeup_eyepiece(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var c := Vector2(240, 176)
	var radius := 150.0
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.03, 0.03, 0.04), true)
	if s07_active:
		_cv_telescope_view(cv, c)
	else:
		_cv_last_row_view(cv, c)
	# The fog on the old lens, wiped off by the cleaner's sponge.
	var fog := 0.0 if s05_lens_clean else 0.88
	var wipe := -1.0
	if closeup_anim == "sponge":
		wipe = closeup_anim_t
		fog = 0.88 * (1.0 - smoothstep(0.25, 0.8, wipe))
	if fog > 0.0:
		cv.draw_circle(c, radius, Color(0.92, 0.93, 0.95, fog))
	if wipe >= 0.0:
		# A huge sponge comes across the view and back.
		var x := c.x + lerpf(320.0, -40.0, smoothstep(0.0, 0.3, wipe)) + lerpf(0.0, -420.0, smoothstep(0.72, 1.0, wipe))
		var sp := Rect2(x - 120, c.y - 90, 240, 170)
		cv.draw_rect(sp, Color("#d9b84a"), true)
		var rng := RandomNumberGenerator.new()
		rng.seed = 41
		for i in range(40):
			cv.draw_circle(sp.position + Vector2(rng.randf() * sp.size.x, rng.randf() * sp.size.y), rng.randf_range(3, 9), Color("#a88a2a"))
		for i in range(6):
			var dx := sp.position.x + 20 + i * 38
			cv.draw_line(Vector2(dx, sp.end.y), Vector2(dx + 4, sp.end.y + 40 + i * 6), Color(0.45, 0.42, 0.36, 0.7), 3.0)
	# The eyepiece's round edge: everything outside it (inside the close-up) is black.
	_cv_round_mask(cv, c, radius, Rect2(Vector2.ZERO, sz), Color(0.03, 0.03, 0.04))
	cv.draw_arc(c, radius, 0.0, TAU, 72, Color("#b08d57"), 6.0)
	# The rail, as a brass scale under the view: the eyepiece at the left, the cleaning zone marked.
	var y := 360.0
	var x0 := 100.0
	var step := 70.0
	cv.draw_line(Vector2(x0 - 30, y), Vector2(x0 + step * (S05_RAIL_NOTCHES - 1) + 20, y), Color("#b08d57"), 3.0)
	cv.draw_string(font, Vector2(x0 - 70, y + 5), _t("sign.hall_closeup.01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	for i in range(S05_RAIL_NOTCHES):
		cv.draw_line(Vector2(x0 + i * step, y - 6), Vector2(x0 + i * step, y + 6), Color("#d9b36a"), 2.0)
	var cz := Rect2(x0 + S05_CLEAN_NOTCH * step - 22, y - 12, 44, 24)
	cv.draw_rect(cz, Color(0.55, 0.8, 0.95, 0.18), true)
	cv.draw_rect(cz, Color(0.75, 0.9, 1.0, 0.6), false, 1.5)
	cv.draw_string(font, Vector2(cz.position.x - 2, y + 26), _t("sign.hall_closeup.02"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#bfe8ff"))
	var lx := x0 + s05_lens_pos * step
	cv.draw_colored_polygon(PackedVector2Array([Vector2(lx, y - 8), Vector2(lx - 8, y - 22), Vector2(lx + 8, y - 22)]), Color("#e8dfc8"))
	cv.draw_string(font, Vector2(lx - 18, y - 28), _t("sign.hall_closeup.03"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e8dfc8"))
	cv.draw_string(font, Vector2(sz.x * 0.5 - 30, -10), _t("sign.hall_closeup.01"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _cv_round_mask(cv: CanvasItem, c: Vector2, radius: float, area: Rect2, col: Color) -> void:
	var n := 96
	var corners := [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]
	for i in range(n):
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var d0 := Vector2.RIGHT.rotated(a0)
		var d1 := Vector2.RIGHT.rotated(a1)
		var pts := PackedVector2Array([c + d0 * radius, c + d1 * radius, _ray_to_rect(c, d1, area)])
		for corner in corners:
			var ac := fposmod(((corner as Vector2) - c).angle(), TAU)
			if ac > a0 and ac < a1:
				pts.append(corner)
		pts.append(_ray_to_rect(c, d0, area))
		cv.draw_colored_polygon(pts, col)

func _ray_to_rect(c: Vector2, d: Vector2, area: Rect2) -> Vector2:
	var t := 1.0e6
	if d.x > 0.0001:
		t = minf(t, (area.end.x - c.x) / d.x)
	elif d.x < -0.0001:
		t = minf(t, (area.position.x - c.x) / d.x)
	if d.y > 0.0001:
		t = minf(t, (area.end.y - c.y) / d.y)
	elif d.y < -0.0001:
		t = minf(t, (area.position.y - c.y) / d.y)
	return c + d * t

## Through the eyepiece in S05/S06: the rack's last row, sharp only with the lens at the right notch.
func _cv_last_row_view(cv: CanvasItem, c: Vector2) -> void:
	cv.draw_circle(c, 150.0, Color("#3a4654"))
	var blur := absf(s05_lens_pos - float(S05_FOCUS_NOTCH)) * 5.0
	for i in range(5):
		var p := c + Vector2(-116 + i * 56, 0)
		if i < 4:
			var gap: int = S05_LAST_ROW_GAPS[i]
			if blur <= 0.15:
				_cv_c(cv, p, 20.0, gap, Color("#cfc8b4"), 7.0)
			else:
				for k in range(6):
					var off := Vector2(cos(k * 1.05), sin(k * 1.05)) * blur
					_cv_c(cv, p + off, 20.0, gap, Color(0.81, 0.78, 0.7, 0.25), 7.0 + blur)
		else:
			var box := Rect2(p - Vector2(26, 26), Vector2(52, 52))
			cv.draw_rect(box, Color(0.75, 0.77, 0.8, 0.55) if not s06_case_clean else Color("#1c2836"), true)
			if blur <= 0.15 and s05_lens_clean:
				for k in range(8):
					var spot: Vector2 = S06_LENS_SPOTS[k]
					cv.draw_circle(box.get_center() + spot * box.size, 4.0 if S06_LENS_BIG[k] else 2.6, Color("#1f3b55"))
			elif blur > 0.15:
				cv.draw_rect(box.grow(blur), Color(0.75, 0.77, 0.8, 0.2), true)

## Through the eyepiece in S07: past the rack to the mural; one window of the red house at a time.
func _cv_telescope_view(cv: CanvasItem, c: Vector2) -> void:
	cv.draw_circle(c, 150.0, Color("#8fc3ea"))
	cv.draw_rect(Rect2(c.x - 150, c.y + 80, 300, 80), Color("#6aa84f"), true)
	cv.draw_rect(Rect2(c.x - 110, c.y - 70, 220, 150), Color("#c2402f"), true)
	for i in range(4):
		var w := Rect2(c.x - 90 + (i % 2) * 110, c.y - 55 + (i / 2) * 66, 70, 50)
		var sharp := 1.0 - clampf(absf(s05_lens_pos - float(i)) * 2.0, 0.0, 1.0)
		cv.draw_rect(w, Color("#f4e7b8"), true)
		if sharp > 0.0:
			_draw_s07_window_scene(S07_WINDOW_ROOMS[i], w, cv)
		var haze := 1.0 - sharp
		if haze > 0.0:
			cv.draw_rect(w, Color(0.95, 0.9, 0.75, 0.9 * haze), true)
			for k in range(5):
				cv.draw_rect(w.grow(2.0 * k), Color(0.95, 0.9, 0.75, 0.15 * haze), false, 3.0)

func _cv_c(cv: CanvasItem, center: Vector2, radius: float, gap: int, col: Color, width: float) -> void:
	var gap_angle: float = [0.0, PI * 0.5, PI, PI * 1.5][gap]
	cv.draw_arc(center, radius, gap_angle + 0.45, gap_angle + TAU - 0.45, 24, col, width)

func _draw_closeup_cleaner(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var time := Time.get_ticks_msec() * 0.001
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#263243"), true)
	# Behind him the mural; his ladder leans flat against it.
	cv.draw_rect(Rect2(0, 0, sz.x, 150), Color("#8fc3ea"), true)
	cv.draw_rect(Rect2(0, 150, sz.x, 200), Color("#6aa84f"), true)
	cv.draw_rect(Rect2(0, 350, sz.x, 50), Color("#2f3a48"), true)
	var wood := Color("#8a7a62")
	cv.draw_line(Vector2(250, 400), Vector2(258, 0), wood, 8.0)
	cv.draw_line(Vector2(330, 400), Vector2(322, 0), wood, 8.0)
	for k in range(7):
		var ry := 380.0 - k * 56.0
		cv.draw_line(Vector2(252, ry), Vector2(328, ry), wood, 6.0)
	var rag := Color("#8d8f86") if s05_lens_clean else Color("#e8e2c8")
	var wiping := s06_wipe_t >= 0.0
	var size := _s05_cleaner_size()
	if not wiping:
		match size:
			"giant":
				# Only a shoe and a trouser leg fit in the picture.
				cv.draw_rect(Rect2(210, -10, 140, 330), Color("#5c7a6e"), true)
				cv.draw_line(Vector2(280, 0), Vector2(282, 300), Color(0.3, 0.42, 0.38), 3.0)
				cv.draw_colored_polygon(PackedVector2Array([Vector2(180, 360), Vector2(380, 360), Vector2(395, 330), Vector2(350, 300), Vector2(200, 300)]), Color("#3a2c22"))
				cv.draw_line(Vector2(185, 352), Vector2(385, 352), Color("#1f1712"), 6.0)
				cv.draw_string(font, Vector2(30, 40), _t("sign.hall_closeup.04"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#263243"))
			"tiny":
				var p := Vector2(292, 244)
				cv.draw_rect(Rect2(p.x - 3, p.y - 8, 6, 8), Color("#5c7a6e"), true)
				cv.draw_circle(p + Vector2(0, -10), 2.6, Color("#c9ad8e"))
				cv.draw_rect(Rect2(p.x - 9, p.y - 10, 3, 2), rag, true)
			_:
				var h := Vector2(282, 98)
				cv.draw_rect(Rect2(264, 196, 14, 80), Color("#3d4d46"), true)
				cv.draw_rect(Rect2(288, 196, 14, 80), Color("#3d4d46"), true)
				cv.draw_rect(Rect2(258, 122, 48, 80), Color("#5c7a6e"), true)
				cv.draw_circle(h, 22.0, Color("#c9ad8e"))
				cv.draw_arc(h + Vector2(0, -4), 22.0, PI * 1.1, PI * 1.9, 12, Color("#7a6a58"), 6.0)
				# His eyes do not quite agree on how far away you are.
				cv.draw_circle(h + Vector2(-8, -2), 3.0 + sin(time * 1.3) * 1.2, Color("#2a2420"))
				cv.draw_circle(h + Vector2(8, -2), 3.0 - sin(time * 1.3) * 1.2, Color("#2a2420"))
				cv.draw_line(h + Vector2(-6, 10), h + Vector2(6, 10), Color("#6a4a3a"), 2.0)
				cv.draw_line(Vector2(262, 136), Vector2(228, 182), Color("#5c7a6e"), 9.0)
				cv.draw_rect(Rect2(212, 178, 26, 20), rag, true)
	else:
		cv.draw_string(font, Vector2(214, 230), _t("sign.hall_closeup.05"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#263243"))
	# The bucket, its crack, and the water in it: 《那喀索斯》's water.
	if s07_active and not s07_found.get("hall", true):
		_draw_sparkle(cv, Vector2(176, 370), 13.0, true)
		_draw_s07_egg("hall", Vector2(176, 370), 2.4, cv)
		_draw_sparkle(cv, Vector2(176, 370), 13.0, false)
	var b := BUCKET_SPOT
	cv.draw_colored_polygon(PackedVector2Array([b + Vector2(-62, -20), b + Vector2(62, -20), b + Vector2(48, 52), b + Vector2(-48, 52)]), Color("#6f7d88"))
	cv.draw_polyline(PackedVector2Array([b + Vector2(-20, 52), b + Vector2(-14, 34), b + Vector2(-22, 20), b + Vector2(-16, 4)]), Color("#2b3138"), 2.0)
	for k in range(3):
		var dy := fmod(time * 60.0 + k * 20.0, 60.0)
		cv.draw_circle(b + Vector2(-19, 56 + dy), 2.2, Color(0.55, 0.78, 0.95, 0.8 * (1.0 - dy / 60.0)))
	var water := PackedVector2Array()
	for i in range(32):
		var a := TAU * i / 32.0
		water.append(b + Vector2(cos(a) * 58.0, -20 + sin(a) * 15.0))
	cv.draw_colored_polygon(water, Color(0.25, 0.42, 0.5))
	var ripple := closeup_anim_t if closeup_anim == "ripple" else -1.0
	var shake := 0.0 if ripple < 0.0 else sin(ripple * 30.0) * 9.0 * (1.0 - ripple)
	var face := b + Vector2(4, -20)
	var a_face := 0.75 if ripple < 0.0 else 0.25 + 0.5 * ripple
	cv.draw_circle(face + Vector2(shake, 0), 11.0, Color(0.85, 0.72, 0.6, a_face))
	cv.draw_arc(face + Vector2(shake, 0), 11.0, PI * 0.15, PI * 0.85, 10, Color(0.3, 0.2, 0.15, a_face), 4.0)
	cv.draw_line(face + Vector2(-5 - shake, -2), face + Vector2(-2 - shake, -2), Color(0.2, 0.15, 0.12, a_face), 1.5)
	cv.draw_line(face + Vector2(2 + shake, -2), face + Vector2(5 + shake, -2), Color(0.2, 0.15, 0.12, a_face), 1.5)
	if ripple >= 0.0:
		for k in range(3):
			var rr := (ripple * 1.2 - k * 0.2) * 60.0
			if rr > 0.0:
				var ring := PackedVector2Array()
				for i in range(25):
					var a := TAU * i / 24.0
					ring.append(b + Vector2(cos(a) * rr, -20 + sin(a) * rr * 0.26))
				cv.draw_polyline(ring, Color(0.9, 0.97, 1.0, 0.6 * (1.0 - ripple)), 2.0)
	var spot := _cleaner_spot(closeup_hand) if closeup_anim == "" else ""
	if spot == "him":
		var hs: Array = CLEANER_SPOT[size]
		cv.draw_arc(hs[0], float(hs[1]), 0.0, TAU, 32, Color(1, 1, 1, 0.45), 2.0)
	elif spot == "bucket":
		cv.draw_arc(b + Vector2(0, -6), 64.0, 0.0, TAU, 32, Color(1, 1, 1, 0.45), 2.0)
	_draw_closeup_hand(cv, sz.y + 70.0)
	cv.draw_string(font, Vector2(sz.x * 0.5 - 30, -10), _t("sign.hall_closeup.06"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _draw_closeup_rack(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var time := Time.get_ticks_msec() * 0.001
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#3a4654"), true)
	cv.draw_rect(Rect2(Vector2.ZERO, sz), Color("#566674"), false, 3.0)
	# The row above, cut off by the top of the picture.
	for i in range(3):
		_cv_c(cv, Vector2(120 + i * 90, 30), 30.0, [1, 3, 0][i], Color(0.81, 0.78, 0.7, 0.5), 10.0)
	# The last row: four C-shaped shelves, taller than a person, and the fifth case.
	for i in range(4):
		_cv_c(cv, Vector2(42 + i * 60, 192), 24.0, S05_LAST_ROW_GAPS[i], Color("#cfc8b4"), 9.0)
	var box := SENSOR_CASE
	var door_open := 0.0
	if closeup_anim == "take":
		door_open = smoothstep(0.05, 0.25, closeup_anim_t)
	if s08_stolen:
		cv.draw_rect(box, Color("#1c2836"), true)
	elif s06_sensor_revealed:
		cv.draw_rect(box, Color("#1c2836"), true)
		_cv_sensor(cv, box, time)
	elif s06_case_clean:
		cv.draw_rect(box, Color("#1c2836"), true)
		# 灰扑扑的一团: something is there, with no near and far.
		for k in range(6):
			cv.draw_circle(box.get_center() + Vector2(sin(k * 2.1) * 12, cos(k * 1.7) * 8), 40.0 - k * 4.0, Color(0.55, 0.57, 0.6, 0.12))
		for i in range(S06_LENS_SPOTS.size()):
			if s06_lens_marked[i]:
				var at := _sensor_lens_at(i)
				var r := 7.0 if S06_LENS_BIG[i] else 4.5
				cv.draw_circle(at, r + 2.0, Color("#0e1a24"))
				cv.draw_circle(at, r, Color("#2c6f9a"))
				cv.draw_circle(at + Vector2(-r * 0.3, -r * 0.3), r * 0.3, Color(1, 1, 1, 0.8))
				cv.draw_arc(at, r + 4.0, 0.0, TAU, 16, Color(0.75, 0.91, 1.0, 0.7), 1.5)
	else:
		cv.draw_rect(box, Color(0.82, 0.84, 0.87, 0.85), true)
		if s06_wipe_t >= 0.0:
			# The tiny cleaner inside, wiping arcs clear from within.
			var n := int(s06_wipe_t * 12.0)
			for k in range(n):
				var ac := box.position + Vector2(18 + (k % 4) * 30, 24 + (k / 4) * 34)
				cv.draw_arc(ac, 16.0, PI * 1.1, PI * 1.9, 12, Color("#3a4654"), 9.0)
			var me := box.position + Vector2(65 + sin(time * 3.0) * 44, 92)
			cv.draw_rect(Rect2(me.x - 3, me.y - 8, 6, 8), Color("#5c7a6e"), true)
			cv.draw_circle(me + Vector2(0, -10), 2.6, Color("#c9ad8e"))
			cv.draw_arc(me + Vector2(8, -14), 7.0, -1.2 + sin(time * 9.0), 0.4 + sin(time * 9.0), 8, Color("#8d8f86"), 3.0)
		elif s05_cell_seen:
			# Someone breathed on it from inside: eight small clear spots in the fog.
			for i in range(S06_LENS_SPOTS.size()):
				cv.draw_circle(_sensor_lens_at(i), 6.0 if S06_LENS_BIG[i] else 4.0, Color(0.45, 0.52, 0.6, 0.85))
	cv.draw_rect(box, Color(0.8, 0.92, 1.0, 0.7), false, 2.0)
	if door_open > 0.0:
		cv.draw_colored_polygon(PackedVector2Array([box.position, box.position + Vector2(box.size.x * (1.0 - door_open), -18 * door_open), box.position + Vector2(box.size.x * (1.0 - door_open), box.size.y + 18 * door_open), box.position + Vector2(0, box.size.y)]), Color(0.8, 0.92, 1.0, 0.25))
	cv.draw_string(font, box.position + Vector2(4, -6), _t("sign.hall_closeup.07"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8dfc8"))
	if s06_has_card and not s08_stolen:
		_cv_card(cv, Rect2(266, 272, 138, 112))
	# In S07, at the other end of the rack, the cleaner (normal size from here) is looking this way.
	if s07_active:
		var h := Vector2(6, 318)
		cv.draw_circle(h, 26.0, Color("#c9ad8e"))
		cv.draw_circle(h + Vector2(12, -4), 3.5, Color("#2a2420"))
		cv.draw_rect(Rect2(h.x - 22, h.y + 24, 40, 60), Color("#5c7a6e"), true)
	if closeup_anim in ["reach", "take"]:
		var k := smoothstep(0.0, 0.6, closeup_anim_t) if closeup_anim == "reach" else 1.0 - smoothstep(0.75, 1.0, closeup_anim_t)
		closeup_hand = Vector2(330, 470).lerp(box.get_center() + Vector2(0, 60), k)
		_draw_closeup_hand(cv, sz.y + 90.0)
	cv.draw_string(font, Vector2(sz.x * 0.5 - 60, -10), _t("sign.hall_closeup.08"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

## The sensor: a small spider-shaped body, eight lenses in two rows (the middle pair of the front
## row large), and eight short stubs where it would be fixed.
func _cv_sensor(cv: CanvasItem, box: Rect2, time: float) -> void:
	var c := box.get_center()
	for i in range(8):
		var side := -1.0 if i < 4 else 1.0
		var a := (i % 4) * 0.35 - 0.5
		var root := c + Vector2(side * 30, 16 + (i % 4) * 4)
		cv.draw_line(root, root + Vector2(side * 22, 0).rotated(a * side), Color("#4a5560"), 3.0)
	cv.draw_colored_polygon(PackedVector2Array([c + Vector2(-46, -30), c + Vector2(46, -30), c + Vector2(54, 4), c + Vector2(34, 34), c + Vector2(-34, 34), c + Vector2(-54, 4)]), Color("#2b333b"))
	for i in range(S06_LENS_SPOTS.size()):
		var at := _sensor_lens_at(i)
		var r := 7.0 if S06_LENS_BIG[i] else 4.5
		cv.draw_circle(at, r + 2.0, Color("#0e1a24"))
		cv.draw_circle(at, r, Color("#2c6f9a").lerp(Color("#9fe3ff"), 0.4 + 0.3 * sin(time * 2.0 + i)))
		cv.draw_circle(at + Vector2(-r * 0.3, -r * 0.3), r * 0.3, Color(1, 1, 1, 0.8))

## The catalogue card for case 5: the red house, and where its owner's eyes, head, body and legs go.
func _cv_card(cv: CanvasItem, r: Rect2) -> void:
	var font := ThemeDB.fallback_font
	cv.draw_rect(r, Color("#e8e2c8"), true)
	cv.draw_circle(r.position + Vector2(r.size.x * 0.5, 4), 3.0, Color("#8a3a2a"))
	cv.draw_string(font, r.position + Vector2(6, 16), _t("sign.hall_closeup.09"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#4a3a2a"))
	var c := r.position + Vector2(r.size.x * 0.5, 54)
	cv.draw_rect(Rect2(c.x - 26, c.y - 24, 52, 28), Color(0.76, 0.25, 0.18, 0.35), true)
	cv.draw_rect(Rect2(c.x - 5, c.y - 8, 10, 12), Color(0.35, 0.16, 0.11, 0.45), true)
	var ink := Color(0.12, 0.1, 0.1, 0.85)
	cv.draw_circle(Vector2(c.x, c.y - 2), 6.0, ink)
	cv.draw_circle(Vector2(c.x, c.y + 16), 11.0, ink)
	for dir in [-1.0, 1.0]:
		for k in range(4):
			var root := Vector2(c.x + dir * 5, c.y + 17)
			var knee := root + Vector2(dir * (16 + k * 3), -10 + k * 6)
			cv.draw_line(root, knee, ink, 2.5)
			cv.draw_line(knee, knee + Vector2(dir * 7, 11), ink, 2.0)
	for wpos in [Vector2(-18, -20), Vector2(10, -20), Vector2(-18, -11), Vector2(10, -11)]:
		cv.draw_rect(Rect2(c + wpos, Vector2(8, 6)), Color(0.96, 0.9, 0.7), true)
		cv.draw_circle(c + wpos + Vector2(2.5, 3), 1.1, ink)
		cv.draw_circle(c + wpos + Vector2(5.5, 3), 1.1, ink)
	cv.draw_string(font, r.position + Vector2(6, r.size.y - 22), _t("sign.hall_closeup.10"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#4a3a2a"))
	cv.draw_string(font, r.position + Vector2(6, r.size.y - 8), _t("sign.hall_closeup.11"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#4a3a2a"))

func _draw_closeup_pile(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	# Far away, the mural; in front, the floor with the pile; right behind the viewer, the lamp.
	_cv_mural(cv, Vector2.ZERO, 1.0, Rect2(0, 0, sz.x, 205), false)
	if s06_lamp_on:
		_cv_shadows(cv, Vector2.ZERO, 1.0)
	cv.draw_rect(Rect2(0, 205, sz.x, sz.y - 205), Color("#2f3a48"), true)
	for i in range(1, 5):
		var fy := 205.0 + i * 38.0
		cv.draw_line(Vector2(0, fy), Vector2(sz.x, fy), Color(1, 1, 1, 0.05), 1.0)
	if not s06_lamp_on:
		cv.draw_rect(Rect2(0, 205, sz.x, sz.y - 205), Color(0.0, 0.0, 0.02, 0.35), true)
	else:
		cv.draw_colored_polygon(PackedVector2Array([Vector2(240, sz.y), Vector2(360, sz.y), Vector2(sz.x, 205), Vector2(0, 205)]), Color(1.0, 0.95, 0.75, 0.10))
	for piece in S06_PIECES:
		var p := _s06_piece_pos(piece)
		var ok := _s06_piece_ok(piece)
		if ok:
			cv.draw_circle(p, 18.0, Color(1.0, 0.86, 0.45, 0.18))
		match piece:
			"body":
				cv.draw_circle(p, 15.0, Color("#d8d4cc"))
				cv.draw_circle(p + Vector2(4, -2), 7.0, Color("#3c6e8f"))
				cv.draw_circle(p + Vector2(4, -2), 3.0, Color("#101418"))
			"head":
				cv.draw_rect(Rect2(p - Vector2(10, 8), Vector2(20, 16)), Color("#9aa7ab"), true)
				cv.draw_circle(p + Vector2(0, 1), 4.0, Color("#26323a"))
			"legs_l", "legs_r":
				var dir := -1.0 if piece == "legs_l" else 1.0
				for j in range(4):
					var knee := p + Vector2(dir * (14 + j * 3), -9 + j * 6)
					cv.draw_line(p, knee, Color("#b08d57"), 3.0)
					cv.draw_line(knee, knee + Vector2(dir * 8, 12), Color("#b08d57"), 2.5)
			"eyes":
				cv.draw_rect(Rect2(p - Vector2(28, 10), Vector2(56, 20)), Color(0.35, 0.38, 0.42, 0.7), true)
				for off in S06_EYE_SPOTS:
					cv.draw_circle(p + (off as Vector2) / S06_THROW, 2.4, Color("#9fd0f5"))
		if blue_lake_active and s06_active and not s06_shadow_done and not ok:
			cv.draw_arc(p, 22.0, 0.0, TAU, 20, Color(0.75, 0.91, 1.0, 0.9 if s06_drag == piece else 0.4), 2.0)
	# The lamp, just behind: the top of its shade at the bottom edge.
	cv.draw_colored_polygon(PackedVector2Array([Vector2(250, sz.y + 4), Vector2(350, sz.y + 4), Vector2(330, sz.y - 22), Vector2(270, sz.y - 22)]), Color("#d6c79f"))
	if s06_lamp_on:
		cv.draw_circle(Vector2(300, sz.y - 22), 14.0, Color(1.0, 0.95, 0.7, 0.8))
	cv.draw_string(font, Vector2(sz.x * 0.5 - 60, -10), _t("sign.hall_closeup.12"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

func _draw_closeup_mural(cv: CanvasItem, sz: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var origin := Vector2(-150, 7.5)
	_cv_mural(cv, origin, 1.5, Rect2(Vector2.ZERO, sz), s07_active)
	if s06_lamp_on and (s06_active or s07_active):
		_cv_shadows(cv, origin, 1.5)
	# The cleaner's ladder, lying flat against the painting the way it would against any wall.
	var wood := Color("#8a7a62")
	cv.draw_line(Vector2(500, sz.y), Vector2(520, 60), wood, 5.0)
	cv.draw_line(Vector2(546, sz.y), Vector2(560, 60), wood, 5.0)
	for k in range(8):
		var t := (k + 1) / 9.0
		cv.draw_line(Vector2(500, sz.y).lerp(Vector2(520, 60), t), Vector2(546, sz.y).lerp(Vector2(560, 60), t), wood, 4.0)
	cv.draw_string(font, Vector2(sz.x * 0.5 - 20, -10), _t("sign.hall_closeup.13"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#e8dfc8"))

## --- Hyper-real inserts of the sensor hall ---------------------------------------------------------
func _draw_hyper_sponge(cv: CanvasItem, r: Rect2, p: float) -> void:
	# Glass with a film of grime; a sponge full of dirty water pressed flat against it.
	cv.draw_rect(r, Color(0.52, 0.56, 0.57), true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	for i in range(120):
		var q := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		cv.draw_line(q, q + Vector2(rng.randf_range(-40, 40), rng.randf_range(-6, 6)), Color(0.38, 0.36, 0.3, 0.25), rng.randf_range(1.0, 4.0))
	var c := r.get_center() + Vector2(lerpf(120.0, -120.0, p), 0)
	var press := 1.0 + 0.08 * sin(p * PI * 3.0)
	var sp := Rect2(c - Vector2(200, 130) * press, Vector2(400, 230) * press)
	# The wet halo where it touches.
	cv.draw_rect(sp.grow(14.0), Color(0.3, 0.3, 0.26, 0.45), true)
	var pts := PackedVector2Array()
	for i in range(40):
		var a := TAU * i / 40.0
		var d := Vector2(cos(a), sin(a))
		var q := Vector2(signf(d.x) * pow(absf(d.x), 0.4), signf(d.y) * pow(absf(d.y), 0.4))
		pts.append(sp.get_center() + q * sp.size * 0.5)
	_hyper_poly(cv, pts, _hyper_texture("sponge"), r)
	for i in range(260):
		var q := sp.position + Vector2(rng.randf() * sp.size.x, rng.randf() * sp.size.y)
		var big := rng.randf_range(1.5, 7.0)
		cv.draw_circle(q, big, Color(0.3, 0.24, 0.1, 0.85))
		if big > 4.5:
			cv.draw_circle(q + Vector2(-big * 0.3, -big * 0.3), big * 0.25, Color(1, 1, 1, 0.55))
	# Grey-brown water squeezed out, running down the glass.
	for i in range(16):
		var x := sp.position.x + 12 + i * (sp.size.x - 24) / 15.0
		var line := PackedVector2Array([Vector2(x, sp.end.y)])
		var y := sp.end.y
		var run := rng.randf_range(40, r.end.y - sp.end.y) * minf(1.0, p * 2.2)
		while y < sp.end.y + run:
			y += 12.0
			line.append(Vector2(x + sin(y * 0.15 + i) * 3.0, y))
		if line.size() > 1:
			cv.draw_polyline(line, Color(0.42, 0.38, 0.3, 0.8), rng.randf_range(2.0, 5.0))
			cv.draw_circle(line[line.size() - 1], 4.0, Color(0.45, 0.41, 0.33, 0.9))
			cv.draw_circle(line[line.size() - 1] + Vector2(-1.5, -1.5), 1.2, Color(1, 1, 1, 0.7))
	cv.draw_line(r.position + Vector2(40, 40), r.position + Vector2(180, 10), Color(1, 1, 1, 0.25), 6.0)

func _draw_hyper_spider(cv: CanvasItem, r: Rect2, p: float) -> void:
	# A jumping spider's face, far too close: two huge glossy main eyes, smaller ones beside them, hair.
	cv.draw_texture_rect(_hyper_texture("chitin"), r, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	var c := r.get_center() + Vector2(0, 10)
	for i in range(700):
		var q := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		var away := (q - c).normalized()
		var col := Color(0.55, 0.42, 0.28, 0.6) if rng.randf() < 0.7 else Color(0.9, 0.85, 0.72, 0.7)
		cv.draw_line(q, q + away.rotated(rng.randf_range(-0.6, 0.6)) * rng.randf_range(6, 22), col, rng.randf_range(0.8, 1.8))
	for side in [-1.0, 1.0]:
		var e2 := c + Vector2(side * 250, 36)
		cv.draw_circle(e2, 40.0, Color(0.03, 0.03, 0.03))
		cv.draw_arc(e2, 38.0, PI * 1.1, PI * 1.6, 12, Color(0.4, 0.6, 0.35, 0.6), 3.0)
		cv.draw_circle(e2 + Vector2(-12, -14), 8.0, Color(1, 1, 1, 0.8))
	for side in [-1.0, 1.0]:
		var e := c + Vector2(side * 108, 0)
		cv.draw_circle(e, 100.0, Color(0.02, 0.02, 0.02))
		# Deep inside, the retina; it shifts as the eye focuses on you.
		var inner := Color(0.32, 0.2, 0.08).lerp(Color(0.06, 0.04, 0.03), p)
		for k in range(6):
			cv.draw_circle(e + Vector2(side * 6 * p, 4), 80.0 - k * 12.0, inner.lerp(Color(0.02, 0.02, 0.02), k / 6.0))
		cv.draw_arc(e, 96.0, PI * 0.9, PI * 1.5, 24, Color(0.35, 0.55, 0.4, 0.55), 5.0)
		cv.draw_arc(e, 96.0, PI * 1.6, PI * 2.0, 16, Color(0.6, 0.45, 0.25, 0.5), 4.0)
		cv.draw_circle(e + Vector2(-34, -40), 22.0, Color(1, 1, 1, 0.85))
		cv.draw_circle(e + Vector2(-8, -56), 7.0, Color(1, 1, 1, 0.7))
		# A tiny bright window reflected in it, four panes.
		var w := Rect2(e + Vector2(28, 18), Vector2(22, 18))
		cv.draw_rect(w, Color(1, 1, 1, 0.55), true)
		cv.draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color(0, 0, 0, 0.6), 2.0)
		cv.draw_line(Vector2(w.position.x, w.get_center().y), Vector2(w.end.x, w.get_center().y), Color(0, 0, 0, 0.6), 2.0)
	for i in range(80):
		var q := c + Vector2(rng.randf_range(-200, 200), rng.randf_range(100, 170))
		cv.draw_line(q, q + Vector2(rng.randf_range(-4, 4), rng.randf_range(10, 26)), Color(0.95, 0.92, 0.82, 0.8), 1.4)

func _draw_hyper_aperture(cv: CanvasItem, r: Rect2, p: float) -> void:
	# A lens of the sensor, looking at Graham's hand: scratched brass, coated glass, and the blades closing.
	cv.draw_texture_rect(_hyper_texture("brass"), r, false)
	var c := r.get_center()
	cv.draw_circle(c, 186.0, Color(0.05, 0.05, 0.05))
	for k in range(36):
		var d := Vector2.RIGHT.rotated(k * TAU / 36.0)
		cv.draw_line(c + d * 174.0, c + d * 184.0, Color(0.8, 0.75, 0.6, 0.6), 1.5)
	cv.draw_circle(c, 170.0, Color(0.06, 0.08, 0.1))
	# Through the opening: her hand, warm and out of focus.
	var hand := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		hand.append(c + Vector2(30, 40) + Vector2(cos(a) * 130.0, sin(a) * 100.0))
	_hyper_poly(cv, hand, _hyper_texture("skin"), r)
	cv.draw_circle(c, 170.0, Color(0.1, 0.12, 0.16, 0.25))
	var open := lerpf(150.0, 22.0, p * p * (3.0 - 2.0 * p))
	var twist := p * 0.9
	for i in range(8):
		var a0 := i * TAU / 8.0 + twist
		var a1 := (i + 1) * TAU / 8.0 + twist
		var quad := PackedVector2Array([c + Vector2.RIGHT.rotated(a0) * open, c + Vector2.RIGHT.rotated(a1) * open, c + Vector2.RIGHT.rotated(a1 + 0.5) * 172.0, c + Vector2.RIGHT.rotated(a0 + 0.5) * 172.0])
		cv.draw_colored_polygon(quad, Color(0.13, 0.13, 0.14).lerp(Color(0.2, 0.2, 0.22), float(i % 2)))
		cv.draw_line(c + Vector2.RIGHT.rotated(a0) * open, c + Vector2.RIGHT.rotated(a0 + 0.5) * 172.0, Color(0.5, 0.5, 0.55, 0.7), 1.5)
	# Coating reflections on the glass.
	cv.draw_arc(c, 150.0, PI * 1.05, PI * 1.45, 24, Color(0.7, 0.4, 0.95, 0.5), 8.0)
	cv.draw_arc(c, 120.0, PI * 1.6, PI * 1.85, 16, Color(0.4, 0.95, 0.6, 0.45), 6.0)
	cv.draw_circle(c + Vector2(-70, -80), 26.0, Color(1, 1, 1, 0.6))
	cv.draw_circle(c + Vector2(-40, -104), 8.0, Color(1, 1, 1, 0.6))

## ===== The white mouse (小白鼠): one small character through the four rooms of chapter 1 =========
## 第一幕 (S01): once time has run on to 多年以后, a mouse hole in the skirting and a mouse peeking out.
## 第二幕 (S02/S03): on the 里 side it keeps running left, and keeps being back on the right again.
## 第三幕 (S04): at dusk, when both apples of 《双生》 show, it comes out to gnaw them; startled, it
##   dives into the riboflavin bottle; pulled out by the tail, it has shaken the paint off except in
##   the creases of its joints (the hint), and runs off to the visitors, who in the dark under
##   ultraviolet see only its dots move — and know it for a mouse.
## 第四幕 (S08): it was behind the bucket all along (it knocked the bucket over); the guard kicks the
##   bucket, it bolts, and only following it makes the circle close.
const MOUSE_HOLE_S01 := Vector2(615, 372)
const S04_MOUSE_Y := 488.0
const S04_MOUSE_SPEED := 160.0
const S04_MOUSE_PACE := Vector2(900, 1000)     # where it runs to and fro, by the visitors
# S08: its route round the hall, in (near-plane x, depth z).
const S08_MOUSE_PATH := [Vector2(700, 0.8), Vector2(380, 0.66), Vector2(200, 0.4), Vector2(330, 0.16), Vector2(700, 0.1), Vector2(900, 0.3), Vector2(860, 0.6)]
const S08_MOUSE_SPEED := 175.0                 # screen pixels a second
const S08_FOLLOW := 200.0                      # this close (on screen) counts as following it
const S08_SHOUTS := ["s08.run.04", "s08.run.05", "s08.run.06"]

## A white mouse, facing `dir` (1 right, −1 left), size `k`. `glow` shows riboflavin dots in the
## creases of its joints; with `a` low (in the dark) only the dots remain.
func _draw_mouse(ci: CanvasItem, at: Vector2, k: float, dir: float, a: float = 1.0, glow: float = 0.0, moving: bool = true) -> void:
	var white := Color(0.95, 0.94, 0.92, a)
	var pink := Color(0.95, 0.66, 0.7, a)
	var tail := PackedVector2Array()
	for i in range(8):
		var u := i / 7.0
		tail.append(at + Vector2(-dir * (10.0 + u * 18.0), -2.0 + sin(u * 4.0 + mouse_t * 6.0) * 3.0) * k)
	if a > 0.02:
		ci.draw_polyline(tail, pink, maxf(1.6 * k, 1.0))
		for leg in _mouse_legs(at, k, dir, moving):
			ci.draw_polyline(PackedVector2Array(leg), pink, maxf(1.2 * k, 1.0))
		var body := PackedVector2Array()
		for i in range(16):
			var ang := TAU * i / 16.0
			body.append(at + Vector2(cos(ang) * 11.0, sin(ang) * 6.0 - 6.0) * k)
		ci.draw_colored_polygon(body, white)
		ci.draw_circle(at + Vector2(dir * 11.0, -7.0) * k, 4.5 * k, white)
		ci.draw_circle(at + Vector2(dir * 8.5, -12.0) * k, 2.6 * k, pink)
		ci.draw_circle(at + Vector2(dir * 13.0, -8.0) * k, 0.9 * k, Color(0.75, 0.1, 0.15, a))
		ci.draw_circle(at + Vector2(dir * 15.5, -6.5) * k, 1.0 * k, pink)
	if glow > 0.0:
		var nose := at + Vector2(dir * 14.0, -8.0) * k
		ci.draw_circle(nose, 3.2 * k, Color(0.78, 1.0, 0.35, 0.2 * glow))
		ci.draw_circle(nose, 1.3 * k, Color(0.9, 1.0, 0.5, glow))
		for leg in _mouse_legs(at, k, dir, moving):
			for j in [2]:
				var p: Vector2 = leg[j]
				ci.draw_circle(p, 3.2 * k, Color(0.78, 1.0, 0.35, 0.2 * glow))
				ci.draw_circle(p, 1.3 * k, Color(0.9, 1.0, 0.5, glow))

## Four legs: [top, knee, foot] each, swinging while it runs.
func _mouse_legs(at: Vector2, k: float, dir: float, moving: bool) -> Array:
	var legs := []
	var swing := sin(mouse_t * 22.0) if moving else 0.0
	for i in range(4):
		var x0 := (6.0 if i < 2 else -6.0) * dir + (1.5 if i % 2 == 0 else -1.5)
		var phase := swing * (1.0 if (i == 0 or i == 3) else -1.0)
		legs.append([at + Vector2(x0, -2.0) * k, at + Vector2(x0 + phase * 2.5 * dir, 1.5) * k, at + Vector2(x0 + phase * 4.0 * dir, 4.0) * k])
	return legs

## --- 第一幕 -----------------------------------------------------------------------------------
func _draw_s01_mouse() -> void:
	if s01_era < 2 and s01_melt == 0:
		return
	var h := MOUSE_HOLE_S01
	draw_colored_polygon(PackedVector2Array([h + Vector2(-9, 0), h + Vector2(-9, -8), h + Vector2(-5, -13), h + Vector2(0, -14), h + Vector2(5, -13), h + Vector2(9, -8), h + Vector2(9, 0)]), Color(0.05, 0.04, 0.03))
	# It peeks out now and then, and ducks back in when Graham comes near.
	var near := player != null and absf(player.position.x - h.x) < 90.0
	var peek := 0.0 if near else clampf(sin(mouse_t * 0.8) * 1.8, 0.0, 1.0)
	if peek > 0.05:
		_draw_mouse(self, h + Vector2(-6.0 - 10.0 * peek, 6.0), 0.8, -1.0, peek, 0.0, false)

## --- 第二幕 -----------------------------------------------------------------------------------
func _s02_mouse_x() -> float:
	# It runs right; the belt carries it left exactly as fast. It gains a little, loses a little.
	return 800.0 + sin(mouse_t * 0.9) * 26.0 + sin(mouse_t * 2.3) * 8.0 + s02_mouse_run

func _draw_s02_mouse() -> void:
	if not (s02_active or s03_active):
		return
	var x := _s02_mouse_x()
	if x > 1180.0:
		return
	# Running right on the 里 side and getting nowhere; once the belt stops it is off, out to the right.
	var fade := 1.0 - clampf((x - 1090.0) / 80.0, 0.0, 1.0)
	_draw_mouse(self, Vector2(x, S04_MOUSE_Y), 1.0, 1.0, 0.85 * fade)

## --- 第三幕 -----------------------------------------------------------------------------------
func _update_s04_mouse(delta: float) -> void:
	match s04_mouse:
		"":
			if s04_has_riboflavin and s04_window == "mid" and absf(s04_win_t - 0.5) < 0.1:
				s04_mouse = "eating"
				chapter_state.mark_event(&"s04_mouse_eating")
			elif s04_girl_caught and not s04_riboflavin_applied and s04_mouse_hint_t >= 0.0:
				s04_mouse_hint_t += delta
				if s04_mouse_hint_t > 25.0 and closeup == "" and s04_lines.is_empty():
					s04_mouse_hint_t = -1.0
					_show_dialogue(_t("s04.mouse.02"))
		"eating":
			if not chapter_state.has_event(&"s04_mouse_heard") and closeup == "" and s04_lines.is_empty():
				chapter_state.mark_event(&"s04_mouse_heard")
				_show_dialogue(_t("s04.mouse.03"))
			if s04_window != "mid":
				s04_mouse = ""   # one of the apples is gone again; it slips back behind the plinth
		"fleeing":
			s04_mouse_x = move_toward(s04_mouse_x, S04_BENCH_X + 14.0, S04_MOUSE_SPEED * delta)
			if s04_mouse_x <= S04_BENCH_X + 14.0:
				s04_mouse = "bottle"
				chapter_state.mark_event(&"s04_mouse_in_the_bottle")
				_show_dialogue(_t("s04.mouse.04"))
		"running":
			s04_mouse_x = move_toward(s04_mouse_x, S04_MOUSE_PACE.x, S04_MOUSE_SPEED * delta)
			if s04_mouse_x >= S04_MOUSE_PACE.x:
				s04_mouse = "pacing"
		"escaping":
			var wx := S05_WINDOW_CENTER.x
			if absf(s04_mouse_x - wx) > 0.5:
				s04_mouse_x = move_toward(s04_mouse_x, wx, S04_MOUSE_SPEED * 1.8 * delta)
			else:
				s04_mouse_climb = minf(1.0, s04_mouse_climb + delta * 1.2)
				if s04_mouse_climb >= 1.0:
					s04_mouse = "gone"
					s04_finish_pending = true
					var closing := _t("s04.end.01")
					if s04_lines.is_empty():
						_s04_say([closing])
					else:
						s04_lines.append(closing)
		"pacing":
			# By the visitors, to and fro. In the dark under ultraviolet only its dots show — and move.
			if s04_uv_on and s04_win_t > 0.9 and not s04_mouse_seen and closeup == "":
				s04_mouse_seen = true
				chapter_state.mark_event(&"s04_visitors_saw_the_mouse")
				_show_dialogue(_t("s04.mouse.05"))

func _s04_mouse_pos() -> Vector2:
	match s04_mouse:
		"table":
			return Vector2(S04_BENCH_X + 32.0, 337.0)
		"escaping":
			return Vector2(s04_mouse_x, lerpf(S04_MOUSE_Y, S05_WINDOW_CENTER.y + 30.0, s04_mouse_climb))
		"eating":
			return Vector2(S04_TWINS_X + 2.0, 326.0)
		"pacing":
			var span := S04_MOUSE_PACE.y - S04_MOUSE_PACE.x
			var u := fmod(mouse_t * 70.0, span * 2.0)
			return Vector2(S04_MOUSE_PACE.x + (u if u < span else span * 2.0 - u), S04_MOUSE_Y)
	return Vector2(s04_mouse_x, S04_MOUSE_Y)

func _s04_mouse_dir() -> float:
	if s04_mouse == "pacing":
		var span := S04_MOUSE_PACE.y - S04_MOUSE_PACE.x
		return 1.0 if fmod(mouse_t * 70.0, span * 2.0) < span else -1.0
	if s04_mouse == "fleeing" or s04_mouse == "eating" or s04_mouse == "table":
		return -1.0
	if s04_mouse == "escaping":
		return 1.0 if S05_WINDOW_CENTER.x >= s04_mouse_x else -1.0
	return 1.0

func _draw_s04_mouse() -> void:
	if s04_mouse == "" or s04_mouse == "caught" or s04_mouse == "gone":
		return
	if s04_mouse == "bottle":
		# Only its tail, hanging out of the bottle's neck.
		var top := Vector2(S04_BENCH_X + 13.0, 326.0)
		draw_polyline(PackedVector2Array([top, top + Vector2(3, -4), top + Vector2(7, -2), top + Vector2(9, 4) + Vector2(sin(mouse_t * 5.0), 0)]), Color(0.95, 0.66, 0.7), 1.6)
		return
	var dotted := s04_mouse in ["running", "pacing"]
	var dark := s04_uv_on and s04_win_t > 0.6
	var a := 0.12 if (dotted and dark) else 1.0
	var glow := (1.0 if dark else 0.55) if dotted else 0.0
	if s04_mouse == "table":
		glow = 0.55
	if s04_mouse == "escaping":
		a = 1.0 - clampf((s04_mouse_climb - 0.7) / 0.3, 0.0, 1.0)
	var gnaw := Vector2(0, sin(mouse_t * 18.0) * 1.0) if s04_mouse == "eating" else Vector2.ZERO
	_draw_mouse(self, _s04_mouse_pos() + gnaw, 0.9, _s04_mouse_dir(), a, glow, s04_mouse not in ["eating", "table"])

func _s04_scare_mouse() -> void:
	if s04_mouse != "eating":
		return
	s04_mouse = "fleeing"
	s04_mouse_x = S04_TWINS_X
	chapter_state.mark_event(&"s04_mouse_startled")
	_show_dialogue(_t("s04.mouse.06"))
	if closeup == "twins":
		_close_closeup()

## --- 第四幕 -----------------------------------------------------------------------------------
func _s08_mouse_screen() -> Vector2:
	return Vector2(_s05_px(s08_mouse.x, s08_mouse.y), _s05_y(s08_mouse.y))

func _update_s08_mouse(delta: float) -> void:
	s08_mouse_clock += delta
	if not s08_mouse_on:
		# The guard comes past the bucket first: he kicks it over, and the mouse behind it bolts.
		if s08_mouse_clock >= 0.7:
			s08_mouse_on = true
			chapter_state.mark_event(&"s08_mouse_bolted")
			_show_dialogue(_t("s08.mouse.01"))
		return
	var me := _s08_mouse_screen()
	var gap := me.distance_to(player.position)
	if gap > S08_FOLLOW * 1.2:
		# Too far ahead: it stops and looks back for her.
		s08_lost_time += delta
		if s08_lost_time > 3.0:
			s08_lost_time = -4.0
			_show_dialogue(_t("s08.mouse.02"))
		return
	var target: Vector2 = S08_MOUSE_PATH[s08_mouse_wp]
	var to := Vector2(_s05_px(target.x, target.y), _s05_y(target.y))
	var step := S08_MOUSE_SPEED * delta
	if me.distance_to(to) <= step:
		s08_mouse = target
		s08_mouse_wp = (s08_mouse_wp + 1) % S08_MOUSE_PATH.size()
	else:
		var nxt := me.move_toward(to, step)
		var z := clampf((S05_NEAR_Y - nxt.y) / (S05_NEAR_Y - S05_FAR_Y), 0.0, 1.0)
		var x := S05_VP.x + (nxt.x - S05_VP.x) / _s05_scale(z)
		s08_mouse = Vector2(x, z)
	s08_mouse_dir = signf(to.x - me.x) if absf(to.x - me.x) > 1.0 else s08_mouse_dir

## True while Graham is running right behind the mouse.
func _s08_following() -> bool:
	return s08_mouse_on and player != null and player.velocity.length() > 30.0 and _s08_mouse_screen().distance_to(player.position) < S08_FOLLOW

func _draw_s08_mouse() -> void:
	if not s08_stolen:
		return
	var s := _s05_scale(s08_mouse.y)
	_draw_mouse(self, _s08_mouse_screen(), 1.3 * s, s08_mouse_dir, 1.0, 0.0, s08_mouse_on)
