extends CharacterBody2D

const SPEED := 160.0
const GRAVITY := 900.0

@onready var visual: Node2D = $Visual
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_setup_animations()
	anim.play("idle")

func _physics_process(delta: float) -> void:
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()
	update_visuals()

## Face the way we are going, and play the animation that matches.
##
## The two thresholds are deliberately above zero and different from each
## other: a body resting against a wall keeps a hair of velocity, and a single
## threshold would leave the sprite flipping and the animation restarting on it.
func update_visuals() -> void:
	if velocity.x < -5:
		visual.scale.x = -1
	elif velocity.x > 5:
		visual.scale.x = 1

	var walking := absf(velocity.x) > 10.0
	if walking and anim.current_animation != "walk":
		anim.play("walk")
	elif not walking and anim.current_animation != "idle":
		anim.play("idle")

func _setup_animations() -> void:
	var lib := AnimationLibrary.new()

	# idle: gentle breathing (scale squish)
	var idle := Animation.new()
	idle.loop_mode = Animation.LOOP_LINEAR
	idle.length = 1.2
	var it := idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(it, "Visual:scale")
	idle.track_insert_key(it, 0.0, Vector2(1.0, 1.0))
	idle.track_insert_key(it, 0.6, Vector2(1.04, 0.96))
	idle.track_insert_key(it, 1.2, Vector2(1.0, 1.0))

	# walk: vertical bob via Visual position offset
	var walk := Animation.new()
	walk.loop_mode = Animation.LOOP_LINEAR
	walk.length = 0.32
	var wt := walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(wt, "Visual:position")
	walk.track_insert_key(wt, 0.00, Vector2(0, 0))
	walk.track_insert_key(wt, 0.08, Vector2(0, -6))
	walk.track_insert_key(wt, 0.16, Vector2(0, 0))
	walk.track_insert_key(wt, 0.24, Vector2(0, -6))
	walk.track_insert_key(wt, 0.32, Vector2(0, 0))

	lib.add_animation("idle", idle)
	lib.add_animation("walk", walk)
	anim.add_animation_library("", lib)
