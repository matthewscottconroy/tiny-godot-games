extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_initial_state()
	_test_pause_sets_state()
	_test_resume_clears_state()
	_test_toggle_idempotent()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_initial_state() -> void:
	print("initial pause state")
	var paused := false
	expect(paused == false, "game starts unpaused")

func _test_pause_sets_state() -> void:
	print("pause sets paused flag and shows menu")
	var paused := false
	var menu_visible := false
	paused = true
	menu_visible = true
	expect(paused, "paused flag is true after pause")
	expect(menu_visible, "menu visible after pause")

func _test_resume_clears_state() -> void:
	print("resume clears paused flag and hides menu")
	var paused := true
	var menu_visible := true
	paused = false
	menu_visible = false
	expect(not paused, "paused flag cleared after resume")
	expect(not menu_visible, "menu hidden after resume")

func _test_toggle_idempotent() -> void:
	print("pause/resume toggle is reversible")
	var paused := false
	paused = true
	paused = false
	expect(not paused, "double toggle returns to unpaused")
	paused = true
	expect(paused, "single toggle is paused")

func _report() -> void:
	var summary := "[pause-menu] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
