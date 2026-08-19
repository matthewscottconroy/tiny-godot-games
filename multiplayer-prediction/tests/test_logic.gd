extends Node

# Drives the real PredictedState from scripts/prediction.gd, and the demo's own
# simulate() step from scripts/main.gd — so client and server run identical code
# here just as they must in a real game.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_predict_applies_immediately()
	test_predict_assigns_sequences()
	test_pending_tracks_unconfirmed_input()
	test_ack_drops_confirmed_input()
	test_matching_server_state_needs_no_correction()
	test_divergent_server_state_corrects()
	test_reconcile_replays_unconfirmed_input()
	test_tolerance_ignores_noise()
	test_reconciled_signal()
	test_prediction_beats_waiting()
	test_the_state_is_copied_not_shared()
	test_the_step_reads_every_direction()
	await test_the_network_queue_delivers_in_order()
	await test_the_keys_change_the_conditions()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[multiplayer-prediction] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0

# The demo's step function — loaded from the real script rather than copied.
var _sim: Callable

func _init() -> void:
	var main_script: GDScript = load("res://scripts/main.gd")
	_sim = Callable(main_script, "simulate")

func _make(start := Vector2(100, 100)) -> PredictedState:
	return PredictedState.new(_sim, {"pos": start})

func _right() -> Dictionary:
	return {"right": true}

func test_predict_applies_immediately() -> void:
	print("prediction is applied without waiting")
	var c := _make()
	var before: Vector2 = c.state["pos"]
	c.predict(_right(), STEP)
	expect(c.state["pos"].x > before.x, "the client moves on the frame the input happens")

func test_predict_assigns_sequences() -> void:
	print("each input gets a sequence number")
	var c := _make()
	expect(c.predict(_right(), STEP) == 1, "the first input is sequence 1")
	expect(c.predict(_right(), STEP) == 2, "sequences increment")
	expect(c.sequence == 2, "the recorder tracks the latest")

func test_pending_tracks_unconfirmed_input() -> void:
	print("unconfirmed inputs are remembered")
	var c := _make()
	for i in 5:
		c.predict(_right(), STEP)
	expect(c.pending_count() == 5, "every applied input is held until confirmed")
	expect(c.pending_sequences() == [1, 2, 3, 4, 5], "in order, with their sequence numbers")

func test_ack_drops_confirmed_input() -> void:
	print("acknowledged inputs are discarded")
	var c := _make()
	for i in 5:
		c.predict(_right(), STEP)
	# The server has now accounted for everything up to and including #3.
	c.reconcile(c.state, 3)
	expect(c.pending_count() == 2, "only inputs after the ack remain")
	expect(c.pending_sequences() == [4, 5], "and they are the right ones")

func test_matching_server_state_needs_no_correction() -> void:
	print("an agreeing server causes no snap")
	var c := _make()
	# Run a server alongside the client over identical input.
	var server := {"pos": c.state["pos"]}
	var inputs: Array[Dictionary] = []
	for i in 4:
		inputs.append(_right())
		c.predict(inputs[i], STEP)
	for input in inputs:
		server = _sim.call(server, input, STEP)

	var corrected := c.reconcile(server, 4)
	expect(not corrected, "identical simulation means no correction")
	expect(c.state["pos"].distance_to(server["pos"]) < 0.001, "and the states agree")

func test_divergent_server_state_corrects() -> void:
	print("a disagreeing server snaps the client")
	var c := _make()
	c.predict(_right(), STEP)
	# The server saw something the client could not predict.
	var corrected := c.reconcile({"pos": Vector2(400, 100)}, 1)
	expect(corrected, "a real disagreement reports a correction")
	expect(is_equal_approx(c.state["pos"].x, 400.0), "the client snaps to the server's answer")

func test_reconcile_replays_unconfirmed_input() -> void:
	print("unconfirmed input survives a correction")
	var c := _make(Vector2(100, 100))
	c.predict(_right(), STEP)      # #1 — the server will confirm this
	c.predict(_right(), STEP)      # #2 — still in flight
	c.predict(_right(), STEP)      # #3 — still in flight

	# Server confirms #1 only, from a position 50px right of where we started.
	var server_pos := Vector2(150, 100)
	c.reconcile({"pos": server_pos}, 1)

	# The client must be at the server's position PLUS the two inputs it has
	# applied since. Losing them is the classic prediction bug: the player's
	# recent movement gets rubber-banded away.
	var expected := server_pos + Vector2(2.0 * 220.0 * STEP, 0.0)
	expect(c.state["pos"].distance_to(expected) < 0.001,
		"the two unconfirmed inputs are re-applied on top of the server state")
	expect(c.pending_count() == 2, "and remain pending until their own ack")

