extends Node2D

# Demo driver. Simulates a laggy server in-process: inputs go into a delay
# queue, the "server" applies them authoritatively, and its state comes back
# late. Adjustable latency and a wind force the server knows about but the
# client does not — so you can watch reconciliation actually correct something.

const SPEED := 220.0
const STEP := 1.0 / 60.0

@onready var _status: Label = $HUD/StatusLabel
@onready var _hint: Label = $HUD/HintLabel

var _client: PredictedState
var _server_state := {"pos": Vector2(320, 260)}
var _server_acked := 0
var _latency_frames := 12
var _wind := 0.0                       # server-only force the client cannot predict
var _prediction_on := true
var _inflight: Array[Dictionary] = []  # inputs travelling to the server
var _returning: Array[Dictionary] = [] # server states travelling back
var _corrections := 0
var _last_error := 0.0

# The one simulation step, shared by client and server. If these ever differ,
# prediction breaks — so there is exactly one of them.
static func simulate(state: Dictionary, input: Dictionary, delta: float) -> Dictionary:
	var pos: Vector2 = state.get("pos", Vector2.ZERO)
	var dir := Vector2(
		(1.0 if input.get("right", false) else 0.0) - (1.0 if input.get("left", false) else 0.0),
		(1.0 if input.get("down", false) else 0.0) - (1.0 if input.get("up", false) else 0.0),
	)
	pos += dir.normalized() * SPEED * delta
	pos += Vector2(float(input.get("wind", 0.0)), 0.0) * delta
	return {"pos": pos.clamp(Vector2(30, 90), Vector2(610, 350))}

func _ready() -> void:
	_client = PredictedState.new(Callable(self, "simulate"), {"pos": Vector2(320, 260)})
	_client.reconciled.connect(func(_seq: int, error: float) -> void:
		_corrections += 1
		_last_error = error)
	_hint.text = "Arrows move   [/] latency   W toggle server-only wind   P toggle prediction   R reset"

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_BRACKETLEFT: _latency_frames = maxi(_latency_frames - 4, 0)
		KEY_BRACKETRIGHT: _latency_frames = mini(_latency_frames + 4, 60)
		KEY_W: _wind = 0.0 if _wind != 0.0 else 90.0
		KEY_P: _prediction_on = not _prediction_on
		KEY_R: _reset()

func _reset() -> void:
	_client = PredictedState.new(Callable(self, "simulate"), {"pos": Vector2(320, 260)})
	_client.reconciled.connect(func(_seq: int, error: float) -> void:
		_corrections += 1
		_last_error = error)
	_server_state = {"pos": Vector2(320, 260)}
	_server_acked = 0
	_inflight.clear()
	_returning.clear()
	_corrections = 0
	_last_error = 0.0

func _physics_process(_delta: float) -> void:
	var input := {
		"left": Input.is_action_pressed("ui_left"),
		"right": Input.is_action_pressed("ui_right"),
		"up": Input.is_action_pressed("ui_up"),
		"down": Input.is_action_pressed("ui_down"),
	}

	# Client: apply immediately (or not, to show the difference).
	var seq := _client.predict(input, STEP) if _prediction_on else _client.sequence
	if not _prediction_on:
		_client.state = _client.state   # unchanged: the client waits for the server

	_inflight.append({"arrive": _latency_frames, "sequence": seq, "input": input})

	# Server: apply inputs that have arrived, with a force the client cannot see.
	for entry in _inflight:
		entry["arrive"] = int(entry["arrive"]) - 1
	var arrived := _inflight.filter(func(e: Dictionary) -> bool: return int(e["arrive"]) <= 0)
	_inflight = _inflight.filter(func(e: Dictionary) -> bool: return int(e["arrive"]) > 0)
	for entry in arrived:
		var server_input: Dictionary = (entry["input"] as Dictionary).duplicate()
		server_input["wind"] = _wind
		_server_state = simulate(_server_state, server_input, STEP)
		_server_acked = int(entry["sequence"])
		_returning.append({"arrive": _latency_frames, "state": _server_state.duplicate(),
			"acked": _server_acked})

	# Client: reconcile against server states as they come back.
	for entry in _returning:
		entry["arrive"] = int(entry["arrive"]) - 1
	var received := _returning.filter(func(e: Dictionary) -> bool: return int(e["arrive"]) <= 0)
	_returning = _returning.filter(func(e: Dictionary) -> bool: return int(e["arrive"]) > 0)
	for entry in received:
		_client.reconcile(entry["state"], int(entry["acked"]))

	_refresh()
	queue_redraw()

func _refresh() -> void:
	_status.text = "\n".join([
		"round-trip latency: %d frames (~%d ms)    prediction: %s    server wind: %s" % [
			_latency_frames * 2, int(_latency_frames * 2 * STEP * 1000.0),
			"on" if _prediction_on else "OFF", "on" if _wind != 0.0 else "off"],
		"unconfirmed inputs: %d    corrections: %d    last error: %.1f px" % [
			_client.pending_count(), _corrections, _last_error],
		"green = what you see (predicted)     grey = server's authoritative position",
	])

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
	var server_pos: Vector2 = _server_state.get("pos", Vector2.ZERO)
	var client_pos: Vector2 = _client.state.get("pos", Vector2.ZERO)
	# The gap between these two is the prediction error you are correcting.
	draw_line(server_pos, client_pos, Color(0.6, 0.5, 0.3), 1.0)
	draw_rect(Rect2(server_pos - Vector2(16, 16), Vector2(32, 32)), Color(0.45, 0.47, 0.55, 0.7))
	draw_rect(Rect2(client_pos - Vector2(12, 12), Vector2(24, 24)), Color(0.3, 0.8, 0.45))
	# Unconfirmed inputs, one pip each.
	for i in mini(_client.pending_count(), 60):
		draw_rect(Rect2(16 + i * 9, 360, 6, 10), Color(0.9, 0.75, 0.3))
