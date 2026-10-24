extends CharacterBody2D

class_name GrahamSteel

@export var speed := 230.0
@export var ground_y := 520.0
@export var ground_top := 482.0
var input_locked := false

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if input_locked:
		velocity = Vector2.ZERO
	else:
		# Keep movement on a narrow floor strip: WASD remains usable for positioning,
		# but the player cannot walk upward into the walls or artwork.
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * speed
	move_and_slide()
	global_position.x = clamp(global_position.x, 0.0, 1120.0)
	global_position.y = clamp(global_position.y, ground_top, ground_y)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color("#f2c6a0"))
	draw_circle(Vector2(0, -4), 15.0, Color("#2b3547"))
	draw_rect(Rect2(-10, 7, 20, 18), Color("#4b79a8"), true)
	draw_circle(Vector2(-5, -5), 2.0, Color("#17202e"))
	draw_circle(Vector2(5, -5), 2.0, Color("#17202e"))
