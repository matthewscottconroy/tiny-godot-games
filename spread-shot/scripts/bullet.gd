extends Node2D

const SPEED   := 420.0
const LIFETIME := 1.4

var _vel: Vector2 = Vector2.RIGHT * SPEED
var _age: float   = 0.0

func init(pos: Vector2, dir: Vector2) -> void:
	position = pos
	_vel     = dir.normalized() * SPEED

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME or position.x < -50.0 or position.x > 700.0:
		queue_free()
		return
	position += _vel * delta
	rotation  = _vel.angle()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4, Color.YELLOW)
	draw_line(Vector2.ZERO, Vector2(-10, 0), Color(1.0, 1.0, 0.0, 0.5), 2)
