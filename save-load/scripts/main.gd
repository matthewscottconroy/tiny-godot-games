extends Control

const SAVE_PATH := "user://save.json"

@onready var name_input: LineEdit   = $Fields/NameRow/NameInput
@onready var score_input: LineEdit  = $Fields/ScoreRow/ScoreInput
@onready var status_label: Label    = $StatusLabel
@onready var load_display: Label    = $LoadDisplay

func _ready() -> void:
	$Fields/SaveBtn.pressed.connect(_on_save)
	$Fields/LoadBtn.pressed.connect(_on_load)
	$Fields/ScoreRow/IncrBtn.pressed.connect(_on_incr)
	_refresh_file_status()

func _on_save() -> void:
	var data := {
		"player_name": name_input.text,
		"score":       int(score_input.text) if score_input.text.is_valid_int() else 0,
		"timestamp":   Time.get_datetime_string_from_system(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	status_label.text = "Saved to %s" % SAVE_PATH
	status_label.modulate = Color.LIME_GREEN

func _on_load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		status_label.text = "No save file found at %s" % SAVE_PATH
		status_label.modulate = Color.TOMATO
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if not data is Dictionary:
		status_label.text = "Failed to parse save file."
		status_label.modulate = Color.TOMATO
		return

	name_input.text  = data.get("player_name", "")
	score_input.text = str(data.get("score", 0))
	status_label.text = "Loaded! Saved at: %s" % data.get("timestamp", "?")
	status_label.modulate = Color.CYAN
	load_display.text = "Raw JSON:\n" + JSON.stringify(data, "  ")

func _on_incr() -> void:
	var v := int(score_input.text) if score_input.text.is_valid_int() else 0
	score_input.text = str(v + 10)

func _refresh_file_status() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		status_label.text = "Save file exists at %s" % SAVE_PATH
	else:
		status_label.text = "No save file yet. Fill in fields and press Save."
