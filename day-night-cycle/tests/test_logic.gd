extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_noon_is_bright()
	test_midnight_is_dark()
	test_time_wraps_at_1()
	test_time_name_noon()
	test_time_name_midnight()
	test_keyframe_interpolation_midpoint()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[day-night-cycle] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const KEYFRAMES: Array = [
	[0.00, Color(0.05, 0.05, 0.20), Color(0.12, 0.14, 0.30)],
	[0.20, Color(0.20, 0.15, 0.30), Color(0.35, 0.28, 0.55)],
	[0.25, Color(0.70, 0.40, 0.20), Color(0.80, 0.65, 0.50)],
	[0.35, Color(0.50, 0.70, 1.00), Color(1.00, 0.95, 0.85)],
	[0.50, Color(0.45, 0.68, 1.00), Color(1.00, 1.00, 1.00)],
	[0.65, Color(0.45, 0.65, 0.95), Color(1.00, 0.98, 0.90)],
	[0.75, Color(0.80, 0.45, 0.10), Color(0.90, 0.70, 0.50)],
	[0.85, Color(0.20, 0.10, 0.25), Color(0.40, 0.30, 0.55)],
	[1.00, Color(0.05, 0.05, 0.20), Color(0.12, 0.14, 0.30)],
]

func _lerp_kf(t: float, col_idx: int) -> Color:
	for i in KEYFRAMES.size() - 1:
		var t0: float = KEYFRAMES[i][0]
		var t1: float = KEYFRAMES[i + 1][0]
		if t >= t0 and t <= t1:
			var local := (t - t0) / (t1 - t0)
			return (KEYFRAMES[i][col_idx + 1] as Color).lerp(KEYFRAMES[i + 1][col_idx + 1], local)
	return KEYFRAMES[0][col_idx + 1]

func _time_name(t: float) -> String:
	var h := int(t * 24)
	var m := int(fmod(t * 24, 1.0) * 60)
	var period := "noon" if h == 12 else ("midnight" if h == 0 or h == 24 else ("PM" if h > 12 else "AM"))
	var dh := h if h <= 12 else h - 12
	if dh == 0: dh = 12
	return "%02d:%02d %s" % [dh, m, period]

func test_noon_is_bright() -> void:
	var c := _lerp_kf(0.5, 1)  # modulate color at noon
	expect(c.get_luminance() > 0.9, "noon modulate color is near white (bright)")

func test_midnight_is_dark() -> void:
	var c := _lerp_kf(0.0, 1)
	expect(c.get_luminance() < 0.3, "midnight modulate color is dark")

func test_time_wraps_at_1() -> void:
	var t := fmod(0.999 + 0.01, 1.0)
	expect(t < 0.02, "time wraps from 1.0 back to near 0.0")

func test_time_name_noon() -> void:
	expect(_time_name(0.5) == "12:00 noon", "0.5 normalized = 12:00 noon")

func test_time_name_midnight() -> void:
	var name := _time_name(0.0)
	expect(name.contains("midnight"), "0.0 normalized contains 'midnight'")

func test_keyframe_interpolation_midpoint() -> void:
	# At t=0.125 (midway between 0.0 and 0.25 keyframes), modulate should be between midnight and dawn
	var c := _lerp_kf(0.125, 1)
	var dark  := _lerp_kf(0.0, 1).get_luminance()
	var light := _lerp_kf(0.25, 1).get_luminance()
	expect(c.get_luminance() > dark and c.get_luminance() < light,
		"midpoint between midnight and dawn has luminance between the two")
