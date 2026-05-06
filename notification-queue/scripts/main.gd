extends Node2D

@onready var _notif: CanvasLayer = $NotifManager

func _process(_delta: float) -> void:
	if Input.is_key_just_pressed(KEY_1):
		_notif.push("Achievement: First Steps!")
	elif Input.is_key_just_pressed(KEY_2):
		_notif.push("Level Up! You are now level 5")
	elif Input.is_key_just_pressed(KEY_3):
		_notif.push("New item found: Iron Sword")
	elif Input.is_key_just_pressed(KEY_4):
		_notif.push("Quest completed: The Lost Mine")

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.10, 0.12, 0.16))

	# Decorative panels to make the scene look purposeful
	draw_rect(Rect2(20, 60, 280, 360), Color(0.18, 0.18, 0.24))
	draw_rect(Rect2(20, 60, 280, 360), Color(0.4, 0.4, 0.5, 0.5), false, 1.0)

	draw_rect(Rect2(340, 60, 280, 360), Color(0.18, 0.18, 0.24))
	draw_rect(Rect2(340, 60, 280, 360), Color(0.4, 0.4, 0.5, 0.5), false, 1.0)

	# Simulated content lines
	for i in 8:
		var y := 90.0 + float(i) * 38.0
		draw_rect(Rect2(36, y, 240.0 - float(i % 3) * 30.0, 8), Color(0.3, 0.3, 0.38))
		draw_rect(Rect2(356, y, 240.0 - float((i+1) % 3) * 25.0, 8), Color(0.3, 0.3, 0.38))

	# Key hint boxes
	var key_colors := [Color(0.8, 0.3, 0.3), Color(0.3, 0.7, 0.3), Color(0.3, 0.5, 0.9), Color(0.8, 0.6, 0.2)]
	var key_labels := ["1", "2", "3", "4"]
	for i in 4:
		var x := 120.0 + float(i) * 100.0
		draw_rect(Rect2(x - 14, 430, 28, 28), key_colors[i].darkened(0.4))
		draw_rect(Rect2(x - 14, 430, 28, 28), key_colors[i], false, 2.0)
