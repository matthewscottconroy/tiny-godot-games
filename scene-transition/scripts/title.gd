extends Control

func _ready() -> void:
	$VBox/StartBtn.pressed.connect(func():
		Transition.fade_to("res://scenes/level.tscn"))
