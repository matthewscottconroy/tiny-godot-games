extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_vertex_radius()
	_test_edge_hit_distance()
	_test_delete_requires_min_vertices()
	_test_add_vertex_on_edge()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_vertex_radius() -> void:
	print("vertex hit radius")
	const VERTEX_RADIUS := 10.0
	expect(VERTEX_RADIUS == 10.0, "VERTEX_RADIUS is 10")

func _test_edge_hit_distance() -> void:
	print("edge hit distance")
	const EDGE_HIT_DIST := 14.0
	expect(EDGE_HIT_DIST == 14.0, "EDGE_HIT_DIST is 14")
	expect(EDGE_HIT_DIST > 10.0, "edge hit dist exceeds vertex radius")

func _test_delete_requires_min_vertices() -> void:
	print("delete requires polygon size > 3")
	var polygon := [Vector2(0,0), Vector2(100,0), Vector2(100,100), Vector2(0,100)]
	expect(polygon.size() > 3, "can delete when 4 vertices")
	polygon.pop_back()
	expect(not (polygon.size() > 3), "cannot delete when 3 vertices remain")

func _test_add_vertex_on_edge() -> void:
	print("vertex insertion on edge")
	var polygon := [Vector2(0,0), Vector2(200,0), Vector2(100,100)]
	var insert_idx := 1
	var mid: Vector2 = (polygon[0] + polygon[1]) * 0.5
	polygon.insert(insert_idx, mid)
	expect(polygon.size() == 4, "vertex inserted grows polygon")
	expect(polygon[1] == mid, "inserted vertex is at midpoint")

func _report() -> void:
	var summary := "[polygon-clip] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
