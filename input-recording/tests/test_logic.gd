extends Node

# Drives the real InputRecorder from scripts/input_recorder.gd.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_starts_idle()
	test_records_frames()
	test_only_tracked_actions_are_kept()
	test_replay_returns_the_same_frames()
	test_replay_ends_and_signals()
	test_poll_passes_live_input_through()
	test_poll_overrides_with_the_recording()
	test_replay_reproduces_the_simulation()
	test_round_trip_through_dict()
	test_start_recording_discards_the_old_take()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[input-recording] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const ACTIONS := ["left", "right", "jump"]

func _make() -> InputRecorder:
	return InputRecorder.new(PackedStringArray(ACTIONS))

func _state(held: Array) -> Dictionary:
	var s: Dictionary = {}
	for a in ACTIONS:
		s[a] = held.has(a)
	return s

# A scripted run: hold right for three frames, then jump.
const SCRIPTED := [[], ["right"], ["right"], ["right"], ["right", "jump"], []]

func _record_scripted(rec: InputRecorder) -> void:
	rec.start_recording()
	for held in SCRIPTED:
		rec.record_frame(_state(held))

func test_starts_idle() -> void:
	print("initial state")
	var r := _make()
	expect(not r.is_recording() and not r.is_replaying(), "starts idle")
	expect(r.frame_count() == 0, "no frames recorded")
	expect(r.next_frame().is_empty(), "next_frame does nothing while idle")

func test_records_frames() -> void:
	print("recording")
	var r := _make()
	_record_scripted(r)
	expect(r.is_recording(), "still recording until stopped")
	expect(r.frame_count() == SCRIPTED.size(), "one entry per frame")

func test_only_tracked_actions_are_kept() -> void:
	print("untracked actions are dropped")
	var r := _make()
	r.start_recording()
	r.record_frame({"right": true, "not_tracked": true})
	r.start_replay()
	var frame := r.next_frame()
	expect(frame.has("right"), "tracked actions are kept")
	expect(not frame.has("not_tracked"), "anything outside the tracked list is discarded")

func test_replay_returns_the_same_frames() -> void:
	print("replay returns what was recorded")
	var r := _make()
	_record_scripted(r)
	r.start_replay()
	var replayed: Array = []
	for i in SCRIPTED.size():
		var frame := r.next_frame()
		var held: Array = []
		for a in ACTIONS:
			if frame.get(a, false):
				held.append(a)
		replayed.append(held)
	expect(replayed == SCRIPTED, "every frame comes back identical, in order")

func test_replay_ends_and_signals() -> void:
	print("replay end")
	var r := _make()
	_record_scripted(r)
	var finished := {"n": 0}
	r.replay_finished.connect(func() -> void: finished["n"] += 1)
	r.start_replay()
	for i in SCRIPTED.size():
		r.next_frame()
	expect(finished["n"] == 0, "not finished while frames remain")
	expect(r.next_frame().is_empty(), "reading past the end returns nothing")
	expect(finished["n"] == 1, "replay_finished fires once")
	expect(not r.is_replaying(), "the recorder returns to idle")

func test_poll_passes_live_input_through() -> void:
	print("poll while idle")
	var r := _make()
	var live := _state(["jump"])
	expect(r.poll(live) == live, "idle poll hands back the live state unchanged")
	expect(r.frame_count() == 0, "and records nothing")

func test_poll_overrides_with_the_recording() -> void:
	print("poll while replaying")
	var r := _make()
	r.start_recording()
	r.record_frame(_state(["left"]))
	r.start_replay()
	# The live state says "right"; the replay must win.
	var got := r.poll(_state(["right"]))
	expect(got["left"] and not got["right"], "replay input replaces live input")

func test_replay_reproduces_the_simulation() -> void:
	print("the same recording produces the same run")
	# This is the property the whole component exists for.
	var r := _make()
	r.start_recording()
	for held in SCRIPTED:
		r.record_frame(_state(held))

	var positions_a := _simulate(r)
	var positions_b := _simulate(r)
	expect(positions_a == positions_b, "replaying twice produces an identical path")
	expect(positions_a[-1].x > positions_a[0].x, "and the path actually moved")

# Run a fixed-step simulation driven entirely by the recording.
func _simulate(r: InputRecorder) -> Array:
	r.start_replay()
	var pos := Vector2.ZERO
	var out: Array = []
	var frame := r.next_frame()
	while not frame.is_empty():
		var dx := (1.0 if frame.get("right", false) else 0.0) - (1.0 if frame.get("left", false) else 0.0)
		pos += Vector2(dx, -1.0 if frame.get("jump", false) else 0.0) * 10.0
		out.append(pos)
		frame = r.next_frame()
	return out

func test_round_trip_through_dict() -> void:
	print("serialisation")
	var r := _make()
	_record_scripted(r)
	var data := r.to_dict()

	var restored := InputRecorder.new()
	restored.from_dict(data)
	expect(Array(restored.actions) == ACTIONS, "the tracked actions survive")
	expect(restored.frame_count() == SCRIPTED.size(), "every frame survives")

	restored.start_replay()
	var third := restored.next_frame()
	restored.next_frame()
	restored.next_frame()
	restored.next_frame()
	var jump_frame := restored.next_frame()
	expect(not third.get("right", false), "frame 0 held nothing")
	expect(jump_frame.get("jump", false), "frame 4 held jump, exactly as recorded")

func test_start_recording_discards_the_old_take() -> void:
	print("re-recording")
	var r := _make()
	_record_scripted(r)
	r.start_recording()
	expect(r.frame_count() == 0, "starting a new recording clears the previous one")
