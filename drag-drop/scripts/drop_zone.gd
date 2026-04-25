extends Area2D

var has_item := false

func _ready() -> void:
	add_to_group("drop_zones")
	monitoring = true

func accept_drop(item: Node2D) -> void:
	item.position  = position
	item.start_pos = position
	has_item = true
	queue_redraw()
	get_parent().on_drop()

func _draw() -> void:
	var border := Color.LIME_GREEN if has_item else Color(0.7, 0.7, 0.7, 0.5)
	draw_rect(Rect2(-36, -36, 72, 72), Color(0.3, 0.3, 0.3, 0.3))
	draw_rect(Rect2(-36, -36, 72, 72), border, false, 3)
