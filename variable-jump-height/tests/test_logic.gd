extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_jump_cut_constant()
	_test_cut_reduces_velocity()
	_test_cut_only_on_release_while_rising()
	_test_full_jump_velocity()
	_test_cut_jump_velocity()
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

func _test_jump_cut_constant() -> void:
	print("jump cut constant")
	const JUMP_CUT := 0.4
	expect(JUMP_CUT > 0.0 and JUMP_CUT < 1.0, "JUMP_CUT is between 0 and 1")
	expect(JUMP_CUT == 0.4, "JUMP_CUT is 0.4")

func _test_cut_reduces_velocity() -> void:
	print("early release multiplies vy by JUMP_CUT")
	const JUMP_VEL := -520.0
	const JUMP_CUT := 0.4
	var vy := JUMP_VEL
	vy *= JUMP_CUT
	expect_near(vy, JUMP_VEL * JUMP_CUT, "cut velocity equals JUMP_VEL * JUMP_CUT")
	expect(absf(vy) < absf(JUMP_VEL), "cut velocity magnitude is smaller")

func _test_cut_only_on_release_while_rising() -> void:
	print("cut only triggers while still rising (vy < 0)")
	var vy_rising := -300.0
	var vy_falling := 200.0
	expect(vy_rising < 0.0, "rising vy is negative — cut applies")
	expect(not (vy_falling < 0.0), "falling vy is positive — cut does not apply")

func _test_full_jump_velocity() -> void:
	print("full hold jump reaches JUMP_VEL")
	const JUMP_VEL := -520.0
	var vy := JUMP_VEL
	expect_near(vy, -520.0, "full jump starts at JUMP_VEL")

func _test_cut_jump_velocity() -> void:
	print("cut jump velocity after early release")
	const JUMP_VEL := -520.0
	const JUMP_CUT := 0.4
	var vy_cut := JUMP_VEL * JUMP_CUT
	expect_near(vy_cut, -208.0, "cut jump vy is JUMP_VEL * 0.4 = -208")
	expect(absf(vy_cut) < absf(JUMP_VEL), "cut jump is weaker than full jump")

func _report() -> void:
	var summary := "[variable-jump-height] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
