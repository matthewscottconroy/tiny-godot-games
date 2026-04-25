extends Control

signal finished

const CHARS_PER_SEC := 28.0

var _lines    : Array[String] = []
var _speakers : Array[String] = []
var _index    := 0
var _typing   := false

@onready var speaker_label : Label  = $Panel/VBox/SpeakerLabel
@onready var text_label    : Label  = $Panel/VBox/TextLabel
@onready var next_btn      : Button = $Panel/NextBtn

func _ready() -> void:
	next_btn.pressed.connect(_advance)
	hide()

func start(lines: Array[String], speakers: Array[String] = []) -> void:
	_lines    = lines
	_speakers = speakers
	_index    = 0
	show()
	_show_line(0)

func _show_line(i: int) -> void:
	if i >= _lines.size():
		hide()
		finished.emit()
		return
	speaker_label.text = _speakers[i] if i < _speakers.size() else ""
	text_label.text    = ""
	next_btn.disabled  = true
	_typing = true
	_type_out.call_deferred(_lines[i])

func _type_out(full: String) -> void:
	for i in full.length():
		if not _typing:
			text_label.text = full
			break
		text_label.text = full.left(i + 1)
		await get_tree().create_timer(1.0 / CHARS_PER_SEC).timeout
	_typing = false
	next_btn.disabled = false

func _advance() -> void:
	if _typing:
		_typing = false
	else:
		_index += 1
		_show_line(_index)
