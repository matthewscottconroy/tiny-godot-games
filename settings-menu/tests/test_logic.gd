extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_linear_to_db_unity()
	_test_linear_to_db_half()
	_test_linear_to_db_zero()
	_test_config_round_trip()
	_test_cancel_reverts_ui()
	_test_reset_defaults()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) < tol, label)

# --- linear_to_db tests ---

func _test_linear_to_db_unity() -> void:
	print("linear_to_db: 1.0 -> 0 dB")
	var db := linear_to_db(1.0)
	expect_approx(db, 0.0, "linear_to_db(1.0) = 0.0 dB")

func _test_linear_to_db_half() -> void:
	print("linear_to_db: 0.5 -> approximately -6 dB")
	var db := linear_to_db(0.5)
	expect(db < -5.0 and db > -7.0, "linear_to_db(0.5) near -6 dB (got %.2f)" % db)

func _test_linear_to_db_zero() -> void:
	print("linear_to_db: very small value -> very negative dB")
	var db := linear_to_db(0.001)
	expect(db < -50.0, "linear_to_db(0.001) very negative (got %.2f)" % db)

# --- ConfigFile round-trip simulation ---

class FakeConfig:
	var _data: Dictionary = {}

	func set_value(section: String, key: String, value: Variant) -> void:
		if not _data.has(section):
			_data[section] = {}
		_data[section][key] = value

	func get_value(section: String, key: String, default: Variant = null) -> Variant:
		if _data.has(section) and _data[section].has(key):
			return _data[section][key]
		return default

func _test_config_round_trip() -> void:
	print("ConfigFile: round-trip save/load")
	var cfg := FakeConfig.new()
	cfg.set_value("audio",    "volume",     0.75)
	cfg.set_value("display",  "fullscreen", true)
	cfg.set_value("gameplay", "speed",      300)

	expect_approx(cfg.get_value("audio", "volume", 1.0), 0.75, "volume round-trips correctly")
	expect(cfg.get_value("display", "fullscreen", false) == true, "fullscreen round-trips correctly")
	expect(cfg.get_value("gameplay", "speed", 200) == 300, "speed round-trips correctly")
	expect(cfg.get_value("missing", "key", 42) == 42, "missing key returns default")

# --- Apply/Cancel pattern simulation ---

class FakeSettingsUI:
	var saved_vol:   float = 1.0
	var saved_fs:    bool  = false
	var saved_speed: int   = 200

	var ui_vol:   float = 1.0
	var ui_fs:    bool  = false
	var ui_speed: int   = 200

	func apply_to_ui() -> void:
		ui_vol   = saved_vol
		ui_fs    = saved_fs
		ui_speed = saved_speed

	func on_apply() -> void:
		saved_vol   = ui_vol
		saved_fs    = ui_fs
		saved_speed = ui_speed

	func on_cancel() -> void:
		apply_to_ui()

	func on_reset() -> void:
		saved_vol   = 1.0
		saved_fs    = false
		saved_speed = 200
		apply_to_ui()

func _test_cancel_reverts_ui() -> void:
	print("cancel: reverts UI to saved values")
	var s := FakeSettingsUI.new()
	s.saved_vol   = 0.6
	s.saved_speed = 150
	# User changes UI without applying
	s.ui_vol   = 0.3
	s.ui_speed = 400
	s.on_cancel()
	expect_approx(s.ui_vol, 0.6, "volume reverted to saved value")
	expect(s.ui_speed == 150, "speed reverted to saved value")

func _test_reset_defaults() -> void:
	print("reset: restores default values")
	var s := FakeSettingsUI.new()
	s.saved_vol   = 0.3
	s.saved_fs    = true
	s.saved_speed = 350
	s.on_reset()
	expect_approx(s.saved_vol,   1.0,   "volume reset to 1.0")
	expect(s.saved_fs    == false, "fullscreen reset to false")
	expect(s.saved_speed == 200,   "speed reset to 200")
	expect_approx(s.ui_vol, 1.0, "UI volume shows reset value")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
