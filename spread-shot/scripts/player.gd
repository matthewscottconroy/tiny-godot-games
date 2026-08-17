extends CharacterBody2D

const SPEED        := 200.0
const JUMP_VEL     := -400.0
const GRAVITY      := 900.0
const BULLET_COUNT := 5
const SPREAD_DEG   := 40.0
const FIRE_COOLDOWN := 0.45

const BulletScript := preload("res://scripts/bullet.gd")

var _facing   := 1.0
var _cooldown := 0.0

@onready var _label: Label = $InfoLabel

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var h := Input.get_axis("ui_left", "ui_right")
	if h != 0.0:
		_facing = sign(h)
	velocity.x = h * SPEED
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL

	_cooldown = maxf(_cooldown - delta, 0.0)
	if Input.is_action_just_pressed("ui_select") and _cooldown <= 0.0:
		_fire()
		_cooldown = FIRE_COOLDOWN

	move_and_slide()
	queue_redraw()
	_label.text = "READY" if _cooldown <= 0.0 else "CD %.1fs" % _cooldown

## The fan of directions a single shot produces.
##
## The spread is split evenly across BULLET_COUNT, centred on `facing`. Dividing
## by COUNT - 1 is what puts a bullet at each end of the arc rather than leaving
## the last slot unused; the single-bullet case has to be handled separately
## because that divisor would be zero.
func spread_directions(facing: float) -> Array[Vector2]:
	var half := deg_to_rad(SPREAD_DEG * 0.5)
	var base := Vector2(facing, 0.0)
	var out: Array[Vector2] = []
	for i in BULLET_COUNT:
		var t := float(i) / (BULLET_COUNT - 1) if BULLET_COUNT > 1 else 0.5
		out.append(base.rotated(lerpf(-half, half, t)))
	return out

func _fire() -> void:
	var base := Vector2(_facing, 0.0)
	for dir in spread_directions(_facing):
		var b := Node2D.new()
		b.set_script(BulletScript)
		get_parent().add_child(b)
		b.init(global_position + base * 22.0, dir)

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
