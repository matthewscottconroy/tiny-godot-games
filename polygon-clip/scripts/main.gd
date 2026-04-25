extends Node2D

const VERTEX_RADIUS := 10.0
const EDGE_HIT_DIST := 14.0

@onready var poly   : Polygon2D = $Polygon2D
@onready var info   : Label     = $InfoLabel

var _drag_idx := -1

func _ready() -> void:
	$Buttons/ResetBtn.pressed.connect(_reset)
	$Buttons/ConvexBtn.pressed.connect(_convexify)
	_reset()

func _reset() -> void:
	poly.polygon = PackedVector2Array([
		Vector2(200, 150), Vector2(440, 120), Vector2(520, 280),
		Vector2(400, 400), Vector2(220, 380), Vector2(120, 270),
	])
	_drag_idx = -1
	queue_redraw()

func _convexify() -> void:
	poly.polygon = Geometry2D.convex_hull(poly.polygon)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_idx = _find_vertex(event.position)
			else:
				_drag_idx = -1
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_insert_point(event.position)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			_delete_vertex(event.position)
	elif event is InputEventMouseMotion and _drag_idx >= 0:
		var pts := poly.polygon
		pts[_drag_idx] = event.position
		poly.polygon    = pts
		queue_redraw()

func _find_vertex(pos: Vector2) -> int:
	for i in poly.polygon.size():
		if poly.polygon[i].distance_to(pos) <= VERTEX_RADIUS:
			return i
	return -1

func _insert_point(pos: Vector2) -> void:
	var pts  := poly.polygon
	var n    := pts.size()
	var best_i := -1
	var best_d := 1e9
	for i in n:
		var a  := pts[i]
		var b  := pts[(i + 1) % n]
		var d  := Geometry2D.get_closest_point_to_segment(pos, a, b).distance_to(pos)
		if d < best_d:
			best_d = d
			best_i = i
	if best_i >= 0 and best_d < EDGE_HIT_DIST:
		var new_pts := PackedVector2Array()
		for i in n:
			new_pts.append(pts[i])
			if i == best_i:
				new_pts.append(pos)
		poly.polygon = new_pts
		queue_redraw()

func _delete_vertex(pos: Vector2) -> void:
	if poly.polygon.size() <= 3:
		return
	var idx := _find_vertex(pos)
	if idx < 0:
		return
	var pts := poly.polygon
	var new_pts := PackedVector2Array()
	for i in pts.size():
		if i != idx:
			new_pts.append(pts[i])
	poly.polygon = new_pts
	queue_redraw()

func _draw() -> void:
	var pts := poly.polygon
	var n   := pts.size()
	# Edges
	for i in n:
		draw_line(pts[i], pts[(i + 1) % n], Color.CORNFLOWER_BLUE, 2)
	# Vertices
	for i in n:
		var col := Color.GOLD if i == _drag_idx else Color.WHITE
		draw_circle(pts[i], VERTEX_RADIUS, col)
		draw_circle(pts[i], VERTEX_RADIUS, Color(0.1, 0.1, 0.1), false, 2)
	info.text = "Vertices: %d   |   Area: %.0f px²" % [
		n, abs(Geometry2D.polygon_area(pts))]
