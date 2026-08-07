## A FIFO notification manager. Call push(msg) any number of times; messages are
## shown one at a time, each sliding in, holding, then sliding out before the
## next begins. Self-contained — copy this node (script + its Panel child).
class_name NotificationQueue
extends CanvasLayer

@onready var _panel: PanelContainer = $NotifPanel
@onready var _label: Label = $NotifPanel/Label

var _queue: Array[String] = []
var _busy := false

@export var slide_in_time := 0.2    ## seconds to slide a message on-screen
@export var show_time := 2.0        ## seconds a message stays visible
@export var slide_out_time := 0.15  ## seconds to slide it back off

const SHOW_X := 390.0   # on-screen X of the panel
const HIDE_X := 660.0   # off-screen X (parked to the right)

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
	tw.tween_property(_panel, "position:x", SHOW_X, slide_in_time)
	tw.tween_interval(show_time)
	tw.tween_property(_panel, "position:x", HIDE_X, slide_out_time)
	tw.tween_callback(_show_next)
