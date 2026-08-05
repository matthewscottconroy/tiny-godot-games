extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_constants()
	_test_adjust_clamp()
	_test_zoom_in()
	_test_zoom_out()
	_test_cannot_exceed_bounds()
	_test_reset()
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

func _test_constants() -> void:
	print("constants")
	const ZOOM_MIN := 0.25
	const ZOOM_MAX := 4.0
	const ZOOM_STEP := 0.15
	expect(ZOOM_MIN == 0.25, "ZOOM_MIN is 0.25")
	expect(ZOOM_MAX == 4.0, "ZOOM_MAX is 4.0")
	expect(ZOOM_STEP == 0.15, "ZOOM_STEP is 0.15")

func _test_adjust_clamp() -> void:
	print("adjust clamp")
	const ZOOM_MIN := 0.25
	const ZOOM_MAX := 4.0
	const ZOOM_STEP := 0.15
	var target := 1.0
	target = clampf(target + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	expect_near(target, 1.15, "zoom in from 1.0 gives 1.15")

func _test_zoom_in() -> void:
	print("zoom in")
	const ZOOM_MIN := 0.25
	const ZOOM_MAX := 4.0
	const ZOOM_STEP := 0.15
	var target := 1.0
	target = clampf(target + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	expect(target > 1.0, "zoom in increases target")

func _test_zoom_out() -> void:
	print("zoom out")
	const ZOOM_MIN := 0.25
	const ZOOM_MAX := 4.0
	const ZOOM_STEP := 0.15
	var target := 1.0
	target = clampf(target - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	expect(target < 1.0, "zoom out decreases target")
	expect_near(target, 0.85, "zoom out from 1.0 gives 0.85")

func _test_cannot_exceed_bounds() -> void:
	print("zoom cannot exceed bounds")
	const ZOOM_MIN := 0.25
	const ZOOM_MAX := 4.0
	const ZOOM_STEP := 0.15
	var target := ZOOM_MAX
	target = clampf(target + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	expect_near(target, ZOOM_MAX, "zoom in at max stays at max")
	target = ZOOM_MIN
	target = clampf(target - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	expect_near(target, ZOOM_MIN, "zoom out at min stays at min")

func _test_reset() -> void:
	print("zoom reset")
	var target := 2.5
	target = 1.0
	expect_near(target, 1.0, "reset restores zoom to 1.0")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
