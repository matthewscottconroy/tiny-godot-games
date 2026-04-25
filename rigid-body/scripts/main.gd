extends Node2D

const BodyScript = preload("res://scripts/physics_body.gd")

var count := 0
var colors := [Color.ORANGE, Color.TOMATO, Color.CORNFLOWER_BLUE, Color.SEA_GREEN, Color.GOLD, Color.ORCHID]

@onready var count_label: Label = $CountLabel

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_spawn(event.position)

func _spawn(pos: Vector2) -> void:
	var use_circle := count % 2 == 1

	var body := RigidBody2D.new()
	body.set_script(BodyScript)
	body.is_circle = use_circle
	body.body_color = colors[count % colors.size()]
	body.gravity_scale = 1.5
	body.position = pos

	var col := CollisionShape2D.new()
	if use_circle:
		var s := CircleShape2D.new()
		s.radius = 15.0
		col.shape = s
	else:
		var s := RectangleShape2D.new()
		s.size = Vector2(32, 32)
		col.shape = s
	body.add_child(col)

	add_child(body)
	count += 1
	count_label.text = "Bodies: %d  (click to spawn more)" % count

func _draw() -> void:
	draw_rect(Rect2(0, 458, 640, 22), Color.DIM_GRAY)
	draw_rect(Rect2(0, 0, 10, 460), Color.DIM_GRAY)
	draw_rect(Rect2(630, 0, 10, 460), Color.DIM_GRAY)
