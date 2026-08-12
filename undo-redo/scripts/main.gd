extends Node2D

var _strokes: Array = []          # Array of PackedVector2Array
var _current_stroke: PackedVector2Array = PackedVector2Array()
var _drawing := false
var _undo_redo := UndoRedo.new()

@onready var _history_label: Label = $HUD/HistoryLabel

func _ready() -> void:
	_update_history()
	$HUD/ClearButton.pressed.connect(_clear_all)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drawing = true
			_current_stroke = PackedVector2Array()
			_current_stroke.append(event.position)
		else:
			if _drawing and _current_stroke.size() > 1:
				_commit_stroke()
			_drawing = false
			queue_redraw()
	elif event is InputEventMouseMotion and _drawing:
		_current_stroke.append(event.position)
		queue_redraw()

# Shortcuts are edge-triggered, so they belong in an event handler rather than a
# per-frame poll. `ctrl_pressed` / `shift_pressed` read the modifier state that
# came with the event itself.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo or not key.ctrl_pressed:
		return
	if key.keycode == KEY_Z and key.shift_pressed:
		_undo_redo.redo()
	elif key.keycode == KEY_Z:
		_undo_redo.undo()
	elif key.keycode == KEY_Y:
		_undo_redo.redo()
	else:
		return
	queue_redraw()
	_update_history()

func _commit_stroke() -> void:
	var stroke := _current_stroke.duplicate()
	_undo_redo.create_action("Draw Stroke")
	# Godot 4 takes a Callable, not (object, method_name, args...). Arguments are
	# bound onto the Callable itself with .bind().
	_undo_redo.add_do_method(_add_stroke.bind(stroke))
	_undo_redo.add_undo_method(_remove_last_stroke)
	_undo_redo.commit_action()
	_update_history()

func _add_stroke(stroke: PackedVector2Array) -> void:
	_strokes.append(stroke)
	queue_redraw()

func _remove_last_stroke() -> void:
	if _strokes.size() > 0:
		_strokes.pop_back()
	queue_redraw()

func _clear_all() -> void:
	_strokes.clear()
	_undo_redo.clear_history()
	queue_redraw()
	_update_history()

func _update_history() -> void:
	_history_label.text = "Strokes: %d  |  Undo: Ctrl+Z   Redo: Ctrl+Y" % _strokes.size()

func _draw() -> void:
	# White canvas background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.95, 0.95, 0.95))

	# Committed strokes
	for stroke in _strokes:
		for i in range(stroke.size() - 1):
			draw_line(stroke[i], stroke[i + 1], Color(0.1, 0.1, 0.8), 3.0, true)

	# In-progress stroke (lighter color)
	for i in range(_current_stroke.size() - 1):
		draw_line(_current_stroke[i], _current_stroke[i + 1], Color(0.5, 0.5, 0.9), 3.0, true)
