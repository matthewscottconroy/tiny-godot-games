extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_coin_positions()
	_test_log_cap()
	_test_log_push_front()
	_test_log_pop_back()
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

func _test_coin_positions() -> void:
	print("coin positions")
	var positions := [
		Vector2(100, 200), Vector2(200, 140), Vector2(400, 180),
		Vector2(520, 240), Vector2(300, 300), Vector2(460, 350),
	]
	expect(positions.size() == 6, "6 coin positions defined")
	expect(positions[0] == Vector2(100, 200), "first coin at (100, 200)")
	expect(positions[5] == Vector2(460, 350), "last coin at (460, 350)")

func _test_log_cap() -> void:
	print("log capped at 9 entries")
	var log_lines: Array[String] = []
	for i in 12:
		log_lines.push_front("line %d" % i)
		if log_lines.size() > 9:
			log_lines.pop_back()
	expect(log_lines.size() == 9, "log capped at 9 entries")

func _test_log_push_front() -> void:
	print("log push_front keeps newest at front")
	var log_lines: Array[String] = []
	log_lines.push_front("first")
	log_lines.push_front("second")
	expect(log_lines[0] == "second", "newest entry is at front")
	expect(log_lines[1] == "first", "older entry is at index 1")

func _test_log_pop_back() -> void:
	print("log pop_back removes oldest entry")
	var log_lines: Array[String] = []
	for i in 10:
		log_lines.push_front("msg%d" % i)
		if log_lines.size() > 9:
			log_lines.pop_back()
	expect(log_lines.size() <= 9, "pop_back keeps size at most 9")
	expect(not log_lines.has("msg0"), "oldest entry (msg0) was removed")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
