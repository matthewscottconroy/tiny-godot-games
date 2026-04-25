extends Node2D

@export var color: Color = Color.WHITE
@export var radius: float = 20.0
@export var velocity: Vector2 = Vector2(120, 90)
@export var label_text: String = "Ball"

var _vel: Vector2

func _ready() -> void:
	_vel = velocity
	queue_redraw()

func _process(delta: float) -> void:
	position += _vel * delta
	var vp := get_viewport_rect()
	if position.x - radius < 0 or position.x + radius > vp.size.x:
		_vel.x *= -1
		position.x = clampf(position.x, radius, vp.size.x - radius)
	if position.y - radius < 40 or position.y + radius > vp.size.y - 30:
		_vel.y *= -1
		position.y = clampf(position.y, radius + 40, vp.size.y - 30 - radius)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, color.darkened(0.3), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-radius * 0.8, 5), label_text,
		HORIZONTAL_ALIGNMENT_CENTER, radius * 1.6, 12, Color.WHITE)
