extends CharacterBody2D

enum State { PATROL, CHASE, RETURN }

const PATROL_SPEED  := 80.0
const CHASE_SPEED   := 150.0
const DETECT_RANGE  := 180.0
const LOSE_RANGE    := 280.0

var state       := State.PATROL
var wp_index    := 0
var waypoints   : Array[Vector2] = []

@onready var state_label : Label           = $StateLabel
@onready var player      : CharacterBody2D = $"../Player"

func _ready() -> void:
	for wp in $"../Waypoints".get_children():
		waypoints.append(wp.global_position)

func _draw() -> void:
	var color := {
		State.PATROL: Color.CORAL,
		State.CHASE:  Color.TOMATO,
		State.RETURN: Color.ORANGE_RED,
	}[state]
	draw_circle(Vector2.ZERO, 18, color)
	var look_at := player.global_position if state == State.CHASE else waypoints[wp_index]
	var dir := (look_at - global_position).normalized()
	draw_circle(dir * 8, 5, Color.WHITE)
	draw_circle(dir * 11, 3, Color.BLACK)

func _physics_process(_delta: float) -> void:
	_transition()
	match state:
		State.PATROL: _patrol()
		State.CHASE:  _chase()
		State.RETURN: _return()
	queue_redraw()

func _transition() -> void:
	var dist := global_position.distance_to(player.global_position)
	match state:
		State.PATROL:
			if dist < DETECT_RANGE:
				state = State.CHASE
		State.CHASE:
			if dist > LOSE_RANGE:
				state = State.RETURN
		State.RETURN:
			if dist < DETECT_RANGE:
				state = State.CHASE
			elif global_position.distance_to(waypoints[wp_index]) < 10:
				state = State.PATROL
	state_label.text = State.keys()[state]

func _patrol() -> void:
	var target := waypoints[wp_index]
	velocity = (target - global_position).normalized() * PATROL_SPEED
	move_and_slide()
	if global_position.distance_to(target) < 10:
		wp_index = (wp_index + 1) % waypoints.size()

func _chase() -> void:
	velocity = (player.global_position - global_position).normalized() * CHASE_SPEED
	move_and_slide()

func _return() -> void:
	velocity = (waypoints[wp_index] - global_position).normalized() * PATROL_SPEED
	move_and_slide()
