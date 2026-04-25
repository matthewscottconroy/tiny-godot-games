extends Node2D

var direction := Vector2.RIGHT
var speed := 420.0
var _lifetime := 0.0

func fire(from: Vector2, dir: Vector2) -> void:
	global_position = from
	direction = dir
	_lifetime = 1.8
	visible = true

func _return_to_pool() -> void:
	visible = false
	_lifetime = 0.0

func _process(delta: float) -> void:
	if not visible:
		return
	global_position += direction * speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		_return_to_pool()

func _draw() -> void:
	if visible:
		draw_circle(Vector2.ZERO, 5, Color.YELLOW)
