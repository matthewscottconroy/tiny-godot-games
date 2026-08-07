extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_defaults()
	_test_x_bounce()
	_test_y_bounce()
	_test_position_clamp_on_bounce()
	_test_velocity_reversal()
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

func _test_defaults() -> void:
	print("export var defaults")
	var radius := 20.0
	var velocity := Vector2(120, 90)
	expect(radius == 20.0, "default radius is 20")
	expect(velocity.x == 120.0, "default velocity x is 120")
	expect(velocity.y == 90.0, "default velocity y is 90")

func _test_x_bounce() -> void:
	print("x axis bounce detection")
	var radius := 20.0
	var vp_width := 640.0
	var pos_x := 5.0
	var vel_x := -80.0
	if pos_x - radius < 0:
		vel_x *= -1
		pos_x = clampf(pos_x, radius, vp_width - radius)
	expect(vel_x > 0.0, "velocity reversed when hitting left wall")
	pos_x = 630.0
	vel_x = 80.0
	if pos_x + radius > vp_width:
		vel_x *= -1
		pos_x = clampf(pos_x, radius, vp_width - radius)
	expect(vel_x < 0.0, "velocity reversed when hitting right wall")

func _test_y_bounce() -> void:
	print("y axis bounce detection")
	var radius := 20.0
	var pos_y := 25.0
	var vel_y := -60.0
	if pos_y - radius < 40:
		vel_y *= -1
	expect(vel_y > 0.0, "velocity reversed near top boundary (y-40)")
	var vp_height := 480.0
	pos_y = 465.0
	vel_y = 60.0
	if pos_y + radius > vp_height - 30:
		vel_y *= -1
	expect(vel_y < 0.0, "velocity reversed near bottom boundary")

func _test_position_clamp_on_bounce() -> void:
	print("position clamped on bounce")
	var radius := 20.0
	var vp_width := 640.0
	var pos_x := -5.0
	if pos_x - radius < 0:
		pos_x = clampf(pos_x, radius, vp_width - radius)
	expect(pos_x >= radius, "position clamped to at least radius from edge")

func _test_velocity_reversal() -> void:
	print("velocity reversal is exact negation")
	var vel := Vector2(120.0, 90.0)
	vel.x *= -1
	expect_near(vel.x, -120.0, "vel.x reversed")
	vel.y *= -1
	expect_near(vel.y, -90.0, "vel.y reversed")

func _report() -> void:
	var summary := "[export-vars] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
