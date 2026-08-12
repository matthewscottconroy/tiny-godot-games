extends Node

# Drives the real SaveSystem from scripts/save_system.gd rather than calling
# FileAccess and JSON directly, so the file handling is covered too.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_round_trip_basic()
	test_round_trip_nested()
	test_round_trip_preserves_types()
	test_missing_key_fallback()
	test_has_save()
	test_load_without_file_returns_empty()
	test_load_of_corrupt_file_returns_empty()
	test_save_overwrites()
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

# Each test starts from a clean slate so ordering never matters.
func _make() -> SaveSystem:
	_cleanup()
	return SaveSystem.new(TEST_PATH)

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))

# --- tests ---

func test_round_trip_basic() -> void:
	var sys := _make()
	sys.save({"score": 42, "level": 3})
	var back := sys.load()
	expect(back.get("score") == 42, "score survives the save/load round-trip")
	expect(back.get("level") == 3,  "level survives the save/load round-trip")
	_cleanup()

func test_round_trip_nested() -> void:
	var sys := _make()
	sys.save({"player": {"hp": 80, "name": "Hero"}})
	var player: Dictionary = sys.load().get("player", {})
	expect(player.get("hp") == 80,      "nested hp survives")
	expect(player.get("name") == "Hero", "nested name survives")
	_cleanup()

func test_round_trip_preserves_types() -> void:
	var sys := _make()
	sys.save({"alive": true, "coins": 7, "ratio": 0.75})
	var back := sys.load()
	expect(back.get("alive") == true, "bool true preserved")
	expect(back.get("coins") == 7,    "int preserved")
	expect(is_equal_approx(back.get("ratio", 0.0), 0.75), "float preserved")
	_cleanup()

func test_missing_key_fallback() -> void:
	var sys := _make()
	sys.save({"score": 10})
	expect(sys.load().get("level", 1) == 1, "missing key returns the provided default")
	_cleanup()

func test_has_save() -> void:
	var sys := _make()
	expect(not sys.has_save(), "has_save is false before anything is written")
	sys.save({"a": 1})
	expect(sys.has_save(), "has_save is true once the file exists")
	_cleanup()
	expect(not sys.has_save(), "has_save is false again after the file is removed")

func test_load_without_file_returns_empty() -> void:
	var sys := _make()
	expect(sys.load().is_empty(), "loading with no save file returns an empty dictionary")

func test_load_of_corrupt_file_returns_empty() -> void:
	var sys := _make()
	# has_save() is what distinguishes "no file" from "unreadable file".
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()
	expect(sys.has_save(), "the corrupt file exists")
	expect(sys.load().is_empty(), "unparseable JSON loads as an empty dictionary")
	_cleanup()

func test_save_overwrites() -> void:
	var sys := _make()
	sys.save({"score": 1, "stale": true})
	sys.save({"score": 2})
	var back := sys.load()
	expect(back.get("score") == 2, "the second save wins")
	expect(not back.has("stale"), "save replaces the file rather than merging into it")
	_cleanup()
