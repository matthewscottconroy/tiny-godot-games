extends CharacterBody2D

const SPEED := 160.0
const FIRE_COOLDOWN := 0.35

## How far in front of the player a bullet spawns — clear of the 24px-wide body.
const MUZZLE_OFFSET := 22.0

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
	update_facing(dir)
	velocity = dir * SPEED
	move_and_slide()

	tick_cooldown(delta)
	if cooldown_bar:
		cooldown_bar.value = cooldown_ratio()
	if ready_label:
		ready_label.visible = can_fire()

	if Input.is_action_just_pressed("ui_accept") and can_fire():
		_shoot()
	queue_redraw()

## Remember the last real heading, so the player keeps aiming where it moved
## instead of snapping back when the stick is released. The threshold stops
## analogue drift from rewriting the aim.
func update_facing(dir: Vector2) -> void:
	if dir.length() > 0.1:
		facing = dir.normalized()

## Age the cooldown, clamped so it never goes negative — an unclamped timer
## would keep counting down and make can_fire() true forever after one shot.
func tick_cooldown(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)

func can_fire() -> bool:
	return cooldown == 0.0

## 0 while the shot is on cooldown, rising to 1 when it is ready — the shape a
## progress bar wants.
func cooldown_ratio() -> float:
	return 1.0 - (cooldown / FIRE_COOLDOWN)

## Start the cooldown. Separated from spawning the bullet so the timing rule can
## be tested without a scene.
func begin_cooldown() -> void:
	cooldown = FIRE_COOLDOWN

## Where a bullet is born: clear of the body, along the aim. Inside the player
## it would be drawn over the shooter and, in a demo with hit detection, would
## be overlapping it on the frame it spawns.
func muzzle() -> Vector2:
	return global_position + facing * MUZZLE_OFFSET

func _shoot() -> void:
	begin_cooldown()
	var b := bullet_scene.instantiate()
	b.global_position = muzzle()
	b.direction = facing
	get_parent().add_child(b)
