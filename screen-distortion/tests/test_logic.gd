extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_uv_shift_is_zero_at_zero_strength()
	test_uv_shift_increases_with_strength()
	test_uv_clamped_to_unit_range()
	test_strength_cycle_wraps()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[screen-distortion] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STRENGTHS := [0.0, 0.015, 0.04, 0.08]

func _distort_uv(uv: Vector2, strength: float, wave_freq: float, time: float) -> Vector2:
	var du := uv
	du.x += sin(uv.y * wave_freq * PI + time) * strength
	du.y += cos(uv.x * wave_freq * PI + time * 1.3) * strength * 0.6
	du = du.clamp(Vector2.ZERO, Vector2.ONE)
	return du

func test_uv_shift_is_zero_at_zero_strength() -> void:
	var uv := Vector2(0.5, 0.5)
	var out := _distort_uv(uv, 0.0, 7.0, 1.0)
	expect(out.is_equal_approx(uv), "zero strength produces no UV shift")

func test_uv_shift_increases_with_strength() -> void:
	var uv  := Vector2(0.5, 0.5)
	var out1 := _distort_uv(uv, 0.015, 7.0, 1.5)
	var out2 := _distort_uv(uv, 0.08,  7.0, 1.5)
	expect((out2 - uv).length() >= (out1 - uv).length(),
		"higher strength produces larger UV displacement")

func test_uv_clamped_to_unit_range() -> void:
	for i in 10:
		var uv  := Vector2(randf(), randf())
		var out := _distort_uv(uv, 0.08, 15.0, float(i) * 0.3)
		expect(out.x >= 0.0 and out.x <= 1.0 and out.y >= 0.0 and out.y <= 1.0,
			"distorted UV stays in [0,1] range")

func test_strength_cycle_wraps() -> void:
	var idx := STRENGTHS.size() - 1
	idx = (idx + 1) % STRENGTHS.size()
	expect(idx == 0, "strength index wraps to 0 after last preset")
