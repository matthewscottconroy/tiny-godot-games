extends Node

# ---------------------------------------------------------------------------
# Minimal test harness
# ---------------------------------------------------------------------------
var _pass := 0
var _fail := 0


func expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("  PASS: %s" % label)
	else:
		_fail += 1
		print("  FAIL: %s" % label)


func _report() -> void:
	print("\n=== Typed Event Bus Tests: %d passed, %d failed ===" % [_pass, _fail])


# ---------------------------------------------------------------------------
# Inline EventBus implementation (mirrors scripts/event_bus.gd)
# ---------------------------------------------------------------------------
class TestBus:
	var _listeners: Dictionary = {}

	func on(event_type: String, callback: Callable) -> void:
		if not _listeners.has(event_type):
			_listeners[event_type] = []
		_listeners[event_type].append(callback)

	func off(event_type: String, callback: Callable) -> void:
		if _listeners.has(event_type):
			_listeners[event_type].erase(callback)

	func emit(event_type: String, data: Dictionary = {}) -> void:
		if _listeners.has(event_type):
			for cb: Callable in _listeners[event_type]:
				cb.call(data)


# ---------------------------------------------------------------------------
# Test state
# ---------------------------------------------------------------------------
var _call_count := 0
var _received_data: Dictionary = {}


func _reset() -> void:
	_call_count = 0
	_received_data = {}


func _counter_cb(_data: Dictionary) -> void:
	_call_count += 1


func _data_cb(data: Dictionary) -> void:
	_received_data = data
	_call_count += 1


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
func _test_subscribe_and_emit() -> void:
	_reset()
	var bus := TestBus.new()
	bus.on("test_event", _counter_cb)
	bus.emit("test_event")
	expect(_call_count == 1, "_test_subscribe_and_emit: callback called once (got %d)" % _call_count)


func _test_multiple_subscribers() -> void:
	_reset()
	var bus := TestBus.new()
	bus.on("multi_event", _counter_cb)
	bus.on("multi_event", _counter_cb)
	bus.on("multi_event", _counter_cb)
	bus.emit("multi_event")
	expect(_call_count == 3,
			"_test_multiple_subscribers: 3 subscribers all called (got %d)" % _call_count)


func _test_unsubscribe() -> void:
	_reset()
	var bus := TestBus.new()
	bus.on("unsub_event", _counter_cb)
	bus.off("unsub_event", _counter_cb)
	bus.emit("unsub_event")
	expect(_call_count == 0,
			"_test_unsubscribe: callback NOT called after unsubscribe (got %d)" % _call_count)


func _test_emit_data() -> void:
	_reset()
	var bus := TestBus.new()
	bus.on("data_event", _data_cb)
	bus.emit("data_event", {"xp": 42, "id": 7})
	expect(_call_count == 1, "_test_emit_data: callback was called")
	expect(_received_data.get("xp", 0) == 42,
			"_test_emit_data: received xp=42 (got %s)" % str(_received_data.get("xp", "missing")))
	expect(_received_data.get("id", -1) == 7,
			"_test_emit_data: received id=7 (got %s)" % str(_received_data.get("id", "missing")))


func _test_no_listeners() -> void:
	_reset()
	var bus := TestBus.new()
	# Should not crash or error — just a no-op
	bus.emit("nonexistent_event", {"foo": "bar"})
	expect(_call_count == 0,
			"_test_no_listeners: no error, no calls when no subscribers (got %d)" % _call_count)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
func _ready() -> void:
	print("\n--- Running Typed Event Bus Tests ---")
	_test_subscribe_and_emit()
	_test_multiple_subscribers()
	_test_unsubscribe()
	_test_emit_data()
	_test_no_listeners()
	_report()
