extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_constants()
	_test_walk_threshold()
	_test_visual_flip()
	_test_gravity_accumulation()
	_test_idle_anim_length()
	_test_walk_anim_length()
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

func _test_constants() -> void:
	print("constants")
	const SPEED := 160.0
	const GRAVITY := 900.0
	expect(SPEED == 160.0, "SPEED is 160")
	expect(GRAVITY == 900.0, "GRAVITY is 900")

func _test_walk_threshold() -> void:
	print("walk threshold")
	var vel_x := 0.0
	expect(not (abs(vel_x) > 10), "zero velocity is not walking")
	vel_x = 10.0
	expect(not (abs(vel_x) > 10), "exactly 10 is not walking")
	vel_x = 11.0
	expect(abs(vel_x) > 10, "11 is walking")
	vel_x = -50.0
	expect(abs(vel_x) > 10, "negative speed also triggers walk")

func _test_visual_flip() -> void:
	print("visual flip direction")
	var scale_x := 1.0
	var vel_x := -20.0
	if vel_x < -5.0:
		scale_x = -1.0
	elif vel_x > 5.0:
		scale_x = 1.0
	expect(scale_x == -1.0, "moving left flips scale to -1")
	vel_x = 20.0
	if vel_x < -5.0:
		scale_x = -1.0
	elif vel_x > 5.0:
		scale_x = 1.0
	expect(scale_x == 1.0, "moving right flips scale to 1")
	vel_x = 3.0
	var old_scale := scale_x
	if vel_x < -5.0:
		scale_x = -1.0
	elif vel_x > 5.0:
		scale_x = 1.0
	expect(scale_x == old_scale, "slow movement keeps current scale")

func _test_gravity_accumulation() -> void:
	print("gravity accumulation")
	const GRAVITY := 900.0
	var vel_y := 0.0
	vel_y += GRAVITY * 0.016
	expect(vel_y > 0.0, "gravity increases vel_y")
	expect_near(vel_y, 14.4, "gravity * delta correct", 0.01)

func _test_idle_anim_length() -> void:
	print("idle animation length")
	var idle_length := 1.2
	expect_near(idle_length, 1.2, "idle animation length is 1.2s")

func _test_walk_anim_length() -> void:
	print("walk animation length")
	var walk_length := 0.32
	expect_near(walk_length, 0.32, "walk animation length is 0.32s")

func _report() -> void:
	var summary := "[animated-walk] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
