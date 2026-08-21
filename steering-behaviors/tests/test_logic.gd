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
	_test_a_force_is_the_change_in_velocity_not_the_sum()
	_test_arrive_scales_the_speed_by_how_close_it_is()
	_test_flee_only_reacts_inside_its_radius()
	_test_wander_projects_a_circle_ahead_of_the_agent()
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

## A steering force is *desired minus current*, not desired plus current.
##
## Every test above leaves the velocity at zero, where the two are the same
## vector — so all three behaviours could add their current velocity instead of
## subtracting it and nothing would notice. An agent already moving is the case
## that tells them apart, and it is the only case that ever happens in the demo.
func _test_a_force_is_the_change_in_velocity_not_the_sum() -> void:
	print("force is a change, not a sum")

	# Already travelling at full speed straight at the target: there is nothing
	# left to correct, so the force is nothing. Added instead, it would be twice
	# the velocity.
	var chasing := _make()
	chasing.velocity = Vector2(chasing.max_speed, 0.0)
	var settled := chasing.seek(chasing.position + Vector2(500.0, 0.0))
	expect(settled.length() < 1.0,
		"seek asks for no change when already heading there at speed (%.1f)"
		% settled.length())

	# Travelling the wrong way: the force has to undo the current velocity as
	# well as build the new one, so it is larger than for a standing start.
	var wrong_way := _make()
	wrong_way.velocity = Vector2(-wrong_way.max_speed, 0.0)
	var turning := wrong_way.seek(wrong_way.position + Vector2(500.0, 0.0))
	var standing := _make().seek(Vector2(600.0, 100.0))
	expect(turning.x > 0.0, "and still points at the target while turning round")
	expect(turning.length() > standing.length(),
		"turning around costs more than starting from rest (%.1f vs %.1f)"
		% [turning.length(), standing.length()])

	# The same for flee: running away already, there is little left to add.
	var running := _make()
	running.velocity = Vector2(-running.max_speed, 0.0)
	var fleeing := running.flee(running.position + Vector2(50.0, 0.0))
	expect(fleeing.length() < 1.0,
		"flee asks for no change when already running away at speed (%.1f)"
		% fleeing.length())

	# And for wander, whose force is bounded by max_force either way — so the
	# direction is what tells them apart. Pointed straight at its own wander
	# target, there is nothing to correct.
	var roaming := _make()
	roaming.wander_jitter = 0.0
	roaming.wander_angle = 0.0
	roaming.velocity = Vector2(roaming.max_speed, 0.0)
	# ahead is +x, so the target is out to the right; heading right at full
	# speed is already most of the way to the desired velocity.
	var drift := roaming.wander(0.016)
	expect(drift.length() < roaming.max_force * 0.5,
		"wander asks for a small correction when already going that way (%.1f)"
		% drift.length())

## Inside arrive_radius the desired speed is scaled by how close it is.
func _test_arrive_scales_the_speed_by_how_close_it_is() -> void:
	print("arrive")
	var agent := _make()
	# A quarter of the way in, from rest: the force is the desired speed, which
	# is a quarter of the maximum. Comparing it only against a distant target
	# cannot see a rule that scales the wrong side of the radius, because the
	# distant force is clamped by max_force anyway.
	var quarter := agent.arrive_radius * 0.25
	var force := agent.seek(agent.position + Vector2(quarter, 0.0))
	expect(is_equal_approx(force.length(), agent.max_speed * 0.25),
		"a quarter of the way in asks for a quarter of top speed (%.1f of %.1f)"
		% [force.length(), agent.max_speed * 0.25])

	var half := _make()
	var half_force := half.seek(half.position + Vector2(half.arrive_radius * 0.5, 0.0))
	expect(is_equal_approx(half_force.length(), half.max_speed * 0.5),
		"halfway in, half of it (%.1f)" % half_force.length())

	# Just outside the radius it asks for full speed, not more.
	var outside := _make()
	var outside_force := outside.seek(
		outside.position + Vector2(outside.arrive_radius + 1.0, 0.0))
	expect(is_equal_approx(outside_force.length(), outside.max_speed),
		"just outside it asks for the full speed (%.1f)" % outside_force.length())
	expect(outside_force.length() > half_force.length(),
		"which is more than it asks for halfway in")

