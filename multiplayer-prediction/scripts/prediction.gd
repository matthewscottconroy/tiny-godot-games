## Client-side prediction with server reconciliation.
##
## Waiting for the server to confirm every input makes a game feel broken at any
## real latency. Prediction fixes the feel: the client applies input immediately
## AND remembers it, tagged with a sequence number. The server, which is
## authoritative, periodically says "after input #N you were here". The client
## then rewinds to that state and re-applies every input after N — so a
## correction is invisible when the prediction was right, and a single snap when
## it was wrong.
##
## The simulation step is injected as a Callable, so the exact same function runs
## on the client (predicting), on the client again (re-simulating), and on the
## server (authoritative). If those three ever diverge, prediction stops working
## — which is why it lives in one place here.
class_name PredictedState
extends RefCounted

## The client had to correct itself: (sequence, error_distance).
signal reconciled(sequence: int, error: float)

## step.call(state: Dictionary, input: Dictionary, delta: float) -> Dictionary
var step: Callable

## Corrections smaller than this are ignored — floating point noise is not worth
## a snap, and re-simulating on every packet is wasted work.
var tolerance := 0.01

var state: Dictionary = {}
var sequence := 0

## Inputs applied locally but not yet confirmed by the server.
var _pending: Array[Dictionary] = []

func _init(simulate: Callable = Callable(), initial: Dictionary = {}) -> void:
	step = simulate
	state = initial.duplicate(true)

## Apply an input right now and remember it until the server confirms it.
## Returns the sequence number assigned to this input.
func predict(input: Dictionary, delta: float) -> int:
	sequence += 1
	_pending.append({"sequence": sequence, "input": input.duplicate(), "delta": delta})
	state = step.call(state, input, delta)
	return sequence

## The server's authoritative state, as of `acked_sequence`.
##
## Drops every input the server has now accounted for, snaps to its state, and
## re-applies whatever is still in flight. Returns true if a visible correction
## was needed.
func reconcile(server_state: Dictionary, acked_sequence: int) -> bool:
	_pending = _pending.filter(func(e: Dictionary) -> bool:
		return int(e["sequence"]) > acked_sequence)

	# Where the client thinks it was, versus where the server says it was.
	var predicted := _replay_from(server_state)
	var error := _distance(predicted, state)

	state = predicted
	if error > tolerance:
		reconciled.emit(acked_sequence, error)
		return true
	return false

## Number of inputs applied locally but not yet confirmed.
func pending_count() -> int:
	return _pending.size()

func pending_sequences() -> Array:
	return _pending.map(func(e: Dictionary) -> int: return int(e["sequence"]))

## Re-run every still-pending input on top of a base state.
func _replay_from(base: Dictionary) -> Dictionary:
	var working := base.duplicate(true)
	for entry in _pending:
		working = step.call(working, entry["input"], float(entry["delta"]))
	return working

func _distance(a: Dictionary, b: Dictionary) -> float:
	var pa: Vector2 = a.get("pos", Vector2.ZERO)
	var pb: Vector2 = b.get("pos", Vector2.ZERO)
	return pa.distance_to(pb)
