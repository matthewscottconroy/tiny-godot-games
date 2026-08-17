extends Node2D

@onready var ray: RayCast2D = $RayCast2D
@onready var line: Line2D = $Line2D

const RAY_LENGTH := 700.0

var _hit_point := Vector2.ZERO
var _is_hitting := false

func _process(_delta: float) -> void:
	aim_at(to_local(get_global_mouse_position()))
	queue_redraw()

## Point the ray at a spot, in this node's own coordinates, and cast it.
##
## force_raycast_update() is what makes this usable outside the physics step:
## a RayCast2D otherwise only refreshes once per physics frame, so the result
## would lag a frame behind the cursor.
func aim_at(target_local: Vector2) -> void:
	# Measured from the ray's own position, not from this node's origin: the
	# ray sits in the middle of the room, so normalising the raw target aimed
	# it as if the cursor were an offset from the top-left corner.
	var origin := ray.position
	var direction := (target_local - origin).normalized()
	ray.target_position = direction * RAY_LENGTH
	ray.force_raycast_update()

	if ray.is_colliding():
		_hit_point = to_local(ray.get_collision_point())
		_is_hitting = true
		line.set_point_position(1, _hit_point)
	else:
		_is_hitting = false
		line.set_point_position(1, origin + direction * RAY_LENGTH)

func is_hitting() -> bool:
	return _is_hitting

func hit_point() -> Vector2:
	return _hit_point

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
