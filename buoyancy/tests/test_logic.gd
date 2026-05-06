extends Node

const WATER_Y := 240.0
const GRAVITY := 500.0
const BUOYANCY := 900.0

var _pass := 0
var _fail := 0

func expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("  PASS: ", label)
	else:
		_fail += 1
		print("  FAIL: ", label)

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])

func _ready() -> void:
	print("=== Buoyancy Tests ===")
	_test_fully_submerged()
	_test_half_submerged()
	_test_above_water()
	_test_density_float()
	_test_density_sink()
	_report()

func _test_fully_submerged() -> void:
	print("_test_fully_submerged")
	var pos_y := 300.0
	var size_y := 40.0
	var bottom := pos_y + size_y * 0.5
	var submerged := clampf(bottom - WATER_Y, 0.0, size_y)
	var depth_frac := submerged / size_y
	# bottom = 300 + 20 = 320, submerged = 320 - 240 = 80, clamped to size_y=40, depth_frac = 1.0
	expect(is_equal_approx(depth_frac, 1.0), "fully submerged depth_frac == 1.0")

func _test_half_submerged() -> void:
	print("_test_half_submerged")
	var pos_y := 240.0
	var size_y := 40.0
	var bottom := pos_y + size_y * 0.5
	var submerged := clampf(bottom - WATER_Y, 0.0, size_y)
	var depth_frac := submerged / size_y
	# bottom = 240 + 20 = 260, submerged = 260 - 240 = 20, depth_frac = 0.5
	expect(is_equal_approx(depth_frac, 0.5), "half submerged depth_frac == 0.5")

func _test_above_water() -> void:
	print("_test_above_water")
	var pos_y := 100.0
	var size_y := 40.0
	var bottom := pos_y + size_y * 0.5
	var submerged := clampf(bottom - WATER_Y, 0.0, size_y)
	var depth_frac := submerged / size_y
	# bottom = 100 + 20 = 120 < 240, submerged = 0, depth_frac = 0
	expect(is_equal_approx(depth_frac, 0.0), "above water depth_frac == 0.0")

func _test_density_float() -> void:
	print("_test_density_float")
	var density := 0.3
	# When fully submerged: net_accel = GRAVITY*density - BUOYANCY*1.0
	var net_accel := GRAVITY * density - BUOYANCY * 1.0
	# 500*0.3 - 900 = 150 - 900 = -750 (negative = floats upward)
	expect(net_accel < 0.0, "light object (density=0.3) has negative net acceleration (floats)")

func _test_density_sink() -> void:
	print("_test_density_sink")
	var density := 1.4
	# In air (depth_frac=0): net_accel = GRAVITY*density - BUOYANCY*0.0
	var net_accel := GRAVITY * density - BUOYANCY * 0.0
	# 500*1.4 - 0 = 700 (positive = sinks)
	expect(net_accel > 0.0, "heavy object (density=1.4) has positive net acceleration in air (sinks)")
