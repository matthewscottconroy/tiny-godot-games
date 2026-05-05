extends Node2D

const PATROL_SPEED := 100.0

@export var patrol_range: float = 100.0

var _patrol_dir := 1.0
var _origin:     Vector2

@onready var _area: Area2D = $HitArea

func _ready() -> void:
	_origin = position
	_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position.x += _patrol_dir * PATROL_SPEED * delta
	if absf(position.x - _origin.x) >= patrol_range:
		_patrol_dir *= -1.0
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit(global_position)

func _draw() -> void:
	draw_rect(Rect2(-14, -20, 28, 40), Color.ORANGE_RED)
	draw_circle(Vector2(0, -28), 10, Color.ORANGE_RED)
	draw_circle(Vector2(-4, -30), 3, Color.WHITE)
	draw_circle(Vector2(4,  -30), 3, Color.WHITE)