func test_tolerance_ignores_noise() -> void:
	print("tiny disagreements are ignored")
	var c := _make()
	c.tolerance = 1.0
	c.predict(_right(), STEP)
	var nudged: Vector2 = c.state["pos"] + Vector2(0.2, 0.0)
	expect(not c.reconcile({"pos": nudged}, 1), "a sub-tolerance difference is not a correction")
	c.tolerance = 0.01
	c.predict(_right(), STEP)
	var shoved: Vector2 = c.state["pos"] + Vector2(5.0, 0.0)
	expect(c.reconcile({"pos": shoved}, 2), "a real difference still corrects")

func test_reconciled_signal() -> void:
	print("the reconciled signal reports the error")
	var c := _make()
	var seen: Array = []
	c.reconciled.connect(func(seq: int, error: float) -> void: seen.append([seq, error]))
	c.predict(_right(), STEP)
	c.reconcile({"pos": Vector2(300, 100)}, 1)
	expect(seen.size() == 1, "one signal per correction")
	expect(seen[0][0] == 1, "carrying the acknowledged sequence")
	expect(float(seen[0][1]) > 1.0, "and the size of the error")

func test_prediction_beats_waiting() -> void:
	print("why prediction exists at all")
	# With latency, a client that waits for the server has not moved yet; a
	# predicting client already has. That gap is the entire feel difference.
	var predicting := _make()
	var waiting_pos := Vector2(100, 100)
	for i in 10:
		predicting.predict(_right(), STEP)
	expect(predicting.state["pos"].x > waiting_pos.x + 30.0,
		"the predicting client has moved after 10 frames")
	expect(is_equal_approx(waiting_pos.x, 100.0),
		"the waiting client has not moved at all yet")

# --- the demo around the component -------------------------------------------

## Both axes, both ways, and the default when a key is absent.
##
## Every test above sends `{"right": true}`, which leaves the other three keys
## to their defaults — so a sign error in `right - left` is invisible, and so is
## a default of `true` on any key that is never sent.
func test_the_step_reads_every_direction() -> void:
	print("the step's directions")
	var start := {"pos": Vector2(300, 200)}

	var right: Dictionary = _sim.call(start, {"right": true}, STEP)
	var left: Dictionary = _sim.call(start, {"left": true}, STEP)
	expect(right["pos"].x > start["pos"].x, "right moves right (%s)" % right["pos"])
	expect(left["pos"].x < start["pos"].x, "left moves left (%s)" % left["pos"])

	var down: Dictionary = _sim.call(start, {"down": true}, STEP)
	var up: Dictionary = _sim.call(start, {"up": true}, STEP)
	expect(down["pos"].y > start["pos"].y, "down moves down — Y is down (%s)" % down["pos"])
	expect(up["pos"].y < start["pos"].y, "up moves up (%s)" % up["pos"])

	# Opposite keys cancel. Added instead of subtracted they would double.
	var both_x: Dictionary = _sim.call(start, {"left": true, "right": true}, STEP)
	expect(both_x["pos"] == start["pos"],
		"left and right together cancel out (%s)" % both_x["pos"])
	var both_y: Dictionary = _sim.call(start, {"up": true, "down": true}, STEP)
	expect(both_y["pos"] == start["pos"], "so do up and down (%s)" % both_y["pos"])

	# An empty input is standing still — every key defaults to not pressed.
	var idle: Dictionary = _sim.call(start, {}, STEP)
	expect(idle["pos"] == start["pos"], "an empty input moves nothing (%s)" % idle["pos"])

	# A diagonal is normalised, or moving corner-ways would be faster.
	var diagonal: Dictionary = _sim.call(start, {"right": true, "down": true}, STEP)
	expect(is_equal_approx(diagonal["pos"].distance_to(start["pos"]),
			right["pos"].distance_to(start["pos"])),
		"a diagonal covers the same ground as a straight line (%.3f vs %.3f)"
		% [diagonal["pos"].distance_to(start["pos"]), right["pos"].distance_to(start["pos"])])

	# Wind is the server-only force, applied along X on top of the input.
	var windy: Dictionary = _sim.call(start, {"wind": 90.0}, STEP)
	expect(windy["pos"].x > start["pos"].x, "wind pushes along X (%s)" % windy["pos"])
	expect(is_equal_approx(windy["pos"].y, start["pos"].y), "and not along Y")

	# The play area is clamped, so neither side can walk off the diagram.
	var far := {"pos": Vector2(10_000, 10_000)}
	var clamped: Dictionary = _sim.call(far, {"right": true}, STEP)
	expect(clamped["pos"].x <= 610.0 and clamped["pos"].y <= 350.0,
		"the state is clamped to the play area (%s)" % clamped["pos"])

