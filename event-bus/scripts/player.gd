extends CharacterBody2D

const SPEED := 160.0
var hp := 100

func _draw() -> void:
	draw_rect(Rect2(-14, -20, 28, 40), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-7, -16, 5, 5), Color.WHITE)
	draw_rect(Rect2(2, -16, 5, 5), Color.WHITE)

func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	# is_action_pressed, not is_action_just_pressed: the "just" variants live on
	# the Input singleton, not on an InputEvent. Calling one here raised an
	# error that aborted the handler, so neither key did anything.
	if event.is_action_pressed("ui_accept"):
		EventBus.player_hurt.emit(10)
		_flash(Color.TOMATO)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SHIFT:
		EventBus.player_healed.emit(10)
		_flash(Color.LIME_GREEN)

func _flash(color: Color) -> void:
	modulate = color
	get_tree().create_timer(0.15).timeout.connect(func(): modulate = Color.WHITE)
