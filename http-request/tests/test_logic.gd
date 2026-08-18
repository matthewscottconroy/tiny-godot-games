extends Node

# Drives the real response handling from scenes/main.tscn — see
# docs/TEST_INTEGRITY.md.
#
# No request is ever sent: the network is not available in a test run, and a
# demo that only works online is a demo nobody can check. What is testable is
# everything after the reply arrives, so the suite hands the handler the
# replies a server would.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_starts_with_nothing_to_show()
	_test_a_good_response_is_read_out()
	_test_the_button_comes_back_after_a_reply()
	_test_a_network_failure_is_reported()
	_test_a_non_200_response_is_reported()
	_test_broken_json_is_reported()
	_test_missing_fields_do_not_break_the_readout()
	_test_a_failed_reply_leaves_the_old_data_alone()
	_test_the_url_is_a_real_https_address()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[http-request] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Control

func _make() -> Control:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

## Hand the demo the reply a server would send.
func _reply(m: Control, body: String, code: int = 200,
		result: int = HTTPRequest.RESULT_SUCCESS) -> void:
	m._on_response(result, code, PackedStringArray(), body.to_utf8_buffer())

const GOOD_BODY := '{"id": 1, "title": "delectus aut autem", "completed": false, "userId": 7}'

func _status(m: Control) -> String:
	return m._status_label.text

func _result(m: Control) -> String:
	return m._result_label.text

func _test_it_starts_with_nothing_to_show() -> void:
	print("before fetching")
	var m := _make()
	expect(_result(m).contains("no data"), "the readout says there is nothing yet")
	expect(not m._fetch_btn.disabled, "and the button is ready to press")

func _test_a_good_response_is_read_out() -> void:
	print("a good reply")
	var m := _make()
	_reply(m, GOOD_BODY)
	expect(_status(m).contains("200"), "the status names the code that came back")
	expect(_result(m).contains("delectus"), "the title is read out of the JSON")
	expect(_result(m).contains("7"), "and so is the user id")
	expect(_result(m).contains("false"), "including the fields that are false rather than missing")

func _test_the_button_comes_back_after_a_reply() -> void:
	print("the button")
	var m := _make()
	m._fetch_btn.disabled = true
	_reply(m, GOOD_BODY)
	expect(not m._fetch_btn.disabled, "a reply frees the button to fetch again")

	var failed := _make()
	failed._fetch_btn.disabled = true
	_reply(failed, "", 500)
	# Left disabled on failure, one bad reply would end the demo for good.
	expect(not failed._fetch_btn.disabled, "and so does a failed one")

func _test_a_network_failure_is_reported() -> void:
	print("no network")
	var m := _make()
	_reply(m, "", 0, HTTPRequest.RESULT_CANT_CONNECT)
	expect(_status(m).to_lower().contains("error"), "a connection failure says so")
	expect(not _status(m).contains("200"), "rather than claiming success")

func _test_a_non_200_response_is_reported() -> void:
	print("an error code")
	var m := _make()
	_reply(m, "not found", 404)
	expect(_status(m).contains("404"), "the status names the code the server sent")
	expect(_result(m).contains("no data"), "and no data is read out of it")

func _test_broken_json_is_reported() -> void:
	print("broken JSON")
	var m := _make()
	# A truncated reply is the usual way this goes wrong in practice.
	_reply(m, '{"id": 1, "title": "half a rep')
	expect(_status(m).to_lower().contains("json"), "a reply that will not parse says so")
	expect(_result(m).contains("no data"), "and nothing is read out of it")

func _test_missing_fields_do_not_break_the_readout() -> void:
	print("missing fields")
	var m := _make()
	_reply(m, '{"id": 3}')
	expect(_status(m).contains("200"), "a thin reply is still a good one")
	expect(_result(m).contains("3"), "the field that is there is shown")
	expect(_result(m).contains("?"), "and the ones that are not are marked rather than left blank")

func _test_a_failed_reply_leaves_the_old_data_alone() -> void:
	print("after a failure")
	var m := _make()
	_reply(m, GOOD_BODY)
	expect(_result(m).contains("delectus"), "some data is on screen")
	_reply(m, "", 503)
	# Wiping the readout on failure loses what the user was looking at.
	expect(_result(m).contains("delectus"), "a later failure leaves it there")
	expect(_status(m).contains("503"), "while the status explains what happened")

func _test_the_url_is_a_real_https_address() -> void:
	print("the address")
	var m := _make()
	expect(m.URL.begins_with("https://"), "the demo fetches over https")
	expect(m.URL.length() > 10, "from a real address")