## Inputs take the latency to reach the server, and states the same coming back.
##
## The queues are two counters and two filters, and every one of them survived:
## a countdown that counts up never delivers, and a filter with its comparison
## flipped either delivers everything at once or keeps it forever.
func test_the_network_queue_delivers_in_order() -> void:
	print("the wire")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame

	scene._reset()
	scene._latency_frames = 5
	scene._prediction_on = true

	var server_start: Vector2 = scene._server_state["pos"]
	# One frame in, the input is on the wire and the server has not seen it.
	scene._physics_process(scene.STEP)
	expect(scene._inflight.size() > 0, "the input is in flight (%d)" % scene._inflight.size())
	expect(scene._server_state["pos"] == server_start,
		"and the server has not moved yet (%s)" % scene._server_state["pos"])

	# Run past the one-way trip and the server has applied something.
	for _i in 10:
		scene._physics_process(scene.STEP)
	expect(scene._server_acked > 0, "the server acknowledges inputs (%d)" % scene._server_acked)

	# The queue drains: it does not grow without bound, and it does not empty
	# instantly either — it holds about one latency's worth of frames.
	for _i in 60:
		scene._physics_process(scene.STEP)
	expect(scene._inflight.size() > 0, "the wire keeps carrying (%d)" % scene._inflight.size())
	expect(scene._inflight.size() <= scene._latency_frames + 2,
		"about one latency of inputs, not every input ever sent (%d for %d frames)"
		% [scene._inflight.size(), scene._latency_frames])
	expect(scene._returning.size() > 0,
		"states are on the wire coming back too (%d)" % scene._returning.size())
	expect(scene._returning.size() <= scene._latency_frames + 2,
		"about one latency of them, not every state ever sent (%d for %d frames)"
		% [scene._returning.size(), scene._latency_frames])

	# Each server state is delivered once. Deliver the whole queue every frame
	# instead — a filter that accepts entries still in flight — and the client
	# reconciles many times per frame. Wind makes every delivery a correction,
	# so the count is a direct measure of how often one lands.
	scene._reset()
	scene._latency_frames = 8
	scene._wind = 90.0
	var frames := 60
	for _i in frames:
		scene._physics_process(scene.STEP)
	expect(scene._corrections > 0,
		"an unpredictable server force does cause corrections (%d)" % scene._corrections)
	expect(scene._corrections <= frames,
		"but no more than one per frame (%d in %d)" % [scene._corrections, frames])
	scene._wind = 0.0

	# With no latency at all, the round trip completes within a frame or two.
	scene._reset()
	scene._latency_frames = 0
	for _i in 4:
		scene._physics_process(scene.STEP)
	expect(scene._inflight.is_empty(),
		"with zero latency nothing waits on the wire (%d)" % scene._inflight.size())
	expect(scene._server_acked > 0, "and the server has caught up (%d)" % scene._server_acked)

	scene.queue_free()

