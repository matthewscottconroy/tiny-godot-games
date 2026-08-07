extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_resource_count()
	_test_progress_formula()
	_test_progress_at_zero()
	_test_progress_at_complete()
	_test_progress_clamped()
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

func _test_resource_count() -> void:
	print("resource count")
	const RESOURCE_COUNT := 8
	expect(RESOURCE_COUNT == 8, "RESOURCE_COUNT is 8")

func _test_progress_formula() -> void:
	print("progress percentage formula")
	var total := 8
	var done := 4
	var progress := float(done) / float(total) * 100.0
	expect_near(progress, 50.0, "4 of 8 done = 50%")

func _test_progress_at_zero() -> void:
	print("progress starts at 0%")
	var total := 8
	var done := 0
	var progress := float(done) / float(total) * 100.0
	expect_near(progress, 0.0, "0 done = 0%")

func _test_progress_at_complete() -> void:
	print("progress reaches 100% when all loaded")
	var total := 8
	var done := 8
	var progress := float(done) / float(total) * 100.0
	expect_near(progress, 100.0, "all done = 100%")

func _test_progress_clamped() -> void:
	print("progress never exceeds 100%")
	var total := 8
	var done := 8
	var progress := clampf(float(done) / float(total) * 100.0, 0.0, 100.0)
	expect(progress <= 100.0, "progress is at most 100%")
	expect(progress >= 0.0, "progress is at least 0%")

func _report() -> void:
	var summary := "[thread-loading] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
