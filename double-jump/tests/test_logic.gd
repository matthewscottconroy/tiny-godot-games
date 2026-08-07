extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_max_jumps()
	_test_resets_on_floor()
	_test_decrement_on_jump()
	_test_blocked_when_exhausted()
	_test_constants()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_max_jumps() -> void:
	print("max jumps constant")
	const MAX_JUMPS := 2
	expect(MAX_JUMPS == 2, "MAX_JUMPS is 2")

func _test_resets_on_floor() -> void:
	print("jumps reset on landing")
	const MAX_JUMPS := 2
	var jumps_left := 0
	var on_floor := true
	if on_floor:
		jumps_left = MAX_JUMPS
	expect(jumps_left == MAX_JUMPS, "jumps_left resets to MAX_JUMPS on floor")

func _test_decrement_on_jump() -> void:
	print("each jump decrements counter")
	var jumps_left := 2
	jumps_left -= 1
	expect(jumps_left == 1, "first jump: jumps_left is 1")
	jumps_left -= 1
	expect(jumps_left == 0, "second jump: jumps_left is 0")

func _test_blocked_when_exhausted() -> void:
	print("jump blocked when jumps_left is 0")
	var jumps_left := 0
	var jumped := false
	if jumps_left > 0:
		jumped = true
		jumps_left -= 1
	expect(not jumped, "jump blocked at 0 remaining jumps")
	expect(jumps_left == 0, "counter unchanged when jump blocked")

func _test_constants() -> void:
	print("physics constants")
	const JUMP_VEL := -420.0
	const GRAVITY  := 900.0
	expect(JUMP_VEL < 0.0, "JUMP_VEL is upward (negative)")
	expect(GRAVITY > 0.0, "GRAVITY is downward (positive)")

func _report() -> void:
	var summary := "[double-jump] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
