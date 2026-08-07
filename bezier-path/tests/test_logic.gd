extends Node

# Pure GDScript tests — no scene tree dependencies.

var _pass := 0
var _fail := 0
var _results: Array = []

func _ready() -> void:
	_test_bezier_endpoints()
	_test_bezier_midpoint()
	_test_bezier_tangent_at_0()
	_test_bezier_tangent_at_1()
	_test_t_wraps()
	_report()

# --------------- helpers ---------------

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _bezier(t: float, pts: PackedVector2Array) -> Vector2:
	var p0 := pts[0]; var p1 := pts[1]; var p2 := pts[2]; var p3 := pts[3]
	var u := 1.0 - t
	return u*u*u*p0 + 3.0*u*u*t*p1 + 3.0*u*t*t*p2 + t*t*t*p3

func _bezier_tangent(t: float, pts: PackedVector2Array) -> Vector2:
	var p0 := pts[0]; var p1 := pts[1]; var p2 := pts[2]; var p3 := pts[3]
	var u := 1.0 - t
	var tang := 3.0*u*u*(p1-p0) + 6.0*u*t*(p2-p1) + 3.0*t*t*(p3-p2)
	if tang.length() > 0.001:
		return tang.normalized()
	return Vector2(1, 0)

# --------------- tests ---------------

func _test_bezier_endpoints() -> void:
	var pts := PackedVector2Array([
		Vector2(80, 380), Vector2(160, 100), Vector2(480, 100), Vector2(560, 380)
	])
	var at0 := _bezier(0.0, pts)
	var at1 := _bezier(1.0, pts)
	expect(at0.distance_to(pts[0]) < 0.01, "B(0) == P0")
	expect(at1.distance_to(pts[3]) < 0.01, "B(1) == P3")

func _test_bezier_midpoint() -> void:
	# Symmetric control points: midpoint should be at the center X
	var pts := PackedVector2Array([
		Vector2(0, 200), Vector2(0, 0), Vector2(400, 0), Vector2(400, 200)
	])
	var mid := _bezier(0.5, pts)
	# For this symmetric arrangement the midpoint X should be 200
	expect(absf(mid.x - 200.0) < 0.5, "B(0.5) at center X for symmetric points")

func _test_bezier_tangent_at_0() -> void:
	var pts := PackedVector2Array([
		Vector2(80, 380), Vector2(160, 100), Vector2(480, 100), Vector2(560, 380)
	])
	var tang := _bezier_tangent(0.0, pts)
	# Tangent at t=0 should be proportional to (P1 - P0)
	var expected_dir := (pts[1] - pts[0]).normalized()
	expect(tang.dot(expected_dir) > 0.999, "Tangent at t=0 proportional to (P1-P0)")

func _test_bezier_tangent_at_1() -> void:
	var pts := PackedVector2Array([
		Vector2(80, 380), Vector2(160, 100), Vector2(480, 100), Vector2(560, 380)
	])
	var tang := _bezier_tangent(1.0, pts)
	# Tangent at t=1 should be proportional to (P3 - P2)
	var expected_dir := (pts[3] - pts[2]).normalized()
	expect(tang.dot(expected_dir) > 0.999, "Tangent at t=1 proportional to (P3-P2)")

func _test_t_wraps() -> void:
	# Simulating _process: t wraps via fmod after exceeding 1.0
	var t := 0.95
	var speed := 0.4
	var delta := 0.5  # large delta to push past 1.0
	var new_t := fmod(t + speed * delta, 1.0)
	expect(new_t >= 0.0 and new_t < 1.0, "t wraps to [0,1) via fmod")
	# Verify the specific wrap
	expect(absf(new_t - fmod(1.15, 1.0)) < 0.001, "t wraps to correct value")

# --------------- report ---------------

func _report() -> void:
	var summary := "[bezier-path] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
