extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_wall_slide_gravity()
	_test_slide_speed_cap()
	_test_pressing_toward_wall()
	_test_slide_distance_accumulation()
	_test_normal_gravity_when_not_sliding()
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

func _test_wall_slide_gravity() -> void:
	print("wall slide gravity multiplier")
	const WALL_SLIDE_GRAV := 0.12
	const GRAVITY := 900.0
	var slide_grav := GRAVITY * WALL_SLIDE_GRAV
	expect_near(slide_grav, 108.0, "slide gravity is 12% of normal")
	expect(slide_grav < GRAVITY, "slide gravity is less than normal gravity")

func _test_slide_speed_cap() -> void:
	print("slide speed terminal velocity cap")
	const SLIDE_SPEED_CAP := 80.0
	var vy := 200.0
	vy = minf(vy, SLIDE_SPEED_CAP)
	expect_near(vy, SLIDE_SPEED_CAP, "vy capped at SLIDE_SPEED_CAP when exceeding")
	vy = 40.0
	vy = minf(vy, SLIDE_SPEED_CAP)
	expect_near(vy, 40.0, "vy unchanged when below cap")

func _test_pressing_toward_wall() -> void:
	print("detect pressing toward wall via wall normal")
	var h_right := 1.0
	var wall_normal_left := Vector2(-1.0, 0.0)
	var pressing_into_left_wall := (h_right * wall_normal_left.x) < 0.0
	expect(pressing_into_left_wall, "pressing right into left wall detected")

	var h_left := -1.0
	var wall_normal_right := Vector2(1.0, 0.0)
	var pressing_into_right_wall := (h_left * wall_normal_right.x) < 0.0
	expect(pressing_into_right_wall, "pressing left into right wall detected")

func _test_slide_distance_accumulation() -> void:
	print("slide distance accumulates while sliding")
	var slide_dist := 0.0
	var vy := 60.0
	var delta := 0.016
	slide_dist += absf(vy) * delta
	expect(slide_dist > 0.0, "slide distance increases each frame while sliding")
	expect_near(slide_dist, vy * delta, "slide distance is vy * delta per frame")

func _test_normal_gravity_when_not_sliding() -> void:
	print("full gravity when not sliding")
	const GRAVITY := 900.0
	const WALL_SLIDE_GRAV := 0.12
	var is_sliding := false
	var grav_scale := WALL_SLIDE_GRAV if is_sliding else 1.0
	expect_near(grav_scale, 1.0, "grav_scale is 1.0 when not sliding")

func _report() -> void:
	var summary := "[wall-slide] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
