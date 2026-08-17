extends Node

# Drives the real enemy from scripts/enemy.gd — see docs/TEST_INTEGRITY.md.
#
# The enemy reads the player and the waypoint markers out of the scene, so the
# suite runs the real scene and moves the player around it.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_starts_patrolling()
	_test_a_nearby_player_starts_a_chase()
	_test_a_distant_player_is_ignored()
	_test_it_keeps_chasing_across_the_gap_between_ranges()
	_test_losing_the_player_sends_it_back()
	_test_it_resumes_patrolling_at_the_waypoint()
	_test_it_can_be_re_detected_on_the_way_back()
	_test_a_state_change_is_announced_once()
	_test_patrolling_advances_through_the_waypoints()
	_test_returning_heads_for_the_waypoint()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[patrol-ai] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

# The enemy is a scene node with siblings it looks up by path, so each test gets
# a fresh copy of the whole scene rather than a bare CharacterBody2D.
#
# The old copy goes first, and immediately: every scene in the tree shares one
# physics space, so leftover bodies overlap the new ones and move_and_slide()
# shoves the enemy off the waypoint it was placed on. queue_free() would be too
# late — it lands at the end of the frame, and the tests all run in this one.
func _make() -> CharacterBody2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene.get_node("Enemy")

func _player() -> CharacterBody2D:
	return _scene.get_node("Player")

## Put the player a given distance from the enemy, out along the x axis.
func _player_at_distance(enemy: CharacterBody2D, distance: float) -> void:
	_player().global_position = enemy.global_position + Vector2(distance, 0.0)

func _test_it_starts_patrolling() -> void:
	print("initial state")
	var e := _make()
	expect(e.state == e.State.PATROL, "the enemy starts on patrol")
	expect(e.waypoints.size() > 1, "with the scene's waypoints loaded")

func _test_a_nearby_player_starts_a_chase() -> void:
	print("detection")
	var e := _make()
	_player_at_distance(e, e.detect_range - 20.0)
	e._transition()
	expect(e.state == e.State.CHASE, "a player inside detect_range is chased")

func _test_a_distant_player_is_ignored() -> void:
	print("no false detection")
	var e := _make()
	_player_at_distance(e, e.detect_range + 20.0)
	e._transition()
	expect(e.state == e.State.PATROL, "a player outside detect_range is not")

func _test_it_keeps_chasing_across_the_gap_between_ranges() -> void:
	print("hysteresis")
	# lose_range is deliberately wider than detect_range. Without that gap the
	# enemy would flicker between chasing and returning at the boundary.
	var e := _make()
	expect(e.lose_range > e.detect_range, "the enemy gives up further out than it detects")

	_player_at_distance(e, e.detect_range - 20.0)
	e._transition()
	_player_at_distance(e, (e.detect_range + e.lose_range) * 0.5)
	e._transition()
	expect(e.state == e.State.CHASE, "and keeps chasing in between the two ranges")

func _test_losing_the_player_sends_it_back() -> void:
	print("giving up")
	var e := _make()
	_player_at_distance(e, e.detect_range - 20.0)
	e._transition()
	_player_at_distance(e, e.lose_range + 20.0)
	e._transition()
	expect(e.state == e.State.RETURN, "past lose_range the enemy heads back")

func _test_it_resumes_patrolling_at_the_waypoint() -> void:
	print("returning")
	var e := _make()
	_player_at_distance(e, e.detect_range - 20.0)
	e._transition()
	_player_at_distance(e, e.lose_range + 20.0)
	e._transition()
	expect(e.state == e.State.RETURN, "on its way back")

	# Still returning while it is short of the waypoint...
	e.global_position = e.waypoints[e.wp_index] + Vector2(40.0, 0.0)
	_player_at_distance(e, e.lose_range + 20.0)
	e._transition()
	expect(e.state == e.State.RETURN, "still returning while short of the waypoint")

	# ...and back on patrol once it arrives.
	e.global_position = e.waypoints[e.wp_index]
	_player_at_distance(e, e.lose_range + 20.0)
	e._transition()
	expect(e.state == e.State.PATROL, "and back on patrol once it arrives")

func _test_it_can_be_re_detected_on_the_way_back() -> void:
	print("re-detection")
	var e := _make()
	_player_at_distance(e, e.detect_range - 20.0)
	e._transition()
	_player_at_distance(e, e.lose_range + 20.0)
	e._transition()
	expect(e.state == e.State.RETURN, "returning")
	_player_at_distance(e, e.detect_range - 20.0)
	e._transition()
	expect(e.state == e.State.CHASE, "walking back into range restarts the chase")

func _test_a_state_change_is_announced_once() -> void:
	print("the signal")
	var e := _make()
	var seen := {"count": 0, "last": -1}
	e.state_changed.connect(func(s): seen["count"] += 1; seen["last"] = s)

	_player_at_distance(e, e.detect_range - 20.0)
	e._transition()
	expect(seen["count"] == 1, "entering a chase emits state_changed")
	expect(seen["last"] == e.State.CHASE, "carrying the new state")

	e._transition()
	expect(seen["count"] == 1, "staying in the same state emits nothing further")
	expect(e.state_label.text == "CHASE", "and the label names the state")

func _test_patrolling_advances_through_the_waypoints() -> void:
	print("the patrol route")
	var e := _make()
	var first: int = e.wp_index
	e.global_position = e.waypoints[first]
	e._patrol()
	expect(e.wp_index == first + 1, "arriving at a waypoint moves on to the next one along")

	# One waypoint is already behind us, so the rest of the route completes the
	# lap — and it has to come back round rather than run off the end.
	for i in e.waypoints.size() - 1:
		e.global_position = e.waypoints[e.wp_index]
		e._patrol()
	expect(e.wp_index == first, "and the route loops rather than running off the end")

	var away := _make()
	var target: Vector2 = away.waypoints[away.wp_index]
	away.global_position = target + Vector2(200.0, 0.0)
	var before: int = away.wp_index
	away._patrol()
	expect(away.wp_index == before, "a waypoint that is still far off is not ticked past")
	expect(away.velocity.length() > 0.0, "the enemy moves towards it instead")
	expect(away.velocity.x < 0.0, "and towards it, not away — the waypoint is to its left")
	expect(is_equal_approx(away.velocity.length(), away.patrol_speed), "at patrol speed")

func _test_returning_heads_for_the_waypoint() -> void:
	print("the walk back")
	var e := _make()
	# Standing to the *right* of the target on purpose: in a scene where every
	# coordinate is positive, adding two positions also points rightwards, so
	# only a leftward move distinguishes "towards" from "away".
	var target: Vector2 = e.waypoints[e.wp_index]
	e.global_position = target + Vector2(150.0, 0.0)
	e._return()
	expect(e.velocity.x < 0.0, "a returning enemy moves towards its waypoint, not away from it")
	expect(is_equal_approx(e.velocity.length(), e.patrol_speed), "at patrol speed, not chase speed")

	var chaser := _make()
	chaser.global_position = _player().global_position + Vector2(150.0, 0.0)
	chaser._chase()
	expect(chaser.velocity.x < 0.0, "and a chasing enemy moves towards the player")
	expect(is_equal_approx(chaser.velocity.length(), chaser.chase_speed), "at the faster chase speed")
