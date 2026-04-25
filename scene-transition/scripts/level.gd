extends Control

func _ready() -> void:
	$VBox/BackBtn.pressed.connect(func():
		Transition.fade_to("res://scenes/title.tscn"))
