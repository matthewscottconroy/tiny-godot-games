extends Node2D

# Demo driver. Fires speech and sound cues into the queue so the queuing
# behaviour — one caption at a time, the rest waiting — is visible.

@onready var _subs: SubtitleQueue = $Subtitles
@onready var _caption: Label = $HUD/CaptionLabel
@onready var _status: Label = $HUD/StatusLabel
@onready var _hint: Label = $HUD/HintLabel

const LINES := [
	{"speaker": "Guard", "text": "Halt! You there — state your business."},
	{"speaker": "You", "text": "Just passing through."},
	{"speaker": "Guard", "text": "Nobody just passes through here. Not since the bridge came down."},
]

var _next_line := 0

func _ready() -> void:
	_subs.caption_shown.connect(func(_e: Dictionary) -> void: _refresh())
	_subs.caption_hidden.connect(func(_e: Dictionary) -> void: _refresh())
	_hint.text = "1 speak a line   2 burst all three   3 sound cue   C toggle cues   S skip   X clear"
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1:
			var line: Dictionary = LINES[_next_line % LINES.size()]
			_next_line += 1
			_subs.say(String(line["text"]), String(line["speaker"]))
		KEY_2:
			for line in LINES:
				_subs.say(String(line["text"]), String(line["speaker"]))
		KEY_3:
			_subs.cue("a door opens behind you")
		KEY_C:
			_subs.sound_cues = not _subs.sound_cues
		KEY_S:
			_subs.skip()
		KEY_X:
			_subs.clear()
	_refresh()

func _process(delta: float) -> void:
	_subs.update(delta)
	_refresh()
	queue_redraw()

func _refresh() -> void:
	_caption.text = _subs.current_text()
	var entry := _subs.current()
	_caption.modulate = Color(0.75, 0.85, 1.0) if entry.get("is_cue", false) else Color.WHITE
	_status.text = "showing: %s    queued: %d    sound cues: %s" % [
		"yes" if _subs.is_showing() else "no",
		_subs.pending(),
		"on" if _subs.sound_cues else "off",
	]

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
	# A stand-in scene so the caption band has something to sit over.
	draw_rect(Rect2(0, 300, 640, 180), Color(0.13, 0.15, 0.19))
	draw_circle(Vector2(240, 270), 34, Color(0.35, 0.55, 0.85))
	draw_circle(Vector2(400, 270), 34, Color(0.75, 0.45, 0.35))
	# The caption band: a solid backing is what makes captions readable over art.
	if _subs.is_showing():
		draw_rect(Rect2(50, 370, 540, 70), Color(0, 0, 0, 0.65))
	# Queue depth, one pip per waiting caption.
	for i in _subs.pending():
		draw_rect(Rect2(50 + i * 14, 356, 10, 6), Color(0.85, 0.9, 0.6))
