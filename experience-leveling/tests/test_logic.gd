extends Node

const BASE_XP := 50
const MAX_LEVEL := 10

var _pass := 0
var _fail := 0


func _ready() -> void:
	_test_xp_threshold()
	_test_level_up()
	_test_multi_level()
	_test_max_level()
	_test_xp_carries_over()
	_report()


func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)


func _report() -> void:
	var summary := "[experience-leveling] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)


func _calc_xp_threshold(level: int) -> int:
	return int(BASE_XP * pow(1.4, level - 1))


func _test_xp_threshold() -> void:
	expect(_calc_xp_threshold(1) == 50, "XP threshold level 1 = 50")
	expect(_calc_xp_threshold(2) == int(50 * 1.4), "XP threshold level 2 = 70")
	# pow(1.4, 2) lands just under 1.96, and int() truncates rather than rounds,
	# so the curve yields 97 here — matching LevelSystem.threshold().
	expect(_calc_xp_threshold(3) == 97, "XP threshold level 3 = 97")


func _test_level_up() -> void:
	var level := 1
	var xp := 0
	var xp_for_next := _calc_xp_threshold(1)
	var stat_attack := 10

	xp += 50
	while xp >= xp_for_next and level < MAX_LEVEL:
		xp -= xp_for_next
		level += 1
		xp_for_next = _calc_xp_threshold(level)
		stat_attack += 5

	expect(level == 2, "Level up: level becomes 2 after 50 XP")
	expect(stat_attack == 15, "Level up: attack becomes 15")


func _test_multi_level() -> void:
	var level := 1
	var xp := 0
	var xp_for_next := _calc_xp_threshold(1)

	# 50 + 70 = 120 XP needed for 2 levels
	xp += 125
	while xp >= xp_for_next and level < MAX_LEVEL:
		xp -= xp_for_next
		level += 1
		xp_for_next = _calc_xp_threshold(level)

	expect(level == 3, "Multi-level: level becomes 3 after 125 XP")


func _test_max_level() -> void:
	var level := MAX_LEVEL
	var xp := 0
	var xp_for_next := _calc_xp_threshold(level)

	xp += 9999
	while xp >= xp_for_next and level < MAX_LEVEL:
		xp -= xp_for_next
		level += 1
		xp_for_next = _calc_xp_threshold(level)

	expect(level == MAX_LEVEL, "Max level: stays at MAX_LEVEL even with excess XP")


func _test_xp_carries_over() -> void:
	var level := 1
	var xp := 0
	var xp_for_next := _calc_xp_threshold(1)

	xp += 80
	while xp >= xp_for_next and level < MAX_LEVEL:
		xp -= xp_for_next
		level += 1
		xp_for_next = _calc_xp_threshold(level)

	expect(level == 2, "XP carry-over: leveled up to 2")
	expect(xp == 30, "XP carry-over: 30 XP remains after level-up")
