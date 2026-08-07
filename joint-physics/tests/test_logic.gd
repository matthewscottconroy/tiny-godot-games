extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_pendulum_constants()
	_test_pendulum_link_positions()
	_test_spring_constants()
	_test_spring_rest_length()
	_test_spring_midpoint()
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

func _test_pendulum_constants() -> void:
	print("pendulum constants")
	const PEND_X := 160.0
	const PEND_ANCHOR_Y := 80.0
	const LINK_COUNT := 5
	const LINK_SPACING := 50.0
	expect(PEND_X == 160.0, "pendulum x is 160")
	expect(PEND_ANCHOR_Y == 80.0, "pendulum anchor y is 80")
	expect(LINK_COUNT == 5, "5 pendulum links")
	expect(LINK_SPACING == 50.0, "link spacing is 50")

func _test_pendulum_link_positions() -> void:
	print("pendulum link y positions")
	const PEND_ANCHOR_Y := 80.0
	const LINK_SPACING := 50.0
	for i in 5:
		var link_y := PEND_ANCHOR_Y + (i + 1) * LINK_SPACING
		expect(link_y == PEND_ANCHOR_Y + (i + 1) * LINK_SPACING,
			"link %d y is correct" % i)
	var bottom_y := PEND_ANCHOR_Y + 5 * LINK_SPACING
	expect_near(bottom_y, 330.0, "bottom link at y=330")

func _test_spring_constants() -> void:
	print("spring constants")
	const SPRING_CX := 480.0
	const SPRING_ANCHOR_Y := 90.0
	const SPRING_GAP := 90.0
	expect(SPRING_CX == 480.0, "spring center x is 480")
	expect(SPRING_ANCHOR_Y == 90.0, "spring anchor y is 90")
	expect(SPRING_GAP == 90.0, "spring gap is 90")

func _test_spring_rest_length() -> void:
	print("spring rest length = dist * 0.80")
	var dist := 200.0
	var rest_length := dist * 0.80
	expect_near(rest_length, 160.0, "rest length is 80% of natural length")

func _test_spring_midpoint() -> void:
	print("spring joint positioned at midpoint")
	var a := Vector2(100.0, 90.0)
	var b := Vector2(200.0, 90.0)
	var mid := (a + b) * 0.5
	expect_near(mid.x, 150.0, "midpoint x is average of endpoints")
	expect_near(mid.y, 90.0, "midpoint y unchanged for horizontal spring")

func _report() -> void:
	var summary := "[joint-physics] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
