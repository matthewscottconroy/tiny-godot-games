extends Node

# Drives the real transmitter and receiver from scenes/main.tscn — see
# docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_receiver_starts_with_placeholder_text()
	_test_pressing_the_button_sends_a_message()
	_test_the_message_reaches_the_receiver()
	_test_the_two_nodes_do_not_know_each_other()
	_test_the_receiver_takes_whatever_it_is_given()
	_test_each_press_sends_a_fresh_message()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[signal-relay] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Control:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _transmitter(m: Control) -> Button:
	return m.get_node("Transmitter")

func _receiver(m: Control) -> Label:
	return m.get_node("Receiver")

func _test_the_receiver_starts_with_placeholder_text() -> void:
	print("before pressing")
	var m := _make()
	expect(not _receiver(m).text.contains("Signal received"),
		"the receiver has not been sent anything yet")

func _test_pressing_the_button_sends_a_message() -> void:
	print("transmitting")
	var m := _make()
	var heard := {"text": ""}
	_transmitter(m).message_sent.connect(func(t: String): heard["text"] = t)
	_transmitter(m).pressed.emit()
	expect(heard["text"].length() > 0, "pressing the button emits a message")

func _test_the_message_reaches_the_receiver() -> void:
	print("relaying")
	var m := _make()
	_transmitter(m).pressed.emit()
	expect(_receiver(m).text.contains("Signal received"),
		"the receiver shows what the transmitter sent")

func _test_the_two_nodes_do_not_know_each_other() -> void:
	print("who knows whom")
	var m := _make()
	# The point of the demo: the wiring lives in main.gd, so neither node
	# names the other and either could be swapped out on its own.
	var transmitter_source: String = _transmitter(m).get_script().source_code
	var receiver_source: String = _receiver(m).get_script().source_code
	expect(not transmitter_source.contains("Receiver"), "the transmitter never mentions the receiver")
	expect(not receiver_source.contains("Transmitter"), "nor the receiver the transmitter")
	expect(m.get_script().source_code.contains("message_sent"),
		"the connection is made by the parent that owns them both")

func _test_the_receiver_takes_whatever_it_is_given() -> void:
	print("the receiver")
	var m := _make()
	_receiver(m).receive("anything at all")
	expect(_receiver(m).text == "anything at all", "the receiver displays the text it is handed")

func _test_each_press_sends_a_fresh_message() -> void:
	print("repeat presses")
	var m := _make()
	var messages: Array[String] = []
	_transmitter(m).message_sent.connect(func(t: String): messages.append(t))
	for i in 3:
		_transmitter(m).pressed.emit()
	expect(messages.size() == 3, "three presses send three messages")
	expect(_receiver(m).text == messages[2], "and the receiver shows the most recent")
