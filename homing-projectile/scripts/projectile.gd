extends Node2D

const SPEED      := 280.0
const TURN_SPEED := 3.5
const LIFETIME   := 4.0

var _vel:    Vector2 = Vector2.RIGHT * SPEED
var _target: Node2D  = null
var _age:    float   = 0.0
var _trail:  Array[Vector2] = []

func init(pos: Vector2, dir: Vector2, target: Node2D) -> void:
	position = pos
	_vel     = dir.normalized() * SPEED
	_target  = target

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return

	if is_instance_valid(_target):
		var to_target  := (_target.global_position - global_position).angle()
		var cur_angle  := _vel.angle()
		var new_angle  := lerp_angle(cur_angle, to_target, TURN_SPEED * delta)
		_vel            = Vector2.from_angle(new_angle) * SPEED

	_trail.append(position)
	if _trail.size() > 12:
		_trail.pop_front()

	position += _vel * delta
	rotation  = _vel.angle()
	queue_redraw()

func _draw() -> void:
	for i in _trail.size():
		var tp    := to_local(_trail[i])
		var alpha := float(i) / _trail.size() * 0.5
		draw_circle(tp, 3.0, Color(1.0, 0.9, 0.2, alpha))
	draw_circle(Vector2.ZERO, 5, Color.YELLOW)
	draw_line(Vector2.ZERO, Vector2(-14, 0), Color(1, 0.8, 0, 0.6), 3)
