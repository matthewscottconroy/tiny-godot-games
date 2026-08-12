extends Node

# Drives the real SteeringAgent from scripts/steering_agent.gd rather than a
# copy of its force calculations.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_seek_points_at_target()
	_test_seek_slows_inside_arrive_radius()
	_test_flee_points_away()
	_test_flee_ignores_distant_threats()
	_test_force_is_clamped()
	_test_step_integrates_and_clamps_speed()
	_test_wander_stays_within_max_force()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _make() -> SteeringAgent:
	var agent := SteeringAgent.new()
	agent.position = Vector2(100.0, 100.0)
	agent.velocity = Vector2.ZERO
	return agent

func _test_seek_points_at_target() -> void:
	print("seek points at the target")
	var agent := _make()
	var force := agent.seek(agent.position + Vector2(200.0, 0.0))
	expect(force.x > 0.0 and is_zero_approx(force.y), "seek steers straight toward the target")

func _test_seek_slows_inside_arrive_radius() -> void:
	print("seek eases to a stop inside arrive_radius")
	var far := _make()
	var far_force := far.seek(far.position + Vector2(500.0, 0.0)).length()
	var near := _make()
	near.velocity = Vector2.ZERO
	var near_force := near.seek(near.position + Vector2(near.arrive_radius * 0.25, 0.0)).length()
	expect(near_force < far_force, "the desired speed scales down within arrive_radius")

	var at_target := _make()
	expect(at_target.seek(at_target.position).length() < 0.01,
		"sitting on the target produces no steering force")

func _test_flee_points_away() -> void:
	print("flee points away from the threat")
	var agent := _make()
	var force := agent.flee(agent.position + Vector2(50.0, 0.0))
	expect(force.x < 0.0, "flee steers directly away from a nearby threat")

func _test_flee_ignores_distant_threats() -> void:
	print("flee ignores threats beyond flee_radius")
	var agent := _make()
	agent.velocity = Vector2(100.0, 0.0)
	var force := agent.flee(agent.position + Vector2(agent.flee_radius + 50.0, 0.0))
	# Out of range, flee just decelerates — the force opposes the current velocity.
	expect(force.x < 0.0, "a distant threat produces a braking force instead of a panic run")
	expect(force.length() <= agent.max_force + 0.01, "the braking force is still clamped")

func _test_force_is_clamped() -> void:
	print("steering forces respect max_force")
	var agent := _make()
	agent.max_force = 50.0
	expect(agent.seek(agent.position + Vector2(9999.0, 0.0)).length() <= 50.01,
		"seek never exceeds max_force")
	expect(agent.flee(agent.position + Vector2(10.0, 0.0)).length() <= 50.01,
		"flee never exceeds max_force")

func _test_step_integrates_and_clamps_speed() -> void:
	print("step integrates force into velocity and position")
	var agent := _make()
	var start := agent.position
	agent.step(Vector2(1000.0, 0.0), 1.0)
	expect(agent.velocity.length() <= agent.max_speed + 0.01, "velocity is clamped to max_speed")
	expect(agent.position.x > start.x, "position advances along the velocity")

func _test_wander_stays_within_max_force() -> void:
	print("wander produces a bounded force")
	var agent := _make()
	agent.velocity = Vector2(60.0, 0.0)
	var within := true
	for i in 50:
		if agent.wander(0.016).length() > agent.max_force + 0.01:
			within = false
	expect(within, "wander is clamped to max_force across many jittered frames")

func _report() -> void:
	var summary := "[steering-behaviors] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
