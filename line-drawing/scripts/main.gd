extends Node2D

var _strokes  : Array = []   # Array of {points: PackedVector2Array, color: Color, width: float}
var _current  : Dictionary = {}
var _drawing  := false
var _color    := Color.WHITE
var _width    := 3.0

func _ready() -> void:
	$Buttons/ClearBtn.pressed.connect(_clear)
	$Buttons/ThinBtn.pressed.connect(func():  _width = 1.5)
	$Buttons/MedBtn.pressed.connect(func():   _width = 3.0)
	$Buttons/ThickBtn.pressed.connect(func(): _width = 7.0)
	$Buttons/RedBtn.pressed.connect(func():   _color = Color.TOMATO)
	$Buttons/BlueBtn.pressed.connect(func():  _color = Color.CORNFLOWER_BLUE)
	$Buttons/GreenBtn.pressed.connect(func(): _color = Color.SEA_GREEN)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		_clear()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drawing = true
				_current = {points = PackedVector2Array(), color = _color, width = _width}
				_current.points.append(event.position)
			else:
				if _drawing and _current.points.size() > 1:
					_strokes.append(_current)
				_drawing = false
				_current = {}
				queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if not _strokes.is_empty():
				_strokes.pop_back()
				queue_redraw()
	if event is InputEventMouseMotion and _drawing:
		_current.points.append(event.position)
		queue_redraw()

func _clear() -> void:
	_strokes.clear()
	_drawing = false
	_current = {}
	queue_redraw()

func _draw() -> void:
	# Canvas background
	draw_rect(Rect2(0, 62, 640, 370), Color(0.08, 0.08, 0.1))
	# Committed strokes
	for s in _strokes:
		if s.points.size() > 1:
			for i in s.points.size() - 1:
				draw_line(s.points[i], s.points[i + 1], s.color, s.width, true)
	# Active stroke
	if _drawing and _current.has("points") and _current.points.size() > 1:
		var pts : PackedVector2Array = _current.points
		for i in pts.size() - 1:
			draw_line(pts[i], pts[i + 1], _current.color, _current.width, true)
