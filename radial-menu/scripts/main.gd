extends Node2D

@onready var _menu:   Control = $RadialMenu
@onready var _result: Label   = $ResultLabel

func _ready() -> void:
	_menu.item_selected.connect(func(i: int, l: String) -> void:
		_result.text = "Selected: %s (index %d)" % [l, i]
	)

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.10, 0.11, 0.16))

	# Decorative character silhouette area
	draw_rect(Rect2(260, 200, 120, 160), Color(0.18, 0.18, 0.24))
	draw_rect(Rect2(260, 200, 120, 160), Color(0.35, 0.35, 0.45), false, 1.5)

	# "Floor"
	draw_rect(Rect2(0, 360, 640, 120), Color(0.15, 0.15, 0.20))
	draw_rect(Rect2(0, 360, 640, 2),   Color(0.35, 0.35, 0.5))
