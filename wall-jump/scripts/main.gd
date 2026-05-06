extends Node2D

func _draw() -> void:
	# Floor
	draw_rect(Rect2(0, 442, 640, 25), Color(0.25, 0.25, 0.25))

	# Left wall
	draw_rect(Rect2(0, 142, 20, 300), Color(0.2, 0.2, 0.22))

	# Right wall
	draw_rect(Rect2(620, 142, 20, 300), Color(0.2, 0.2, 0.22))

	# Title hint drawn in _draw so it layers under the Label nodes (which are children)
	# (Title text is handled by TitleLabel node instead)
