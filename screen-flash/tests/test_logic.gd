extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_flash_sets_color()
	_test_flash_targets_alpha_zero()
	_test_multiple_flashes()
	_test_preset_colors()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) < tol, label)

# --- minimal flash simulation ---

class FakeFlash:
	var color: Color = Color.TRANSPARENT
	var tween_target_alpha: float = -1.0
	var tween_duration: float = -1.0

	func flash(c: Color, duration: float) -> void:
		color = c
		tween_target_alpha = 0.0
		tween_duration = duration

func _test_flash_sets_color() -> void:
	print("flash sets color")
	var f := FakeFlash.new()
	f.flash(Color(1, 0, 0, 0.65), 0.3)
	expect(f.color.r == 1.0, "red channel correct")
	expect(f.color.g == 0.0, "green channel correct")
	expect_approx(f.color.a, 0.65, "alpha set to flash value")

func _test_flash_targets_alpha_zero() -> void:
	print("tween targets alpha 0")
	var f := FakeFlash.new()
	f.flash(Color(1, 1, 1, 0.9), 0.4)
	expect(f.tween_target_alpha == 0.0, "tween ends at alpha=0 (fully transparent)")
	expect_approx(f.tween_duration, 0.4, "tween duration matches argument")

func _test_multiple_flashes() -> void:
	print("second flash overwrites first")
	var f := FakeFlash.new()
	f.flash(Color(1, 0, 0, 0.6), 0.3)
	f.flash(Color(1, 1, 0, 0.7), 0.25)
	expect(f.color == Color(1, 1, 0, 0.7), "last flash color wins")
	expect_approx(f.tween_duration, 0.25, "last flash duration wins")

func _test_preset_colors() -> void:
	print("preset flash types")
	var presets := [
		{"name": "damage",     "color": Color(1.0, 0.1, 0.1, 0.65), "dur": 0.35},
		{"name": "pickup",     "color": Color(1.0, 0.9, 0.1, 0.70), "dur": 0.25},
		{"name": "transition", "color": Color(0.2, 0.6, 1.0, 0.55), "dur": 0.40},
		{"name": "respawn",    "color": Color(1.0, 1.0, 1.0, 0.90), "dur": 0.45},
	]
	for p in presets:
		var f := FakeFlash.new()
		f.flash(p["color"], p["dur"])
		expect(f.color.a > 0.0, "%s flash has nonzero alpha" % p["name"])
		expect(f.tween_duration > 0.0, "%s flash has positive duration" % p["name"])

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
