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
	if try_move(dir):
		var tween := create_tween()
		tween.tween_property(self, "position", main.cell_to_world(grid_pos), 0.1)

## Attempt one step. Returns true if the move happened.
##
## The grid position is the source of truth and updates instantly; the tween
## only animates the sprite catching up. Doing it the other way round — moving
## the sprite and deriving the cell from it — is what makes grid movement drift.
func try_move(dir: Vector2i) -> bool:
	var next := grid_pos + dir
	if main.is_wall(next):
		return false
	grid_pos = next
	return true

func _draw() -> void:
	draw_rect(Rect2(-14, -14, 28, 28), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-6, -10, 4, 4), Color.WHITE)
	draw_rect(Rect2(2, -10, 4, 4), Color.WHITE)
