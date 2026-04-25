extends CharacterBody2D

const SPEED := 160.0
const FIRE_COOLDOWN := 0.35

@export var bullet_scene: PackedScene

var cooldown := 0.0
var facing := Vector2.RIGHT

@onready var cooldown_bar: ProgressBar = $CooldownBar
@onready var ready_label: Label = $ReadyLabel

func _draw() -> void:
	draw_rect(Rect2(-14, -20, 28, 40), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-7, -16, 5, 5), Color.WHITE)
	draw_rect(Rect2(2, -16, 5, 5), Color.WHITE)
	# Gun barrel
	var barrel_dir := facing * 20
	draw_line(Vector2.ZERO, barrel_dir, Color.LIGHT_GRAY, 4)

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir.length() > 0.1:
		facing = dir.normalized()
	velocity = dir * SPEED
	move_and_slide()

	cooldown = max(0.0, cooldown - delta)
	cooldown_bar.value = 1.0 - (cooldown / FIRE_COOLDOWN)
	ready_label.visible = cooldown == 0.0

	if Input.is_action_just_pressed("ui_accept") and cooldown == 0.0:
		_shoot()
	queue_redraw()

func _shoot() -> void:
	cooldown = FIRE_COOLDOWN
	var b := bullet_scene.instantiate()
	b.global_position = global_position + facing * 22
	b.direction = facing
	get_parent().add_child(b)
