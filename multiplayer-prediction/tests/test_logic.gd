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
