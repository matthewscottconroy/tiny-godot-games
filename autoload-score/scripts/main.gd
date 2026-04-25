extends Control

func _ready() -> void:
	# ScoreManager is available everywhere as an autoload singleton.
	# Connecting its signal here keeps the UI decoupled from game logic.
	ScoreManager.score_changed.connect(_on_score_changed)
	_on_score_changed(ScoreManager.score)
	$AddButton.pressed.connect(_on_add_pressed)
	$ResetButton.pressed.connect(_on_reset_pressed)

func _on_score_changed(new_score: int) -> void:
	$ScoreLabel.text = "Score: %d" % new_score

func _on_add_pressed() -> void:
	ScoreManager.add(10)

func _on_reset_pressed() -> void:
	ScoreManager.reset()
