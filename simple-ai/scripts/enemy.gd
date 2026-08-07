extends CharacterBody2D

@export var speed := 70.0

@onready var player: CharacterBody2D = $"../Player"

func _draw() -> void:
	draw_circle(Vector2.ZERO, 18, Color.TOMATO)
	# Simple "eye" to show facing direction
	var eye_offset := (player.global_position - global_position).normalized() * 8
	draw_circle(eye_offset, 5, Color.WHITE)
	draw_circle(eye_offset + (player.global_position - global_position).normalized() * 2, 3, Color.BLACK)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	queue_redraw()
