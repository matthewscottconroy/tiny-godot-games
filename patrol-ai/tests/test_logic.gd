extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_patrol_to_chase_when_close()
	test_patrol_stays_when_far()
	test_chase_to_return_when_very_far()
	test_chase_stays_when_medium_range()
	test_return_to_chase_when_player_close_again()
	test_return_to_patrol_when_reached_waypoint()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[patrol-ai] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

# Replicate constants and _transition() logic from enemy.gd
enum State { PATROL, CHASE, RETURN }
const DETECT_RANGE := 180.0
const LOSE_RANGE   := 280.0

func _next_state(current: State, dist_to_player: float, dist_to_waypoint: float) -> State:
	match current:
		State.PATROL:
			if dist_to_player < DETECT_RANGE:
				return State.CHASE
		State.CHASE:
			if dist_to_player > LOSE_RANGE:
				return State.RETURN
		State.RETURN:
			if dist_to_player < DETECT_RANGE:
				return State.CHASE
			elif dist_to_waypoint < 10:
				return State.PATROL
	return current

# --- tests ---

func test_patrol_to_chase_when_close() -> void:
	var s := _next_state(State.PATROL, DETECT_RANGE - 1, 999)
	expect(s == State.CHASE, "PATROL → CHASE when player within detect range")

func test_patrol_stays_when_far() -> void:
	var s := _next_state(State.PATROL, DETECT_RANGE + 10, 999)
	expect(s == State.PATROL, "PATROL stays when player outside detect range")

func test_chase_to_return_when_very_far() -> void:
	var s := _next_state(State.CHASE, LOSE_RANGE + 1, 999)
	expect(s == State.RETURN, "CHASE → RETURN when player beyond lose range")

func test_chase_stays_when_medium_range() -> void:
	var s := _next_state(State.CHASE, DETECT_RANGE + 10, 999)
	expect(s == State.CHASE, "CHASE stays within lose range")

func test_return_to_chase_when_player_close_again() -> void:
	var s := _next_state(State.RETURN, DETECT_RANGE - 1, 999)
	expect(s == State.CHASE, "RETURN → CHASE if player re-enters detect range")

func test_return_to_patrol_when_reached_waypoint() -> void:
	var s := _next_state(State.RETURN, LOSE_RANGE - 1, 5)
	expect(s == State.PATROL, "RETURN → PATROL when close to waypoint and player far")
