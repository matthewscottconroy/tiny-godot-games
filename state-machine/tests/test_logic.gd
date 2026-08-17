extends Node

# Drives the real player from scripts/player.gd. The previous suite recomputed
# the transition table inline — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_idle_when_still_on_floor()
	_test_walk_above_the_threshold()
	_test_threshold_is_exclusive()
	_test_direction_does_not_matter()
	_test_jump_when_rising()
	_test_fall_when_descending()
	_test_airborne_beats_horizontal_speed()
	_test_states_are_mutually_exclusive()
	_test_signal_fires_only_on_change()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[state-machine] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/player.gd")

func _make() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.set_script(_script)
	add_child(p)
	return p

func _test_idle_when_still_on_floor() -> void:
	print("idle")
	var p := _make()
	expect(p.state_for(true, Vector2.ZERO) == p.State.IDLE, "standing still on the floor is IDLE")

func _test_walk_above_the_threshold() -> void:
	print("walk")
	var p := _make()
	expect(p.state_for(true, Vector2(p.walk_threshold + 1.0, 0)) == p.State.WALK,
		"moving faster than the threshold is WALK")

func _test_threshold_is_exclusive() -> void:
	print("the threshold")
	var p := _make()
	# Exactly at the threshold counts as idle, which is what stops residual
	# drift after stopping from flickering the state.
	expect(p.state_for(true, Vector2(p.walk_threshold, 0)) == p.State.IDLE,
		"exactly at the threshold is still IDLE")
	expect(p.state_for(true, Vector2(p.walk_threshold - 0.1, 0)) == p.State.IDLE,
		"just below it is IDLE")

func _test_direction_does_not_matter() -> void:
	print("direction")
	var p := _make()
	var fast: float = p.walk_threshold + 50.0
	expect(p.state_for(true, Vector2(-fast, 0)) == p.State.WALK,
		"walking left is WALK too — the state uses speed, not signed velocity")

func _test_jump_when_rising() -> void:
	print("jump")
	var p := _make()
	expect(p.state_for(false, Vector2(0, -200)) == p.State.JUMP,
		"airborne and rising is JUMP")

func _test_fall_when_descending() -> void:
	print("fall")
	var p := _make()
	expect(p.state_for(false, Vector2(0, 200)) == p.State.FALL,
		"airborne and descending is FALL")
	expect(p.state_for(false, Vector2.ZERO) == p.State.FALL,
		"the apex, with no vertical speed, counts as FALL rather than JUMP")

func _test_airborne_beats_horizontal_speed() -> void:
	print("airborne wins")
	var p := _make()
	expect(p.state_for(false, Vector2(999, -200)) == p.State.JUMP,
		"running fast in mid-air is still JUMP, not WALK")

func _test_states_are_mutually_exclusive() -> void:
	print("one state at a time")
	# The point of an FSM over boolean flags: every input maps to exactly one
	# state, so contradictory combinations cannot arise.
	var p := _make()
	var seen := {}
	for on_floor in [true, false]:
		for vx in [0.0, 500.0]:
			for vy in [-100.0, 0.0, 100.0]:
				var st: int = p.state_for(on_floor, Vector2(vx, vy))
				seen[st] = true
				expect(st >= 0 and st < p.State.size(), "every input yields a valid state")
	expect(seen.size() == 4, "all four states are reachable")

func _test_signal_fires_only_on_change() -> void:
	print("state_changed")
	# A bare body has never called move_and_slide(), so is_on_floor() is false —
	# seed the state with what state_for() will actually derive.
	var player := _make()
	player.velocity = Vector2.ZERO
	player.state = player.state_for(false, Vector2.ZERO)     # FALL

	var changes: Array[int] = []
	player.state_changed.connect(func(s: int) -> void: changes.append(s))

	player._transition()
	expect(changes.is_empty(), "staying in the same state emits nothing")

	# Rising while airborne is a different state, so this must emit.
	player.velocity = Vector2(0, -300)
	player._transition()
	expect(changes == [player.State.JUMP], "entering a new state emits it exactly once")

	player._transition()
	expect(changes.size() == 1, "and holding that state does not emit again")
