extends Node

# Drives the real ObjectPool from scripts/object_pool.gd rather than a list of
# dictionaries standing in for pooled nodes.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_pool_preallocates()
	_test_acquire_returns_inactive()
	_test_acquire_returns_null_when_all_active()
	_test_released_instance_is_reused()
	_test_hit_miss_tracking()
	_test_signals()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

const POOL_SIZE := 20

# ObjectPool fills itself in _ready(), so the pool has to enter the tree. The
# pooled scene is built here instead of loaded so the test stays self-contained.
func _make_pool(size: int = POOL_SIZE) -> ObjectPool:
	var template := Node2D.new()
	var packed := PackedScene.new()
	packed.pack(template)
	template.free()

	var pool := ObjectPool.new()
	pool.scene = packed
	pool.size = size
	add_child(pool)
	return pool

func _test_pool_preallocates() -> void:
	print("pool preallocates its instances")
	var pool := _make_pool()
	expect(pool.get_child_count() == POOL_SIZE, "pool instantiates `size` children up front")
	expect(pool.active_count() == 0, "every instance starts inactive (hidden)")

func _test_acquire_returns_inactive() -> void:
	print("acquire returns an inactive instance")
	var pool := _make_pool()
	var instance := pool.acquire()
	expect(instance != null, "inactive instance found in pool")
	expect(not instance.visible, "the returned instance is still hidden — the caller shows it")

func _test_acquire_returns_null_when_all_active() -> void:
	print("acquire returns null when the pool is exhausted")
	var pool := _make_pool(3)
	for i in 3:
		var instance := pool.acquire()
		instance.visible = true          # mark it in use
	expect(pool.active_count() == 3, "all three instances are active")
	expect(pool.acquire() == null, "null returned when every instance is active")

func _test_released_instance_is_reused() -> void:
	print("hiding an instance returns it to the pool")
	var pool := _make_pool(1)
	var first := pool.acquire()
	first.visible = true
	expect(pool.acquire() == null, "pool of 1 is exhausted while its instance is visible")
	first.visible = false                # release
	expect(pool.acquire() == first, "the same instance is handed out again after release")

func _test_hit_miss_tracking() -> void:
	print("hit and miss counters")
	var pool := _make_pool(1)
	var instance := pool.acquire()
	instance.visible = true
	pool.acquire()                       # miss
	pool.acquire()                       # miss
	expect(pool.reuse_count == 1, "hit counter increments on a successful acquire")
	expect(pool.miss_count == 2, "miss counter increments when exhausted")
	expect(pool.reuse_count + pool.miss_count == 3, "total acquire attempts tracked correctly")

func _test_signals() -> void:
	print("acquired and exhausted signals")
	var pool := _make_pool(1)
	var events: Array[String] = []
	pool.acquired.connect(func(_instance: Node) -> void: events.append("acquired"))
	pool.exhausted.connect(func() -> void: events.append("exhausted"))
	var instance := pool.acquire()
	instance.visible = true
	pool.acquire()
	expect(events == ["acquired", "exhausted"], "acquired then exhausted, in that order")

func _report() -> void:
	var summary := "[object-pool] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
