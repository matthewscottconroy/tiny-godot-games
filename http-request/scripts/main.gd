extends Control

@onready var _fetch_btn: Button      = $VBox/FetchButton
@onready var _status_label: Label    = $VBox/StatusLabel
@onready var _result_label: Label    = $VBox/ResultLabel
@onready var _http: HTTPRequest      = $HTTPRequest

const URL := "https://jsonplaceholder.typicode.com/todos/1"

func _ready() -> void:
	_http.request_completed.connect(_on_response)
	_fetch_btn.pressed.connect(_fetch)
	_result_label.text = "(no data yet)"

func _fetch() -> void:
	_fetch_btn.disabled = true
	_status_label.text = "Fetching..."
	var err := _http.request(URL)
	if err != OK:
		_status_label.text = "Request failed to start: error %d" % err
		_fetch_btn.disabled = false

func _on_response(
		result: int,
		code: int,
		_headers: PackedStringArray,
		body: PackedByteArray) -> void:

	_fetch_btn.disabled = false

	if result != HTTPRequest.RESULT_SUCCESS:
		_status_label.text = "Network error: result=%d" % result
		return

	if code != 200:
		_status_label.text = "HTTP %d (non-200 response)" % code
		return

	var json := JSON.new()
	var parse_err := json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		_status_label.text = "JSON parse error (line %d)" % json.get_error_line()
		return

	var data: Dictionary = json.get_data()
	_status_label.text = "HTTP %d — OK" % code
	_result_label.text = (
		"ID:        %s\nTitle:     %s\nCompleted: %s\nUser ID:   %s"
		% [
			str(data.get("id", "?")),
			str(data.get("title", "?")),
			str(data.get("completed", "?")),
			str(data.get("userId", "?")),
		]
	)
