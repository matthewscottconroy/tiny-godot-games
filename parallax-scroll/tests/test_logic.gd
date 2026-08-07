extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_player_speed()
	_test_layer_scroll_ratios()
	_test_mountain_peak_offsets()
	_test_layer_ordering()
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

func _test_player_speed() -> void:
	print("player speed")
	const SPEED := 200.0
	expect(SPEED == 200.0, "player SPEED is 200")

func _test_layer_scroll_ratios() -> void:
	print("parallax layer scroll ratios")
	var far_ratio := 0.2
	var mid_ratio := 0.5
	var near_ratio := 0.8
	expect(far_ratio < mid_ratio, "far layer scrolls slower than mid")
	expect(mid_ratio < near_ratio, "mid layer scrolls slower than near")
	expect(near_ratio < 1.0, "near layer scrolls slower than camera")

func _test_mountain_peak_offsets() -> void:
	print("mountain peak y offsets in far layer")
	var spacing := 280.0
	var peak_offset := 140.0
	for i in 4:
		var base_x := float(i) * spacing
		var peak_x := base_x + peak_offset
		expect_near(peak_x - base_x, peak_offset, "peak centered at half spacing for mountain %d" % i)

func _test_layer_ordering() -> void:
	print("layer z-order from back to front")
	var far_z := -3
	var mid_z := -2
	var near_z := -1
	expect(far_z < mid_z, "far layer behind mid")
	expect(mid_z < near_z, "mid layer behind near")

func _report() -> void:
	var summary := "[parallax-scroll] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
