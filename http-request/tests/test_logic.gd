extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_json_parse_sample_data()
	_test_result_label_format()
	_test_error_code_mapping()
	_test_url_non_empty()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# ---- helpers ----

const URL := "https://jsonplaceholder.typicode.com/todos/1"

const SAMPLE_JSON := '{"userId":1,"id":1,"title":"delectus aut autem","completed":false}'

func _format_result(data: Dictionary) -> String:
	return (
		"ID:        %s\nTitle:     %s\nCompleted: %s\nUser ID:   %s"
		% [
			str(data.get("id", "?")),
			str(data.get("title", "?")),
			str(data.get("completed", "?")),
			str(data.get("userId", "?")),
		]
	)

# ---- tests ----

func _test_json_parse_sample_data() -> void:
	print("JSON parse of sample todo response")
	var json := JSON.new()
	var err := json.parse(SAMPLE_JSON)
	expect(err == OK, "parse returns OK")
	var data: Dictionary = json.get_data()
	expect(data.has("id"), "data has 'id'")
	expect(data.has("title"), "data has 'title'")
	expect(data.has("completed"), "data has 'completed'")
	expect(data.has("userId"), "data has 'userId'")
	expect(data["id"] == 1, "id == 1")
	expect(data["title"] == "delectus aut autem", "title matches")
	expect(data["completed"] == false, "completed is false")

func _test_result_label_format() -> void:
	print("result label formatting with mock data")
	var json := JSON.new()
	json.parse(SAMPLE_JSON)
	var data: Dictionary = json.get_data()
	var text := _format_result(data)
	expect(text.contains("ID:"), "text contains 'ID:'")
	expect(text.contains("Title:"), "text contains 'Title:'")
	expect(text.contains("Completed:"), "text contains 'Completed:'")
	expect(text.contains("User ID:"), "text contains 'User ID:'")
	expect(text.contains("delectus aut autem"), "text contains the title value")

func _test_error_code_mapping() -> void:
	print("error code mapping")
	# HTTPRequest.RESULT_SUCCESS == 0 in Godot 4
	expect(HTTPRequest.RESULT_SUCCESS == 0, "RESULT_SUCCESS is 0")
	# Non-zero result indicates an error
	expect(HTTPRequest.RESULT_CANT_CONNECT != 0, "RESULT_CANT_CONNECT is non-zero")
	expect(HTTPRequest.RESULT_NO_RESPONSE != 0, "RESULT_NO_RESPONSE is non-zero")
	expect(HTTPRequest.RESULT_CONNECTION_ERROR != 0, "RESULT_CONNECTION_ERROR is non-zero")

func _test_url_non_empty() -> void:
	print("URL constant is valid")
	expect(URL.length() > 0, "URL is non-empty")
	expect(URL.begins_with("https://"), "URL starts with https://")
	expect(URL.contains("jsonplaceholder"), "URL targets jsonplaceholder")

func _report() -> void:
	var summary := "[http-request] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
