extends Node

# Drives the real NotificationQueue from scripts/notification_manager.gd via the
# demo scene (the component needs its NotifPanel/Label children).

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_first_push_shows_immediately()
	_test_further_pushes_queue()
	_test_queue_drains_in_order()
	_test_empty_queue_clears_busy()
	_test_tween_timings_come_from_exports()
	_test_only_a_fresh_key_press_queues_a_notice()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _make() -> NotificationQueue:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene.get_node("NotifManager")

# The slide-in/hold/slide-out chain ends by calling _show_next again. Driving
# that directly keeps the test synchronous instead of waiting on real tweens.
func _finish_current(notif: NotificationQueue) -> void:
	notif._show_next()

func _test_first_push_shows_immediately() -> void:
	print("first push shows immediately")
	var notif := _make()
	notif.push("A")
	expect(notif._busy, "the manager is busy after the first push")
	expect(notif._queue.is_empty(), "the first message is shown rather than queued")
	expect(notif._label.text == "A", "the panel label shows the message")

func _test_further_pushes_queue() -> void:
	print("further pushes queue up")
	var notif := _make()
	notif.push("A")
	notif.push("B")
	notif.push("C")
	expect(notif._queue.size() == 2, "two messages are waiting behind the visible one")
	expect(notif._queue[0] == "B", "B is next in the queue")
	expect(notif._queue[1] == "C", "C is last in the queue")
	expect(notif._label.text == "A", "the visible message is unchanged while busy")

func _test_queue_drains_in_order() -> void:
	print("queue drains FIFO")
	var notif := _make()
	notif.push("A")
	notif.push("B")
	notif.push("C")
	expect(notif._label.text == "A", "showing A first")
	_finish_current(notif)
	expect(notif._label.text == "B", "showing B after A finishes")
	_finish_current(notif)
	expect(notif._label.text == "C", "showing C after B finishes")

func _test_empty_queue_clears_busy() -> void:
	print("busy clears when the queue empties")
	var notif := _make()
	notif.push("only")
	_finish_current(notif)
	expect(not notif._busy, "busy is false after the queue empties")
	expect(notif._queue.is_empty(), "the queue is empty")
	# A later push must start the cycle again rather than sit forever.
	notif.push("later")
	expect(notif._busy and notif._label.text == "later", "a push after draining shows immediately")

func _test_tween_timings_come_from_exports() -> void:
	print("timings are configurable")
	var notif := _make()
	expect(notif.slide_in_time > 0.0, "slide_in_time has a usable default")
	expect(notif.show_time > notif.slide_in_time, "messages hold longer than they take to arrive")
	expect(notif.slide_out_time > 0.0, "slide_out_time has a usable default")

## One notice per physical press.
##
## The handler filters on the press *and* on the auto-repeat. Drop either and
## holding 1 queues a notice every frame, which is a screen that never stops
## sliding — and the demo's own comment promises exactly the opposite.
func _test_only_a_fresh_key_press_queues_a_notice() -> void:
	print("the keys")
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	var notif: NotificationQueue = scene.get_node("NotifManager")

	scene._unhandled_key_input(_key(KEY_1, false, false))
	expect(not notif._busy, "a key coming back up queues nothing")

	scene._unhandled_key_input(_key(KEY_1, true, true))
	expect(not notif._busy, "nor does an auto-repeat")

	scene._unhandled_key_input(_key(KEY_9, true, false))
	expect(not notif._busy, "nor a key the demo does not use")

	scene._unhandled_key_input(_key(KEY_1, true, false))
	expect(notif._busy, "while a fresh press does")
	expect(notif._label.text != "", "showing a message (%s)" % notif._label.text)

	# Held down, it stays at one: the repeats after the first press are echoes.
	var first: String = notif._label.text
	for i in 30:
		scene._unhandled_key_input(_key(KEY_1, true, true))
	expect(notif._queue.is_empty(),
		"holding the key queues nothing behind it (%d waiting)" % notif._queue.size())
	expect(notif._label.text == first, "and the message on screen does not change")

	# Each of the four keys says something different.
	var seen := {}
	for code in [KEY_1, KEY_2, KEY_3, KEY_4]:
		var fresh: Node = load("res://scenes/main.tscn").instantiate()
		add_child(fresh)
		fresh._unhandled_key_input(_key(code, true, false))
		var text: String = (fresh.get_node("NotifManager") as NotificationQueue)._label.text
		seen[text] = true
		fresh.queue_free()
	expect(seen.size() == 4, "the four keys push four different notices (%d)" % seen.size())

	scene.queue_free()

func _key(code: Key, pressed: bool, echo: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	return event

func _report() -> void:
	var summary := "[notification-queue] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
