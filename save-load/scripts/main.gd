extends Control

## Demo driver: a tiny form (name + score) plus Save/Load buttons. All file I/O
## is delegated to SaveSystem (scripts/save_system.gd); this script only builds
## the payload dictionary and reports status.

const SAVE_PATH := "user://save.json"

var _save := SaveSystem.new(SAVE_PATH)

@onready var name_input: LineEdit   = $Fields/NameRow/NameInput
@onready var score_input: LineEdit  = $Fields/ScoreRow/ScoreInput
@onready var status_label: Label    = $StatusLabel
@onready var load_display: Label    = $LoadDisplay

func _ready() -> void:
	$Fields/BtnRow/SaveBtn.pressed.connect(_on_save)
	$Fields/BtnRow/LoadBtn.pressed.connect(_on_load)
	$Fields/ScoreRow/IncrBtn.pressed.connect(_on_incr)
	_refresh_file_status()

func _on_save() -> void:
	_save.save({
		"player_name": name_input.text,
		"score":       int(score_input.text) if score_input.text.is_valid_int() else 0,
		"timestamp":   Time.get_datetime_string_from_system(),
	})
	status_label.text = "Saved to %s" % _save.path
	status_label.modulate = Color.LIME_GREEN

func _on_load() -> void:
	if not _save.has_save():
		status_label.text = "No save file found at %s" % _save.path
		status_label.modulate = Color.TOMATO
		return

	var data := _save.load()
	if data.is_empty():
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
	if _save.has_save():
		status_label.text = "Save file exists at %s" % _save.path
	else:
		status_label.text = "No save file yet. Fill in fields and press Save."
