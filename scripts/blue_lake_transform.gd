extends Control

signal finished

var progress := 0.0

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1152, 648)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90
	hide()

func play() -> void:
	progress = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, 0.95)
	tween.tween_callback(_finish)

func _finish() -> void:
	hide()
	finished.emit()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	var center := Vector2(576, 330)
	var liquid_progress: float = clampf(progress / 0.58, 0.0, 1.0)
	var brush_progress: float = clampf((progress - 0.28) / 0.72, 0.0, 1.0)
	if liquid_progress > 0.0:
		var radius: float = 26.0 + liquid_progress * 46.0
		draw_circle(center, radius, Color(0.25, 0.72, 0.95, 0.18 * (1.0 - brush_progress * 0.5)))
		for i in range(8):
			var angle := float(i) * TAU / 8.0 + progress * 2.0
			var orbit: float = radius + 18.0 + sin(progress * 8.0 + i) * 5.0
			var point: Vector2 = center + Vector2(cos(angle), sin(angle)) * orbit
			draw_circle(point, 3.0 + liquid_progress * 3.0, Color("#bfe8ff"))
	if brush_progress > 0.0:
		var brush_length: float = 28.0 + brush_progress * 78.0
		var brush_center: Vector2 = center + Vector2(brush_progress * 34.0, -brush_progress * 16.0)
		draw_set_transform(brush_center, -0.45)
		draw_rect(Rect2(-6, -brush_length * 0.5, 12, brush_length), Color("#8bdfff"), true)
		draw_rect(Rect2(-8, -brush_length * 0.5 - 10, 16, 12), Color("#e0d8bd"), true)
		draw_colored_polygon(PackedVector2Array([Vector2(-7, brush_length * 0.5), Vector2(7, brush_length * 0.5), Vector2(0, brush_length * 0.5 + 18)]), Color("#62c7e8"))
		draw_set_transform(Vector2.ZERO)
