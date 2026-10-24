extends Control

signal finished

var progress := 0.0
var phase := "idle"
var message := ""
func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1152, 648)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	hide()

func begin() -> void:
	phase = "window"
	progress = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, 1.0)
	tween.tween_callback(_start_curtain)

func _start_curtain() -> void:
	phase = "curtain_close"
	progress = 0.0
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, 1.4)
	tween.tween_callback(_open_curtain)

func _open_curtain() -> void:
	phase = "curtain_open"
	progress = 0.0
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, 1.4)
	tween.tween_callback(_finish)

func _finish() -> void:
	phase = "done"
	hide()
	finished.emit()

func set_message(value: String) -> void:
	message = value

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if phase == "idle" or phase == "done":
		return
	var size := get_viewport().get_visible_rect().size
	var center := size.x * 0.5
	if phase == "window":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.09, 0.16, 0.82 * progress))
		draw_circle(Vector2(center, size.y * 0.48), 80.0 + progress * 160.0, Color(0.36, 0.76, 0.95, 0.18))
	elif phase == "curtain_close":
		draw_rect(Rect2(Vector2.ZERO, size), Color("#080b16"))
		var half := center * progress
		draw_rect(Rect2(0, 0, half, size.y), Color("#8b2635"))
		draw_rect(Rect2(size.x - half, 0, half, size.y), Color("#8b2635"))
		draw_line(Vector2(half, 0), Vector2(half, size.y), Color("#d07a7c"), 3.0)
		draw_line(Vector2(size.x - half, 0), Vector2(size.x - half, size.y), Color("#d07a7c"), 3.0)
	elif phase == "curtain_open":
		draw_rect(Rect2(Vector2.ZERO, size), Color("#080b16"))
		var half := center * (1.0 - progress)
		draw_rect(Rect2(0, 0, half, size.y), Color("#8b2635"))
		draw_rect(Rect2(size.x - half, 0, half, size.y), Color("#8b2635"))
