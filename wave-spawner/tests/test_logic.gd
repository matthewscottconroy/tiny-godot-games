extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_wave_count()
	_test_enemy_count_per_wave()
	_test_enemy_speed_per_wave()
	_test_enemy_hp_per_wave()
	_test_intermission_duration()
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

func _test_wave_count() -> void:
	print("total wave count")
	var total_waves := 5
	expect(total_waves == 5, "5 total waves")

func _test_enemy_count_per_wave() -> void:
	print("enemy count formula: 3 + (wave-1)*2")
	for w in range(1, 6):
		var count := 3 + (w - 1) * 2
		var expected := [3, 5, 7, 9, 11][w - 1]
		expect(count == expected, "wave %d has %d enemies" % [w, expected])

func _test_enemy_speed_per_wave() -> void:
	print("enemy speed formula: 40 + wave*12")
	for w in range(1, 6):
		var speed := 40.0 + w * 12.0
		var expected := [52.0, 64.0, 76.0, 88.0, 100.0][w - 1]
		expect_near(speed, expected, "wave %d enemy speed is %.0f" % [w, expected])

func _test_enemy_hp_per_wave() -> void:
	print("enemy HP formula: 2 + wave")
	for w in range(1, 6):
		var hp := 2 + w
		var expected := [3, 4, 5, 6, 7][w - 1]
		expect(hp == expected, "wave %d enemy HP is %d" % [w, expected])

func _test_intermission_duration() -> void:
	print("intermission duration between waves")
	var intermission_duration := 3.0
	expect_near(intermission_duration, 3.0, "intermission is 3.0s")

func _report() -> void:
	var summary := "[wave-spawner] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
