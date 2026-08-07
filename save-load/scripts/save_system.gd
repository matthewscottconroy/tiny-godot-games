## Persists a Dictionary to a JSON file (under user:// by default).
##
## Godot maps user:// to an OS-specific, per-app data directory, so saves
## survive between runs without the project folder needing to be writable.
## JSON keeps the file human-readable and debuggable.
class_name SaveSystem
extends RefCounted

var path := "user://save.json"

func _init(save_path := "user://save.json") -> void:
	path = save_path

## True if a save file currently exists.
func has_save() -> bool:
	return FileAccess.file_exists(path)

## Write `data` as pretty-printed JSON, overwriting any existing file.
func save(data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

## Read and parse the save file. Returns {} if it is missing or not valid JSON,
## so callers can check `has_save()` first to tell "no file" from "bad file".
func load() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}
