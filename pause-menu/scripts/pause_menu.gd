extends CanvasLayer

func _ready() -> void:
	hide()
	$Panel/VBox/ResumeBtn.pressed.connect(_resume)
	$Panel/VBox/QuitBtn.pressed.connect(get_tree().quit)

func _unhandled_input(event: InputEvent) -> void:
	# is_action_pressed, not is_action_just_pressed: the "just" variants are on
	# the Input singleton. An InputEvent has no such method, and calling it
	# raised an error that aborted this handler — so Esc did nothing at all.
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume()
		else:
			_pause()

func _pause() -> void:
	get_tree().paused = true
	show()

func _resume() -> void:
	get_tree().paused = false
	hide()
