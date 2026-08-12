extends Node

# Drives the real player from scripts/player.gd rather than a copy of the
# counter. See docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_starts_empty_until_grounded()
	_test_landing_refills()
	_test_first_jump()
	_test_second_jump_in_air()
	_test_no_third_jump()
	_test_press_without_charges_does_nothing()
	_test_landing_refills_after_spending()
	_test_holding_does_not_drain()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[double-jump] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/player.gd")

func _make() -> CharacterBody2D:
	var player := CharacterBody2D.new()
	player.set_script(_script)
	add_child(player)
	return player

func _test_starts_empty_until_grounded() -> void:
	print("before touching the ground")
	var p := _make()
	expect(p.jumps_left() == 0, "no charges before the first landing")

func _test_landing_refills() -> void:
	print("landing refills")
	var p := _make()
	p.tick_jump(true, false)
	expect(p.jumps_left() == p.MAX_JUMPS, "touching the floor restores every charge")

func _test_first_jump() -> void:
	print("the ground jump")
	var p := _make()
	p.tick_jump(true, false)
	expect(p.tick_jump(true, true), "pressing on the ground jumps")
	expect(p.jumps_left() == p.MAX_JUMPS - 1, "and spends one charge")

func _test_second_jump_in_air() -> void:
	print("the air jump")
	var p := _make()
	p.tick_jump(true, false)
	p.tick_jump(true, true)                     # ground jump
	expect(p.tick_jump(false, true), "a second press in mid-air jumps again")
	expect(p.jumps_left() == 0, "spending the last charge")

func _test_no_third_jump() -> void:
	print("no third jump")
	var p := _make()
	p.tick_jump(true, false)
	p.tick_jump(true, true)
	p.tick_jump(false, true)
	expect(not p.tick_jump(false, true), "a third press in the air does nothing")
	expect(p.jumps_left() == 0, "and cannot push the counter negative")

func _test_press_without_charges_does_nothing() -> void:
	print("pressing with no charges")
	var p := _make()
	expect(not p.tick_jump(false, true), "pressing before ever landing does nothing")
	expect(p.jumps_left() == 0, "the counter stays at zero")

func _test_landing_refills_after_spending() -> void:
	print("refill after landing again")
	var p := _make()
	p.tick_jump(true, false)
	p.tick_jump(true, true)
	p.tick_jump(false, true)
	expect(p.jumps_left() == 0, "both charges spent")
	p.tick_jump(true, false)
	expect(p.jumps_left() == p.MAX_JUMPS, "landing restores them")

func _test_holding_does_not_drain() -> void:
	print("only presses count")
	var p := _make()
	p.tick_jump(true, false)
	for i in 30:
		p.tick_jump(false, false)
	expect(p.jumps_left() == p.MAX_JUMPS, "frames without a press cost nothing")
