extends Node2D

const SPEED    := 180.0
const JUMP_VEL := -420.0
const GRAVITY  := 900.0

## Below this horizontal speed the character is standing still, not walking —
## without it, a fraction of a pixel of drift would play the walk cycle.
const WALK_THRESHOLD := 10.0

## Stick and key input never rests at exactly zero; inside this the facing is
## left alone.
const FACING_DEADZONE := 0.1

@onready var player  : Node2D             = $Player
@onready var anim    : AnimatedSprite2D   = $Player/AnimatedSprite2D
@onready var anim_lbl: Label              = $AnimLabel

var velocity := Vector2.ZERO

func _ready() -> void:
	_build_sprite_frames()
	anim.play("idle")

	# Ground collision shape
	var gs := RectangleShape2D.new()
	gs.size = Vector2(640, 20)
	$Ground/Collision.shape = gs

	# Player collision shape
	var ps := CapsuleShape2D.new()
	ps.radius = 8
	ps.height = 20
	$Player/CollisionShape2D.shape = ps

	# Convert player to CharacterBody2D properly requires a diff approach;
	# We'll do manual physics here for simplicity

func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()

	# Each animation is built from programmatically-generated images
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 4.0)
	for i in 4:
		frames.add_frame("idle", _make_frame(i, "idle"), 0)

	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 8.0)
	for i in 6:
		frames.add_frame("walk", _make_frame(i, "walk"), 0)

	frames.add_animation("jump")
	frames.set_animation_loop("jump", false)
	frames.set_animation_speed("jump", 4.0)
	frames.add_frame("jump", _make_frame(0, "jump"), 0)

	frames.add_animation("fall")
	frames.set_animation_loop("fall", false)
	frames.set_animation_speed("fall", 4.0)
	frames.add_frame("fall", _make_frame(0, "fall"), 0)

	anim.sprite_frames = frames

func _make_frame(idx: int, anim_name: String) -> ImageTexture:
	# 16×16 pixel art character frames
	var img := Image.create(16, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var body_col := Color(0.3, 0.5, 0.9)   # blue body
	var eye_col  := Color.WHITE
	var pupil_col := Color(0.1, 0.1, 0.2)

	# Body (6×10 centered)
	for y in range(8, 18):
		for x in range(5, 11):
			img.set_pixel(x, y, body_col)

	# Head (6×6)
	for y in range(2, 8):
		for x in range(5, 11):
			img.set_pixel(x, y, body_col)

	# Eyes
	img.set_pixel(6, 4, eye_col); img.set_pixel(7, 4, eye_col)
	img.set_pixel(9, 4, eye_col); img.set_pixel(10, 4, eye_col)
	img.set_pixel(6, 4, pupil_col)
	img.set_pixel(9, 4, pupil_col)

	# Walk leg animation
	match anim_name:
		"walk":
			# The image is 20px tall (rows 0-19) and the legs sit at row 18, so
			# offsets must stay within ±1 to keep set_pixel() in bounds.
			var leg_offsets := [0, 1, 1, 0, -1, -1]
			var off : int = leg_offsets[idx % leg_offsets.size()]
			img.set_pixel(6, 18 + off, body_col.darkened(0.3))
			img.set_pixel(9, 18 - off, body_col.darkened(0.3))
		"jump":
			# Arms up
			img.set_pixel(4, 9, body_col.darkened(0.2))
			img.set_pixel(11, 9, body_col.darkened(0.2))
		"fall":
			# Arms out
			img.set_pixel(3, 11, body_col.darkened(0.2))
			img.set_pixel(12, 11, body_col.darkened(0.2))
		"idle":
			# Subtle blink on frame 3
			if idx == 3:
				for x in range(6, 8): img.set_pixel(x, 4, body_col)
				for x in range(9, 11): img.set_pixel(x, 4, body_col)

	return ImageTexture.create_from_image(img)

var _on_floor := true

func _physics_process(delta: float) -> void:
	var dir_x := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir_x * SPEED

	if not _on_floor:
		velocity.y += GRAVITY * delta
	if _on_floor and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VEL
		_on_floor = false

	player.position += velocity * delta

	# Floor clamping
	if player.position.y >= 450:
		player.position.y = 450
		velocity.y = 0
		_on_floor = true

	# Screen wrap
	player.position.x = wrapf(player.position.x, -20, 660)

	anim.flip_h = facing_flip(dir_x, anim.flip_h)

	var new_anim := animation_for(_on_floor, velocity)
	if anim.animation != new_anim:
		anim.play(new_anim)

	anim_lbl.text = "Animation: %s   frame: %d" % [anim.animation, anim.frame]

## Which clip belongs to a given state.
##
## Extracted from _physics_process because the state it reads is built there
## from Input, which a headless test cannot press — velocity.x is recomputed
## from the axis on every frame, so "walk" is unreachable from the outside. The
## rule is the part worth holding; what stays behind is the wiring.
func animation_for(on_floor: bool, vel: Vector2) -> String:
	if not on_floor:
		# Up is negative Y, so a negative vertical speed is a rise.
		return "jump" if vel.y < 0.0 else "fall"
	if absf(vel.x) > WALK_THRESHOLD:
		return "walk"
	return "idle"

## Which way the sprite faces. A dead zone around zero, so letting go of the
## key leaves the character facing the way it was going rather than snapping
## back to the default.
func facing_flip(dir_x: float, current: bool) -> bool:
	if dir_x < -FACING_DEADZONE:
		return true
	if dir_x > FACING_DEADZONE:
		return false
	return current

func _draw() -> void:
	draw_rect(Rect2(0, 450, 640, 30), Color(0.3, 0.25, 0.2))
