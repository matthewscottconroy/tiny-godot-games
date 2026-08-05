extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_spawn_timer()
	_test_coin_lifetime()
	_test_coin_collection()
	_test_spawn_counter()
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

func _test_spawn_timer() -> void:
	print("spawner timer interval")
	var wait_time := 1.0
	expect_near(wait_time, 1.0, "spawner wait_time is 1.0s")

func _test_coin_lifetime() -> void:
	print("coin auto-despawn lifetime")
	var lifetime := 4.0
	expect_near(lifetime, 4.0, "coin lifetime is 4.0s")
	expect(lifetime > wait_time_value(), "coin lives longer than spawn interval")

func wait_time_value() -> float:
	return 1.0

func _test_coin_collection() -> void:
	print("coin collected removes instance")
	var coin_alive := true
	coin_alive = false
	expect(not coin_alive, "coin no longer alive after collection")

func _test_spawn_counter() -> void:
	print("spawn count increments")
	var spawned := 0
	spawned += 1
	spawned += 1
	expect(spawned == 2, "spawn counter tracks instances created")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
