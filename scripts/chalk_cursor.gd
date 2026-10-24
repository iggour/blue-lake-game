extends Control

var active := false
var blue := Color("#bfe8ff")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func set_active(value: bool) -> void:
	active = value
	visible = value
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if value else Input.MOUSE_MODE_VISIBLE)
	queue_redraw()

func _process(_delta: float) -> void:
	if active:
		position = get_viewport().get_mouse_position()
		queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_circle(Vector2.ZERO, 9.0, Color(0.75, 0.92, 1.0, 0.16))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, blue, 2.0)
	draw_line(Vector2(5, 5), Vector2(14, 14), Color("#ffffff"), 3.0)
	draw_line(Vector2(8, 8), Vector2(15, 15), Color("#82c8e8"), 1.0)
