extends Node2D

@onready var ray: RayCast2D = $RayCast2D
@onready var line: Line2D = $Line2D

const RAY_LENGTH := 700.0

var _hit_point := Vector2.ZERO
var _is_hitting := false

func _process(_delta: float) -> void:
	var mouse_local := to_local(get_global_mouse_position())
	var direction := mouse_local.normalized()
	ray.target_position = direction * RAY_LENGTH
	ray.force_raycast_update()

	if ray.is_colliding():
		_hit_point = to_local(ray.get_collision_point())
		_is_hitting = true
		line.set_point_position(1, _hit_point)
	else:
		_is_hitting = false
		line.set_point_position(1, direction * RAY_LENGTH)

	queue_redraw()

func _draw() -> void:
	# Walls (StaticBody2D has no built-in visual)
	draw_rect(Rect2(180, 80, 20, 200), Color.SLATE_GRAY)
	draw_rect(Rect2(380, 180, 20, 180), Color.SLATE_GRAY)
	draw_rect(Rect2(260, 300, 160, 20), Color.SLATE_GRAY)
	# Ray origin
	draw_circle(Vector2(320, 240), 6, Color.WHITE)
	# Hit point marker
	if _is_hitting:
		draw_circle(_hit_point, 7, Color.RED)
