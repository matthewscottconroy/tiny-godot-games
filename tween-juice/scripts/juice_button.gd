extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
	pivot_offset = size / 2

func _on_resized() -> void:
	pivot_offset = size / 2

func _on_pressed() -> void:
	_squish()
	_spawn_pop(get_global_rect().get_center())

func _squish() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.25, 0.7), 0.07)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)

func _spawn_pop(at: Vector2) -> void:
	var label := Label.new()
	label.text = "+10"
	label.position = at + Vector2(randf_range(-20, 20), -20)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.GOLD)
	get_parent().add_child(label)

	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 70, 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(label.queue_free)
