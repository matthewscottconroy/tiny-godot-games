extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_json_round_trip_basic()
	test_json_round_trip_nested()
	test_json_round_trip_preserves_types()
	test_missing_key_fallback()
	test_save_and_load_file()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[save-load] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const TEST_PATH := "user://test_save_temp.json"

func _serialize(data: Dictionary) -> String:
	return JSON.stringify(data)

func _deserialize(text: String) -> Dictionary:
	var result := JSON.parse_string(text)
	return result if result is Dictionary else {}

# --- tests ---

func test_json_round_trip_basic() -> void:
	var data := {"score": 42, "level": 3}
	var text  := _serialize(data)
	var back  := _deserialize(text)
	expect(back.get("score") == 42, "score survives JSON round-trip")
	expect(back.get("level") == 3,  "level survives JSON round-trip")

func test_json_round_trip_nested() -> void:
	var data := {"player": {"hp": 80, "name": "Hero"}}
	var text  := _serialize(data)
	var back  := _deserialize(text)
	var player : Dictionary = back.get("player", {})
	expect(player.get("hp")   == 80,     "nested hp survives")
	expect(player.get("name") == "Hero", "nested name survives")

func test_json_round_trip_preserves_types() -> void:
	var data := {"alive": true, "coins": 7, "ratio": 0.75}
	var back  := _deserialize(_serialize(data))
	expect(back.get("alive") == true,  "bool true preserved")
	expect(back.get("coins") == 7,     "int preserved")
	expect(is_equal_approx(back.get("ratio", 0.0), 0.75), "float preserved")

func test_missing_key_fallback() -> void:
	var back := _deserialize('{"score": 10}')
	expect(back.get("level", 1) == 1, "missing key returns provided default")

func test_save_and_load_file() -> void:
	var data := {"test_run": true, "value": 99}
	# Write
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	expect(file != null, "file opened for writing")
	if file:
		file.store_string(_serialize(data))
		file.close()
	# Read back
	var rfile := FileAccess.open(TEST_PATH, FileAccess.READ)
	expect(rfile != null, "file opened for reading")
	if rfile:
		var back := _deserialize(rfile.get_as_text())
		rfile.close()
		expect(back.get("value") == 99, "value 99 read back from file")
	# Cleanup
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
