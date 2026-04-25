extends Area2D

var dragging    := false
var drag_offset := Vector2.ZERO
var item_color  := Color.CORNFLOWER_BLUE
var start_pos   := Vector2.ZERO

func _ready() -> void:
	start_pos = position
	input_event.connect(_on_input)
	monitoring = true

func _on_input(_viewport: Viewport, event: InputEvent, _shape: int) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		dragging    = true
		drag_offset = position - get_global_mouse_position()
	else:
		dragging = false
		_try_drop()

func _process(_delta: float) -> void:
	if dragging:
		position = get_global_mouse_position() + drag_offset
		queue_redraw()

func _try_drop() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("drop_zones"):
			area.accept_drop(self)
			return
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position", start_pos, 0.35)

func _draw() -> void:
	var col := item_color.lightened(0.3) if dragging else item_color
	draw_rect(Rect2(-24, -24, 48, 48), col)
	if dragging:
		draw_rect(Rect2(-24, -24, 48, 48), Color(1, 1, 1, 0.25))
