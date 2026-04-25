extends CanvasLayer

func _ready() -> void:
	hide()
	$Panel/VBox/ResumeBtn.pressed.connect(_resume)
	$Panel/VBox/QuitBtn.pressed.connect(get_tree().quit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("ui_cancel"):
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
