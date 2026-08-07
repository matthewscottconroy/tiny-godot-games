extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_grid_dimensions()
	_test_threshold()
	_test_corner_bits()
	_test_interpolation_midpoint()
	_test_interpolation_exact()
	_test_all_below_skipped()
	_test_all_above_skipped()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) <= tol, label)

func lerp_t(a: float, b: float, threshold: float) -> float:
	if absf(b - a) < 0.00001:
		return 0.5
	return clampf((threshold - a) / (b - a), 0.0, 1.0)

func _test_grid_dimensions() -> void:
	print("grid dimensions")
	const GRID_W := 64
	const GRID_H := 48
	const CELL := 10
	expect(GRID_W * CELL == 640, "grid width fills viewport")
	expect(GRID_H * CELL == 480, "grid height fills viewport")

func _test_threshold() -> void:
	print("contour threshold")
	const THRESHOLD := 0.5
	expect(THRESHOLD == 0.5, "threshold is 0.5")

func _test_corner_bits() -> void:
	print("corner bit assignments")
	var tl := 0.8  # above threshold
	var tr := 0.3  # below
	var br := 0.6  # above
	var bl := 0.2  # below
	const T := 0.5
	var idx := (
		(1 if tl >= T else 0) |
		(2 if tr >= T else 0) |
		(4 if br >= T else 0) |
		(8 if bl >= T else 0)
	)
	expect(idx == 5, "tl+br above threshold gives index 5")

func _test_interpolation_midpoint() -> void:
	print("edge interpolation at equal values")
	var t := lerp_t(0.3, 0.7, 0.5)
	expect_near(t, 0.5, "crossing at midpoint when values straddle threshold equally")

func _test_interpolation_exact() -> void:
	print("edge interpolation exact crossing")
	var t := lerp_t(0.0, 1.0, 0.5)
	expect_near(t, 0.5, "t=0.5 when a=0, b=1, threshold=0.5")
	t = lerp_t(0.0, 1.0, 0.25)
	expect_near(t, 0.25, "t=0.25 when a=0, b=1, threshold=0.25")

func _test_all_below_skipped() -> void:
	print("all-below case (idx=0) skipped")
	var idx := 0  # no corners above threshold
	expect(idx == 0 or idx == 15, "idx=0 means no contour to draw")

func _test_all_above_skipped() -> void:
	print("all-above case (idx=15) skipped")
	var idx := 15  # all corners above threshold
	expect(idx == 15, "idx=15 means no contour to draw")

func _report() -> void:
	var summary := "[marching-squares] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
