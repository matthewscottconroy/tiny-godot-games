extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_signal_relay_pattern()
	_test_message_received()
	_test_multiple_receivers()
	_test_disconnect_stops_delivery()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# --- Stand-ins for the demo's three nodes ---
#
# The demo wires $Transmitter.message_sent -> $Receiver.receive from main.gd, so
# neither node knows about the other. These classes mirror that shape without
# needing a Button or a Label on screen.
#
# Note these are real signals, not stored Callables: GDScript lambdas capture
# locals by value, so a lambda writing to a captured `bool` would leave the
# original untouched and the test would pass or fail for the wrong reason.

class Transmitter extends Node:
	signal message_sent(text: String)

	func send(text: String) -> void:
		message_sent.emit(text)

class Receiver extends Node:
	var text := ""
	var call_count := 0

	func receive(msg: String) -> void:
		text = msg
		call_count += 1

func _test_signal_relay_pattern() -> void:
	print("signal relay: transmitter emits, receiver catches")
	var tx := Transmitter.new()
	var rx := Receiver.new()
	tx.message_sent.connect(rx.receive)
	tx.send("hello")
	expect(rx.call_count == 1, "receiver called when signal emitted")

func _test_message_received() -> void:
	print("relay passes message content to receiver")
	var tx := Transmitter.new()
	var rx := Receiver.new()
	tx.message_sent.connect(rx.receive)
	tx.send("ping from transmitter")
	expect(rx.text == "ping from transmitter", "message content relayed correctly")

func _test_multiple_receivers() -> void:
	print("multiple receivers all get signal")
	var tx := Transmitter.new()
	var a := Receiver.new()
	var b := Receiver.new()
	tx.message_sent.connect(a.receive)
	tx.message_sent.connect(b.receive)
	tx.send("test")
	expect(a.call_count == 1 and b.call_count == 1, "both receivers notified")

func _test_disconnect_stops_delivery() -> void:
	print("disconnecting stops delivery")
	var tx := Transmitter.new()
	var rx := Receiver.new()
	tx.message_sent.connect(rx.receive)
	tx.send("first")
	tx.message_sent.disconnect(rx.receive)
	tx.send("second")
	expect(rx.call_count == 1, "no further calls after disconnect")
	expect(rx.text == "first", "receiver still holds the last delivered message")

func _report() -> void:
	var summary := "[signal-relay] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