## The keys that make the demo demonstrate anything.
func test_the_keys_change_the_conditions() -> void:
	print("the controls")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame

	expect(scene._prediction_on,
		"prediction starts on — the demo opens showing the thing it is about")
	expect(scene._wind == 0.0, "and the unpredictable force starts off (%.0f)" % scene._wind)

	var started: int = scene._latency_frames
	scene._unhandled_key_input(_key(KEY_BRACKETRIGHT))
	expect(scene._latency_frames > started,
		"] adds latency (%d -> %d)" % [started, scene._latency_frames])
	scene._unhandled_key_input(_key(KEY_BRACKETLEFT))
	expect(scene._latency_frames == started,
		"[ takes it away again (%d)" % scene._latency_frames)

	# Both ends are bounded: negative latency is meaningless and an unbounded
	# one would stall the demo entirely.
	for _i in 40:
		scene._unhandled_key_input(_key(KEY_BRACKETLEFT))
	expect(scene._latency_frames == 0, "latency floors at zero (%d)" % scene._latency_frames)
	for _i in 40:
		scene._unhandled_key_input(_key(KEY_BRACKETRIGHT))
	expect(scene._latency_frames == 60, "and caps at sixty (%d)" % scene._latency_frames)

	# W toggles the wind, and the readout follows it.
	scene._unhandled_key_input(_key(KEY_W))
	expect(scene._wind != 0.0, "W turns the wind on (%.0f)" % scene._wind)
	scene._refresh()
	expect(scene._status.text.contains("server wind: on"),
		"and the readout says so (%s)" % scene._status.text.split("\n")[0])
	scene._unhandled_key_input(_key(KEY_W))
	expect(scene._wind == 0.0, "W again turns it off (%.0f)" % scene._wind)
	scene._refresh()
	expect(scene._status.text.contains("server wind: off"), "and the readout follows")

	# P toggles prediction, R puts everything back.
	scene._unhandled_key_input(_key(KEY_P))
	expect(not scene._prediction_on, "P turns prediction off")
	scene._corrections = 7
	scene._unhandled_key_input(_key(KEY_R))
	expect(scene._corrections == 0, "R clears the counters")
	expect(scene._inflight.is_empty() and scene._returning.is_empty(),
		"and empties the wire")

	# A key released, or an auto-repeat, must not count as a second press.
	# Away from either end of the range, so a change would actually show — at
	# the cap, mini(60 + 4, 60) is 60 whether the press counted or not.
	scene._latency_frames = 20
	var before: int = scene._latency_frames
	var released := _key(KEY_BRACKETRIGHT)
	released.pressed = false
	scene._unhandled_key_input(released)
	expect(scene._latency_frames == before, "a key coming back up changes nothing")
	var repeat := _key(KEY_BRACKETRIGHT)
	repeat.echo = true
	scene._unhandled_key_input(repeat)
	expect(scene._latency_frames == before, "nor does an auto-repeat")

	scene.queue_free()

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

## PredictedState takes a copy of the state it is given, all the way down.
##
## The demo's own state is `{"pos": Vector2}`, and Vector2 is a value type, so
## a shallow copy behaves identically and nothing here would notice. But this is
## a reusable component — the moment someone's state holds an inventory array or
## a nested dictionary, a shallow copy means the component and its caller share
## it, and predicting a frame quietly rewrites the caller's data.
func test_the_state_is_copied_not_shared() -> void:
	print("the state is copied")
	# A step that records where it went by appending to the array already in the
	# state, in place. That is the ordinary thing to write, and it is exactly
	# what a shared array turns into a bug: the component's copy and the
	# caller's are then the same array, and stepping writes into both.
	var stepper := func(state: Dictionary, input: Dictionary, delta: float) -> Dictionary:
		var moved: Vector2 = (state.get("pos", Vector2.ZERO) as Vector2) \
			+ Vector2(1.0 if input.get("right", false) else 0.0, 0.0) * delta
		var trail: Array = state["visited"]
		trail.append(moved)
		return {"pos": moved, "visited": trail}

	var initial := {"pos": Vector2(10, 10), "visited": []}
	var client := PredictedState.new(stepper, initial)

	expect((initial["visited"] as Array).is_empty(),
		"the caller's nested array starts empty (%d)" % (initial["visited"] as Array).size())
	client.predict({"right": true}, STEP)
	expect((initial["visited"] as Array).is_empty(),
		"and predicting a frame does not write into it (%d)"
		% (initial["visited"] as Array).size())
	expect((client.state["visited"] as Array).size() == 1,
		"while the component's own copy records the step (%d)"
		% (client.state["visited"] as Array).size())

	# The same on the way back in: reconciling against a server state must not
	# reach into the dictionary the server handed over.
	var server := {"pos": Vector2(50, 10), "visited": []}
	client.predict({"right": true}, STEP)
	client.reconcile(server, 0)
	expect((server["visited"] as Array).is_empty(),
		"replaying pending inputs does not write into the server's state (%d)"
		% (server["visited"] as Array).size())
