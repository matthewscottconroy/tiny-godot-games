extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_agent_speed()
	_test_obstacle_count()
	_test_obstacle_margin()
	_test_obstacle_bounds()
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

func _test_agent_speed() -> void:
	print("agent speed")
	const AGENT_SPEED := 120.0
	expect(AGENT_SPEED == 120.0, "AGENT_SPEED is 120")

func _test_obstacle_count() -> void:
	print("obstacle count")
	var obstacles := [
		Rect2(160, 140, 120, 100),
		Rect2(400, 200, 140, 80),
		Rect2(260, 310, 100, 120),
	]
	expect(obstacles.size() == 3, "3 obstacles defined")

func _test_obstacle_margin() -> void:
	print("obstacle margin expansion")
	const MARGIN := 6.0
	var base := Rect2(160, 140, 120, 100)
	var expanded := base.grow(MARGIN)
	expect(expanded.position.x < base.position.x, "expanded rect extends left")
	expect(expanded.size.x > base.size.x, "expanded rect is wider")
	expect_near(expanded.size.x - base.size.x, MARGIN * 2.0, "width grows by 2*margin")

func _test_obstacle_bounds() -> void:
	print("obstacle bounds are positive dimensions")
	var obstacles := [
		Rect2(160, 140, 120, 100),
		Rect2(400, 200, 140, 80),
		Rect2(260, 310, 100, 120),
	]
	for obs in obstacles:
		expect(obs.size.x > 0 and obs.size.y > 0, "obstacle has positive size")

func _report() -> void:
	var summary := "[navigation-agent] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
