class_name FloatingText
extends Label

static func spawn(parent: Node, pos: Vector2, msg: String, col: Color = Color.WHITE) -> void:
	var ft := FloatingText.new()
	ft.text = msg
	ft.add_theme_font_size_override("font_size", 22)
	ft.modulate = col
	ft.position = pos
	ft.z_index = 10
	parent.add_child(ft)

	var tw := ft.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ft, "position:y", pos.y - 72.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(ft, "modulate:a", 0.0, 0.9).set_delay(0.25)
	tw.chain().tween_callback(ft.queue_free)
