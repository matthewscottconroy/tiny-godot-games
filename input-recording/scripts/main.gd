extends Node2D

# Demo driver. Record a run of the square, then replay it and watch the ghost
# retrace the identical path.

const ACTIONS := ["ui_left", "ui_right", "ui_up", "ui_down"]
const SPEED := 220.0
const START := Vector2(320, 260)
# Replay only reproduces the original if the simulation is fed a fixed step.
const STEP := 1.0 / 60.0

@onready var _status: Label = $HUD/StatusLabel
@onready var _hint: Label = $HUD/HintLabel

var _rec: InputRecorder
var _pos := START
var _trail: PackedVector2Array = PackedVector2Array()
var _recorded_trail: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	_rec = InputRecorder.new(PackedStringArray(ACTIONS))
	_rec.replay_finished.connect(func() -> void: _refresh())
	_hint.text = "Arrow keys move   R record   P replay   S stop"
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_R:
			_pos = START
			_trail = PackedVector2Array()
			_rec.start_recording()
		KEY_P:
			_pos = START
			_recorded_trail = _trail
			_trail = PackedVector2Array()
			_rec.start_replay()
		KEY_S:
			_rec.stop()
	_refresh()

func _physics_process(_delta: float) -> void:
	var live: Dictionary = {}
	for action in ACTIONS:
		live[action] = Input.is_action_pressed(action)

	var state := _rec.poll(live)
	var dir := Vector2(
		(1.0 if state.get("ui_right", false) else 0.0) - (1.0 if state.get("ui_left", false) else 0.0),
		(1.0 if state.get("ui_down", false) else 0.0) - (1.0 if state.get("ui_up", false) else 0.0),
	)
	# STEP, not delta: a replay fed variable timing drifts away from the original.
	_pos += dir.normalized() * SPEED * STEP
	_pos = _pos.clamp(Vector2(30, 90), Vector2(610, 420))

	if _rec.is_recording() or _rec.is_replaying():
		_trail.append(_pos)
	_refresh()
	queue_redraw()

func _refresh() -> void:
	var mode := "idle"
	if _rec.is_recording():
		mode = "RECORDING"
	elif _rec.is_replaying():
		mode = "REPLAYING"
	_status.text = "%s    frames: %d    replay position: %d" % [
		mode, _rec.frame_count(), _rec.current_frame()]

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
	if _recorded_trail.size() > 1:
		draw_polyline(_recorded_trail, Color(0.4, 0.45, 0.55), 2.0)
	if _trail.size() > 1:
		var col := Color(0.9, 0.35, 0.35) if _rec.is_recording() else Color(0.35, 0.8, 0.5)
		draw_polyline(_trail, col, 2.0)
	var body := Color(0.9, 0.35, 0.35) if _rec.is_recording() else \
		(Color(0.35, 0.8, 0.5) if _rec.is_replaying() else Color(0.45, 0.55, 0.75))
	draw_rect(Rect2(_pos - Vector2(12, 12), Vector2(24, 24)), body)
