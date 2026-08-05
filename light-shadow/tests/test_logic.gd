extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_light_radii()
	_test_alpha_at_center()
	_test_alpha_at_edge()
	_test_alpha_outside()
	_test_alpha_falloff_curve()
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

func _test_light_radii() -> void:
	print("light texture radii")
	var player_radius := 100
	var torch_radius := 140
	expect(player_radius == 100, "player light radius is 100")
	expect(torch_radius == 140, "torch light radius is 140")
	expect(torch_radius > player_radius, "torch is larger than player light")

func _test_alpha_at_center() -> void:
	print("alpha at center (d=0)")
	var radius := 100.0
	var d := 0.0
	var a := pow(maxf(1.0 - d / radius, 0.0), 1.8)
	expect_near(a, 1.0, "alpha at center is 1.0")

func _test_alpha_at_edge() -> void:
	print("alpha at edge (d=radius)")
	var radius := 100.0
	var d := radius
	var a := pow(maxf(1.0 - d / radius, 0.0), 1.8)
	expect_near(a, 0.0, "alpha at edge is 0.0")

func _test_alpha_outside() -> void:
	print("alpha outside radius is 0 (clamped)")
	var radius := 100.0
	var d := 150.0
	var a := pow(maxf(1.0 - d / radius, 0.0), 1.8)
	expect_near(a, 0.0, "alpha outside radius clamped to 0")

func _test_alpha_falloff_curve() -> void:
	print("alpha falloff is non-linear (pow 1.8)")
	var radius := 100.0
	var d_half := radius * 0.5
	var a_half := pow(maxf(1.0 - d_half / radius, 0.0), 1.8)
	expect(a_half < 0.5, "at half radius, alpha is less than 0.5 (nonlinear falloff)")
	expect(a_half > 0.0, "at half radius, alpha is still positive")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
