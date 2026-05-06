extends CanvasLayer

@onready var _panel: PanelContainer = $NotifPanel
@onready var _label: Label = $NotifPanel/Label

var _queue: Array[String] = []
var _busy := false

const SLIDE_IN_TIME := 0.2
const SHOW_TIME := 2.0
const SLIDE_OUT_TIME := 0.15
const SHOW_X := 390.0
const HIDE_X := 660.0

func push(msg: String) -> void:
	_queue.append(msg)
	if not _busy:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_busy = false
		return

	_busy = true
	_label.text = _queue.pop_front()
	_panel.position = Vector2(HIDE_X, 20.0)

	var tw := create_tween()
	tw.tween_property(_panel, "position:x", SHOW_X, SLIDE_IN_TIME)
	tw.tween_interval(SHOW_TIME)
	tw.tween_property(_panel, "position:x", HIDE_X, SLIDE_OUT_TIME)
	tw.tween_callback(_show_next)
