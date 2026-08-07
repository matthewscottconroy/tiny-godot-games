extends Node

var _pass := 0
var _fail := 0

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[sprite-outline] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# --- Helpers (mirrors main.gd logic) ---

func _hit_test(mouse_pos: Vector2, shape_pos: Vector2, radius: float) -> bool:
	return mouse_pos.distance_to(shape_pos) <= radius

func _toggle_select(current_selected: int, hit: int) -> int:
	if hit == current_selected:
		return -1
	else:
		return hit

func _hover_nearest(mouse_pos: Vector2, shapes: Array) -> int:
	var nearest: int = -1
	var nearest_dist: float = INF
	for i in range(shapes.size()):
		var shape = shapes[i]
		var dist: float = mouse_pos.distance_to(shape["pos"])
		if dist <= shape["radius"] and dist < nearest_dist:
			nearest = i
			nearest_dist = dist
	return nearest

# --- Tests ---

func _test_hit_inside() -> void:
	var hit = _hit_test(Vector2(105, 120), Vector2(100, 120), 28.0)
	expect(hit == true, "hit_inside: point inside radius should register hit")

func _test_hit_outside() -> void:
	var hit = _hit_test(Vector2(200, 120), Vector2(100, 120), 28.0)
	expect(hit == false, "hit_outside: point outside radius should miss")

func _test_hit_edge() -> void:
	# Point exactly at radius distance
	var shape_pos = Vector2(100, 120)
	var edge_pos = shape_pos + Vector2(28.0, 0.0)
	var hit = _hit_test(edge_pos, shape_pos, 28.0)
	expect(hit == true, "hit_edge: point exactly at radius should register hit")

func _test_toggle_select() -> void:
	# Clicking the already-selected shape should deselect
	var result_deselect = _toggle_select(2, 2)
	expect(result_deselect == -1, "toggle_select: clicking selected shape deselects (returns -1)")
	# Clicking a different shape should select it (old deselects implicitly)
	var result_new = _toggle_select(2, 4)
	expect(result_new == 4, "toggle_select: clicking different shape selects it")

func _test_hover_nearest() -> void:
	var shapes: Array = [
		{"pos": Vector2(100, 100), "radius": 28.0},
		{"pos": Vector2(300, 200), "radius": 22.0},
	]
	# Near shape 0
	var nearest = _hover_nearest(Vector2(110, 105), shapes)
	expect(nearest == 0, "hover_nearest: closest shape within radius is selected as hovered")
	# Outside all radii
	var none = _hover_nearest(Vector2(500, 400), shapes)
	expect(none == -1, "hover_nearest: no shape in range returns -1")

func _ready() -> void:
	print("=== Sprite Outline Tests ===")
	_test_hit_inside()
	_test_hit_outside()
	_test_hit_edge()
	_test_toggle_select()
	_test_hover_nearest()
	_report()
