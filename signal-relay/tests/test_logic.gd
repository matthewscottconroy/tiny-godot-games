extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_signal_relay_pattern()
	_test_message_received()
	_test_multiple_receivers()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_signal_relay_pattern() -> void:
	print("signal relay: transmitter emits, receiver catches")
	var received := false
	var message_sent_handlers := []
	message_sent_handlers.append(func(msg: String): received = true)
	for handler in message_sent_handlers:
		handler.call("hello")
	expect(received, "receiver called when signal emitted")

func _test_message_received() -> void:
	print("relay passes message content to receiver")
	var received_msg := ""
	var handler := func(msg: String): received_msg = msg
	handler.call("ping from transmitter")
	expect(received_msg == "ping from transmitter", "message content relayed correctly")

func _test_multiple_receivers() -> void:
	print("multiple receivers all get signal")
	var count := 0
	var handlers := [
		func(_m: String): count += 1,
		func(_m: String): count += 1,
	]
	for h in handlers:
		h.call("test")
	expect(count == 2, "both receivers notified")

func _report() -> void:
	var summary := "[signal-relay] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
