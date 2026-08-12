## Records per-frame input and plays it back deterministically.
##
## Recording input rather than positions is what makes a replay small and a bug
## reproducible: you keep the *causes*, then re-run the same simulation over
## them. The same recording drives a demo attract mode, a ghost car, and a
## regression test that replays the exact sequence that broke something.
##
## Determinism is the whole contract, and it costs discipline elsewhere: replay
## only reproduces the original run if the simulation is fed a fixed delta and
## uses a seeded RNG. Anything reading wall-clock time or unseeded randomness
## will drift.
class_name InputRecorder
extends RefCounted

enum Mode { IDLE, RECORDING, REPLAYING }

## Replay reached the end of the recording.
signal replay_finished

var mode: Mode = Mode.IDLE

## One entry per recorded frame: the set of actions held that frame.
var _frames: Array[Dictionary] = []
var _frame := 0

## The actions this recorder tracks. Anything outside this list is not captured.
var actions: PackedStringArray = PackedStringArray()

func _init(tracked_actions: PackedStringArray = PackedStringArray()) -> void:
	actions = tracked_actions

func start_recording() -> void:
	_frames.clear()
	_frame = 0
	mode = Mode.RECORDING

func start_replay() -> void:
	if _frames.is_empty():
		return
	_frame = 0
	mode = Mode.REPLAYING

func stop() -> void:
	mode = Mode.IDLE
	_frame = 0

func frame_count() -> int:
	return _frames.size()

func current_frame() -> int:
	return _frame

func is_recording() -> bool:
	return mode == Mode.RECORDING

func is_replaying() -> bool:
	return mode == Mode.REPLAYING

## Capture this frame's input. Pass a snapshot so the caller decides where the
## values come from — Input in a real game, a fixture in a test.
func record_frame(state: Dictionary) -> void:
	if mode != Mode.RECORDING:
		return
	var frame: Dictionary = {}
	for action in actions:
		frame[action] = bool(state.get(action, false))
	_frames.append(frame)
	_frame += 1

## Take a snapshot straight from Input. Convenience for the common case.
func record_from_input() -> void:
	if mode != Mode.RECORDING:
		return
	var state: Dictionary = {}
	for action in actions:
		state[action] = Input.is_action_pressed(action)
	record_frame(state)

## The input for the current replay frame, then advance. Returns {} and emits
## replay_finished once the recording runs out.
func next_frame() -> Dictionary:
	if mode != Mode.REPLAYING:
		return {}
	if _frame >= _frames.size():
		mode = Mode.IDLE
		replay_finished.emit()
		return {}
	var frame: Dictionary = _frames[_frame]
	_frame += 1
	return frame.duplicate()

## Read input from whichever source is active: the recording during replay,
## otherwise live input (recording it on the way past).
func poll(live_state: Dictionary) -> Dictionary:
	if mode == Mode.REPLAYING:
		return next_frame()
	if mode == Mode.RECORDING:
		record_frame(live_state)
	return live_state

## Serialise to something JSON can hold. Frames are stored as the list of
## actions held, which compresses well because most frames hold nothing.
func to_dict() -> Dictionary:
	var frames: Array = []
	for frame in _frames:
		var held: Array = []
		for action in actions:
			if bool(frame.get(action, false)):
				held.append(action)
		frames.append(held)
	return {"actions": Array(actions), "frames": frames}

func from_dict(data: Dictionary) -> void:
	actions = PackedStringArray(data.get("actions", []))
	_frames.clear()
	for held in data.get("frames", []):
		var frame: Dictionary = {}
		for action in actions:
			frame[action] = held.has(action)
		_frames.append(frame)
	_frame = 0
	mode = Mode.IDLE
