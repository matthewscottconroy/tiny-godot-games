extends CharacterBody2D

const SPEED        := 200.0
const JUMP_VEL     := -400.0
const GRAVITY      := 900.0
const BULLET_COUNT := 5
const SPREAD_DEG   := 40.0
const FIRE_COOLDOWN := 0.45

## How far in front of the player the fan starts — clear of the 24px body.
const MUZZLE_OFFSET := 22.0

const BulletScript := preload("res://scripts/bullet.gd")

var _facing   := 1.0
var _cooldown := 0.0

@onready var _label: Label = $InfoLabel

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var h := Input.get_axis("ui_left", "ui_right")
	_facing = facing_for(h, _facing)
	velocity.x = h * SPEED
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL

	tick_cooldown(delta)
	if Input.is_action_just_pressed("ui_select") and can_fire():
		_fire()
		_cooldown = FIRE_COOLDOWN

	move_and_slide()
	queue_redraw()
	if _label:
		_label.text = status_text()

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

## The way to face, given this frame's input. A released key reads as zero, and
## writing sign(0) into the facing would leave the next shot with no side to
## come out of.
static func facing_for(h: float, current: float) -> float:
	return sign(h) if h != 0.0 else current

## Where the fan starts: clear of the body, on the side the player is facing.
func muzzle() -> Vector2:
	return global_position + Vector2(_facing, 0.0) * MUZZLE_OFFSET

## Age the cooldown, clamped so it never goes negative — an unclamped timer
## would keep counting down and leave the gun permanently ready.
func tick_cooldown(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)

func can_fire() -> bool:
	return _cooldown <= 0.0

## What the readout says: ready, or how long until it is.
func status_text() -> String:
	return "READY" if can_fire() else "CD %.1fs" % _cooldown

func _fire() -> void:
	var from := muzzle()
	for dir in spread_directions(_facing):
		var b := Node2D.new()
		b.set_script(BulletScript)
		get_parent().add_child(b)
		b.init(from, dir)

func _draw() -> void:
	draw_rect(Rect2(-12, -24, 24, 48), Color.DODGER_BLUE)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
