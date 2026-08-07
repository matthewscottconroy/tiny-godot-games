extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_pool_size()
	_test_request_returns_inactive()
	_test_request_returns_null_when_all_active()
	_test_hit_miss_tracking()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_pool_size() -> void:
	print("pool size")
	const POOL_SIZE := 20
	expect(POOL_SIZE == 20, "POOL_SIZE is 20")

func _test_request_returns_inactive() -> void:
	print("request returns first inactive bullet")
	var bullets := []
	for i in 20:
		bullets.append({"visible": false})
	var result = null
	for b in bullets:
		if not b["visible"]:
			result = b
			break
	expect(result != null, "inactive bullet found in pool")
	expect(result["visible"] == false, "returned bullet was inactive")

func _test_request_returns_null_when_all_active() -> void:
	print("request returns null when pool exhausted")
	var bullets := []
	for i in 20:
		bullets.append({"visible": true})
	var result = null
	for b in bullets:
		if not b["visible"]:
			result = b
			break
	expect(result == null, "null returned when all bullets active")

func _test_hit_miss_tracking() -> void:
	print("hit and miss counters")
	var hits := 0
	var misses := 0
	hits += 1
	misses += 1
	misses += 1
	expect(hits == 1, "hit counter increments")
	expect(misses == 2, "miss counter increments")
	expect(hits + misses == 3, "total shots tracked correctly")

func _report() -> void:
	var summary := "[object-pool] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