## Flee reacts only inside its radius, and only to a threat somewhere else.
func _test_flee_only_reacts_inside_its_radius() -> void:
	print("the flee radius")
	# From rest, a distant threat produces nothing at all — there is no velocity
	# to brake. A radius test joined with `or` instead of `and` would panic-run
	# from a threat on the far side of the level.
	var calm := _make()
	var distant := calm.flee(calm.position + Vector2(calm.flee_radius + 200.0, 0.0))
	expect(distant.length() < 0.01,
		"a distant threat leaves a resting agent alone (%.1f)" % distant.length())

	# Standing exactly on the threat is the degenerate case: there is no
	# direction to flee in, so it must not produce a force from a zero vector.
	var overlapping := _make()
	var on_top := overlapping.flee(overlapping.position)
	expect(on_top.length() < 0.01,
		"a threat in the same place produces no direction to run (%.1f)"
		% on_top.length())

	# And just inside the radius it does run.
	var alarmed := _make()
	var close := alarmed.flee(alarmed.position + Vector2(alarmed.flee_radius - 1.0, 0.0))
	expect(close.x < 0.0, "a threat just inside the radius sends it the other way")
	expect(close.length() > 1.0, "at speed (%.1f)" % close.length())

## Wander projects a circle ahead of where the agent is going.
##
## With the jitter turned off the whole thing is deterministic, which is the
## only way to say anything about *where* it steers rather than merely how hard.
func _test_wander_projects_a_circle_ahead_of_the_agent() -> void:
	print("the wander circle")
	var agent := _make()
	agent.position = Vector2(300.0, 300.0)
	agent.wander_jitter = 0.0

	# Moving downward, so "ahead" is down rather than the default right — which
	# is what separates reading the velocity from falling back to Vector2.RIGHT.
	agent.velocity = Vector2(0.0, 100.0)
	agent.wander_angle = PI            # circle point is to the left
	var force := agent.wander(0.016)
	expect(force.y > 0.0,
		"the circle is projected ahead of the agent, so it keeps going that way (%s)"
		% force)
	expect(force.x < 0.0,
		"and offset to the side the wander angle points (%s)" % force)

	# The angle is what moves the target round the circle: the other side of it
	# steers the other way.
	var mirrored := _make()
	mirrored.position = Vector2(300.0, 300.0)
	mirrored.wander_jitter = 0.0
	mirrored.velocity = Vector2(0.0, 100.0)
	mirrored.wander_angle = 0.0        # circle point is to the right
	var other := mirrored.wander(0.016)
	expect(other.x > 0.0, "the opposite angle steers the opposite way (%s)" % other)

	# A standing start has no heading to project from, so it uses a default
	# rather than dividing by a zero-length velocity.
	var still := _make()
	still.position = Vector2(300.0, 300.0)
	still.wander_jitter = 0.0
	still.wander_angle = 0.0
	still.velocity = Vector2.ZERO
	var first := still.wander(0.016)
	expect(first.length() > 0.0, "a resting agent still wanders somewhere (%s)" % first)
	expect(first.x > 0.0,
		"defaulting to straight ahead rather than nowhere (%s)" % first)

	# The jitter is what makes it aimless: with it on, the angle moves.
	var jittery := _make()
	jittery.wander_angle = 0.0
	var before: float = jittery.wander_angle
	for i in 20:
		jittery.wander(0.016)
	expect(jittery.wander_angle != before,
		"the wander angle drifts when the jitter is on (%.3f)" % jittery.wander_angle)
