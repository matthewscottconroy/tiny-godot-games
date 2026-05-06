extends Node

const DEFAULTS := {
	"master_volume": 80,
	"sfx_volume":    60,
	"fullscreen":    false,
	"player_speed":  150,
	"show_fps":      true,
}

var _pass_count := 0
var _fail_count := 0


func _ready() -> void:
	_test_default_volume()
	_test_clamp_volume()
	_test_toggle()
	_test_slider_value()
	_test_speed_range()
	_report()


func expect(condition: bool, label: String) -> void:
	if condition:
		_pass_count += 1
		print("[PASS] ", label)
	else:
		_fail_count += 1
		print("[FAIL] ", label)


func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass_count, _fail_count])


func _clamp_volume(val: int) -> int:
	return clampi(val, 0, 100)


func _clamp_speed(val: int) -> int:
	return clampi(val, 50, 300)


func _slider_value_from_frac(frac: float, min_val: int, max_val: int) -> int:
	return int(round(min_val + clampf(frac, 0.0, 1.0) * (max_val - min_val)))


func _test_default_volume() -> void:
	# Simulate loading without a file — defaults apply
	var settings := DEFAULTS.duplicate()
	expect(int(settings["master_volume"]) == 80, "Default volume: master_volume=80")
	expect(int(settings["sfx_volume"]) == 60,    "Default volume: sfx_volume=60")


func _test_clamp_volume() -> void:
	expect(_clamp_volume(150) == 100, "Clamp volume: 150 clamped to 100")
	expect(_clamp_volume(-10) == 0,   "Clamp volume: -10 clamped to 0")
	expect(_clamp_volume(75)  == 75,  "Clamp volume: 75 unchanged")


func _test_toggle() -> void:
	var fullscreen := false
	fullscreen = not fullscreen
	expect(fullscreen == true, "Toggle: false -> true after toggle")
	fullscreen = not fullscreen
	expect(fullscreen == false, "Toggle: true -> false after second toggle")


func _test_slider_value() -> void:
	# Slider width = 200, click at x_offset=100 → 50% → value=50 (for 0-100 range)
	var slider_width := 200.0
	var click_offset := 100.0
	var frac := click_offset / slider_width
	var val := _slider_value_from_frac(frac, 0, 100)
	expect(val == 50, "Slider value: 50%% of 200px wide slider = value 50")

	# Click at far right
	frac = 200.0 / slider_width
	val = _slider_value_from_frac(frac, 0, 100)
	expect(val == 100, "Slider value: 100%% of slider = 100")

	# Click at far left
	frac = 0.0 / slider_width
	val = _slider_value_from_frac(frac, 0, 100)
	expect(val == 0, "Slider value: 0%% of slider = 0")


func _test_speed_range() -> void:
	expect(_clamp_speed(50)  == 50,  "Speed range: min=50")
	expect(_clamp_speed(300) == 300, "Speed range: max=300")
	expect(_clamp_speed(150) == 150, "Speed range: default=150 in range")
	expect(_clamp_speed(10)  == 50,  "Speed range: 10 clamped to min 50")
	expect(_clamp_speed(999) == 300, "Speed range: 999 clamped to max 300")
