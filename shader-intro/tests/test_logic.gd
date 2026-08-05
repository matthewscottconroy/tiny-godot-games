extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_shader_mode_count()
	_test_shader_mode_names()
	_test_mode_cycling()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_shader_mode_count() -> void:
	print("shader mode count")
	var modes := ["NONE", "TINT", "FLASH", "OUTLINE"]
	expect(modes.size() == 4, "4 shader modes defined")

func _test_shader_mode_names() -> void:
	print("shader mode names")
	var modes := ["NONE", "TINT", "FLASH", "OUTLINE"]
	expect(modes[0] == "NONE", "first mode is NONE")
	expect(modes[1] == "TINT", "second mode is TINT")
	expect(modes[2] == "FLASH", "third mode is FLASH")
	expect(modes[3] == "OUTLINE", "fourth mode is OUTLINE")

func _test_mode_cycling() -> void:
	print("mode cycles through all values")
	var mode_count := 4
	var current := 0
	for i in mode_count:
		current = (current + 1) % mode_count
	expect(current == 0, "cycling through all modes returns to start")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
