extends StaticBody2D

@export var amplitude:  float   = 80.0
@export var period:     float   = 2.5
@export var axis:       Vector2 = Vector2(0.0, 1.0)
@export var draw_size:  Vector2 = Vector2(120.0, 14.0)

var _origin:  Vector2
var _elapsed: float = 0.0

func _ready() -> void:
	_origin = position

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var prev     := position
	var offset   := axis.normalized() * sin(_elapsed * TAU / period) * amplitude
	position                  = _origin + offset
	constant_linear_velocity  = (position - prev) / delta
	queue_redraw()

func _draw() -> void:
	var hw := draw_size.x * 0.5
	var hh := draw_size.y * 0.5
	draw_rect(Rect2(-hw, -hh, draw_size.x, draw_size.y), Color(0.55, 0.38, 0.20))
	draw_rect(Rect2(-hw, -hh, draw_size.x, draw_size.y), Color(0.85, 0.60, 0.30), false, 2.0)
