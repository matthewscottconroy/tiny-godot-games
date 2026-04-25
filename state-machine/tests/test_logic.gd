extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_idle_when_stationary_on_floor()
	test_walk_when_moving_on_floor()
	test_jump_when_rising()
	test_fall_when_falling()
	test_idle_to_walk_transition()
	test_walk_to_fall_transition()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[state-machine] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

# Replicate _transition() logic from player.gd
enum State { IDLE, WALK, JUMP, FALL }

func _calc_state(on_floor: bool, vel_x: float, vel_y: float) -> State:
	if on_floor:
		return State.WALK if abs(vel_x) > 10 else State.IDLE
	else:
		return State.JUMP if vel_y < 0 else State.FALL

# --- tests ---

func test_idle_when_stationary_on_floor() -> void:
	expect(_calc_state(true, 0.0, 0.0)   == State.IDLE, "standing still on floor → IDLE")
	expect(_calc_state(true, 5.0, 0.0)   == State.IDLE, "tiny horizontal vel on floor → IDLE (threshold)")

func test_walk_when_moving_on_floor() -> void:
	expect(_calc_state(true, 200.0, 0.0) == State.WALK, "moving right on floor → WALK")
	expect(_calc_state(true, -200.0, 0.0) == State.WALK, "moving left on floor → WALK")
	expect(_calc_state(true, 11.0, 0.0)  == State.WALK, "vel.x just above threshold → WALK")

func test_jump_when_rising() -> void:
	expect(_calc_state(false, 0.0, -420.0) == State.JUMP, "rising (vel_y < 0) → JUMP")
	expect(_calc_state(false, 100.0, -1.0) == State.JUMP, "any upward velocity → JUMP")

func test_fall_when_falling() -> void:
	expect(_calc_state(false, 0.0, 100.0)  == State.FALL, "falling (vel_y > 0) → FALL")
	expect(_calc_state(false, 50.0, 0.0)   == State.FALL, "horizontal only, airborne → FALL (vel_y == 0)")

func test_idle_to_walk_transition() -> void:
	var s := _calc_state(true, 0.0, 0.0)
	expect(s == State.IDLE, "starts IDLE")
	s = _calc_state(true, 200.0, 0.0)
	expect(s == State.WALK, "transitions to WALK on horizontal input")

func test_walk_to_fall_transition() -> void:
	var s := _calc_state(true, 200.0, 0.0)
	expect(s == State.WALK, "WALK while on floor")
	s = _calc_state(false, 200.0, 50.0)
	expect(s == State.FALL, "FALL after leaving floor with downward velocity")
