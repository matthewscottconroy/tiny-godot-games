extends Node2D

var grid_pos := Vector2i(2, 6)

@onready var main : Node2D = get_parent()

func _ready() -> void:
	position = main.cell_to_world(grid_pos)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var dir := Vector2i.ZERO
	if event.is_action("ui_up"):    dir = Vector2i(0, -1)
	elif event.is_action("ui_down"):  dir = Vector2i(0,  1)
	elif event.is_action("ui_left"):  dir = Vector2i(-1, 0)
	elif event.is_action("ui_right"): dir = Vector2i( 1, 0)
	if dir == Vector2i.ZERO:
		return
	var next := grid_pos + dir
	if not main.is_wall(next):
		grid_pos = next
		var tween := create_tween()
		tween.tween_property(self, "position", main.cell_to_world(grid_pos), 0.1)

func _draw() -> void:
	draw_rect(Rect2(-14, -14, 28, 28), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-6, -10, 4, 4), Color.WHITE)
	draw_rect(Rect2(2, -10, 4, 4), Color.WHITE)
