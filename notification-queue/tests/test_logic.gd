extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_queue_push_fifo()
	_test_busy_flag_prevents_double_show()
	_test_queue_drains_in_order()
	_test_empty_queue_clears_busy()
	_test_push_while_busy_queues()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# --- Simulated notification manager (no scene tree) ---

class FakeNotifManager:
	var _queue: Array[String] = []
	var _busy := false
	var _showing := ""
	var _show_call_count := 0

	func push(msg: String) -> void:
		_queue.append(msg)
		if not _busy:
			_show_next()

	func _show_next() -> void:
		if _queue.is_empty():
			_busy = false
			return
		_busy = true
		_showing = _queue.pop_front()
		_show_call_count += 1
		# In real code a tween callback would call _show_next again.
		# For test purposes we just record state.

	func finish_current() -> void:
		# Simulate tween completing
		_show_next()

func _test_queue_push_fifo() -> void:
	print("push: messages stored in FIFO order")
	var mgr := FakeNotifManager.new()
	mgr.push("first")
	mgr.push("second")
	mgr.push("third")
	# first was immediately shown (popped), remaining two are queued
	expect(mgr._showing == "first", "first message shown immediately")
	expect(mgr._queue.size() == 2, "two remaining in queue")
	expect(mgr._queue[0] == "second", "second is next in queue")
	expect(mgr._queue[1] == "third", "third is last in queue")

func _test_busy_flag_prevents_double_show() -> void:
	print("busy flag: prevents concurrent shows")
	var mgr := FakeNotifManager.new()
	mgr.push("first")
	expect(mgr._busy == true, "busy after first push")
	var count_before := mgr._show_call_count
	mgr.push("second")
	# _show_next should NOT be called again because _busy is true
	expect(mgr._show_call_count == count_before, "_show_next not called again while busy")

func _test_queue_drains_in_order() -> void:
	print("queue drains in FIFO order")
	var mgr := FakeNotifManager.new()
	mgr.push("A")
	mgr.push("B")
	mgr.push("C")
	# A shown immediately
	expect(mgr._showing == "A", "showing A first")
	mgr.finish_current()
	expect(mgr._showing == "B", "showing B after A finishes")
	mgr.finish_current()
	expect(mgr._showing == "C", "showing C after B finishes")
	mgr.finish_current()
	expect(mgr._busy == false, "busy cleared after queue empty")

func _test_empty_queue_clears_busy() -> void:
	print("_show_next on empty queue clears busy flag")
	var mgr := FakeNotifManager.new()
	mgr.push("only one")
	mgr.finish_current()
	expect(mgr._busy == false, "busy is false after queue empties")
	expect(mgr._queue.is_empty(), "queue is empty")

func _test_push_while_busy_queues() -> void:
	print("push while busy does not trigger immediate show")
	var mgr := FakeNotifManager.new()
	mgr.push("msg1")
	var count := mgr._show_call_count
	mgr.push("msg2")
	mgr.push("msg3")
	expect(mgr._show_call_count == count, "no additional _show_next calls while busy")
	expect(mgr._queue.size() == 2, "both new messages queued")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
