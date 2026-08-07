extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_trail_caps_at_max()
	test_trail_inserts_at_front()
	test_trail_tail_removed_on_overflow()
	test_trail_grows_to_max_then_stays()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[trail-effect] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Simulate the trail using a plain array (no Line2D needed)
func _add_trail(pts: Array, pos: Vector2, max_len: int) -> Array:
	pts.push_front(pos)
	while pts.size() > max_len:
		pts.pop_back()
	return pts

func test_trail_caps_at_max() -> void:
	var pts := []
	var max_len := 10
	for i in 20:
		pts = _add_trail(pts, Vector2(i, 0), max_len)
	expect(pts.size() == max_len, "trail caps at MAX_POINTS")

func test_trail_inserts_at_front() -> void:
	var pts := []
	pts = _add_trail(pts, Vector2(1, 0), 5)
	pts = _add_trail(pts, Vector2(2, 0), 5)
	pts = _add_trail(pts, Vector2(3, 0), 5)
	expect(pts[0] == Vector2(3, 0), "newest point is at front (index 0)")
	expect(pts[2] == Vector2(1, 0), "oldest point is at back")

func test_trail_tail_removed_on_overflow() -> void:
	var pts := []
	var max_len := 3
	for i in 5:
		pts = _add_trail(pts, Vector2(i, 0), max_len)
	expect(not Vector2(0, 0) in pts, "oldest point removed when overflow")
	expect(not Vector2(1, 0) in pts, "second-oldest also removed")
	expect(Vector2(4, 0) in pts, "newest point still present")

func test_trail_grows_to_max_then_stays() -> void:
	var pts := []
	for i in 100:
		pts = _add_trail(pts, Vector2(i, 0), 20)
		expect(pts.size() <= 20, "trail never exceeds max at step %d" % i)
