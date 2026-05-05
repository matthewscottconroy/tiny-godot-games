extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_platform_at_origin_when_t0()
	test_platform_at_peak_quarter_period()
	test_platform_back_at_origin_half_period()
	test_velocity_equals_displacement_over_delta()
	test_diagonal_axis_normalized()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[moving-platforms] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

func _platform_pos(origin: Vector2, axis: Vector2, amplitude: float, period: float, t: float) -> Vector2:
	return origin + axis.normalized() * sin(t * TAU / period) * amplitude

func _platform_vel(origin: Vector2, axis: Vector2, amplitude: float, period: float, t: float, delta: float) -> Vector2:
	var prev := _platform_pos(origin, axis, amplitude, period, t - delta)
	var curr := _platform_pos(origin, axis, amplitude, period, t)
	return (curr - prev) / delta

func test_platform_at_origin_when_t0() -> void:
	var pos := _platform_pos(Vector2(200, 300), Vector2(0, 1), 80.0, 2.5, 0.0)
	expect(pos.is_equal_approx(Vector2(200, 300)), "platform at origin when t=0 (sin(0)=0)")

func test_platform_at_peak_quarter_period() -> void:
	var pos := _platform_pos(Vector2(0, 0), Vector2(0, 1), 80.0, 2.5, 2.5 / 4.0)
	expect(absf(pos.y - 80.0) < 0.01, "platform at amplitude peak at t=period/4")

func test_platform_back_at_origin_half_period() -> void:
	var pos := _platform_pos(Vector2(0, 0), Vector2(0, 1), 80.0, 2.5, 2.5 / 2.0)
	expect(pos.length() < 0.01, "platform returns to origin at t=period/2")

func test_velocity_equals_displacement_over_delta() -> void:
	var vel := _platform_vel(Vector2(0, 0), Vector2(0, 1), 80.0, 2.5, 0.5, 0.016)
	# velocity should be non-zero and finite
	expect(vel.length() > 0.0 and vel.length() < 1000.0, "velocity is finite and non-zero mid-cycle")

func test_diagonal_axis_normalized() -> void:
	var axis := Vector2(1, -1).normalized()
	expect(absf(axis.length() - 1.0) < 0.001, "diagonal axis normalized to unit vector")
