extends Node2D

## The box the ball bounces in, and the click that puts the ball back.
##
## The four walls are StaticBody2Ds carrying a rectangle collision shape and
## nothing visual. Collision shapes are drawn by the editor, never by a running
## game, so the demo opened onto a ball falling through empty space and rebounding
## off nothing — the one thing it exists to show was invisible.
##
## The rectangles are read back out of the collision shapes rather than repeated
## as ColorRects, so a wall cannot be drawn anywhere the physics is not.

const WALL_COLOR := Color(0.35, 0.37, 0.42)
const BALL_START := Vector2(320.0, 60.0)

@onready var _ball: RigidBody2D = $Ball

## Put the ball back at the top, at rest.
##
## Writing to a RigidBody2D's position fights the physics server, which owns the
## transform — the assignment is applied and then overwritten on the next step.
## PhysicsServer2D.body_set_state is the supported way in, and the velocities
## have to be cleared too or the ball arrives carrying whatever speed it had.
func reset_ball() -> void:
	PhysicsServer2D.body_set_state(
		_ball.get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		Transform2D(0.0, BALL_START))
	PhysicsServer2D.body_set_state(
		_ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(
		_ball.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		reset_ball()

## Every static wall, in world space, taken from the shape the physics uses.
func wall_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for child in get_children():
		var body := child as StaticBody2D
		if body == null:
			continue
		for part in body.get_children():
			var collider := part as CollisionShape2D
			if collider == null:
				continue
			var box := collider.shape as RectangleShape2D
			if box == null:
				continue
			var centre: Vector2 = body.position + collider.position
			rects.append(Rect2(centre - box.size * 0.5, box.size))
	return rects

func _draw() -> void:
	for rect in wall_rects():
		draw_rect(rect, WALL_COLOR)
