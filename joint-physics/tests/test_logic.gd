extends Node

# Drives the real rig from scripts/main.gd — see docs/TEST_INTEGRITY.md.
#
# The joints are Godot's, so this checks the rig is built the way a pendulum and
# a spring need, and then lets the physics run to see it behave.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_pendulum_is_a_chain()
	_test_the_pendulum_hangs_from_a_fixed_anchor()
	_test_the_links_are_pinned_to_each_other()
	_test_the_first_link_is_offset_so_it_swings()
	_test_the_spring_is_slung_between_two_anchors()
	_test_the_spring_is_stretched_at_rest()
	await _test_the_pendulum_swings()
	await _test_the_chain_holds_together()
	await _test_clicking_kicks_the_pendulum()
	await _test_right_clicking_kicks_the_weight()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[joint-physics] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _joints(m: Node2D, type: String) -> Array[Node]:
	var found: Array[Node] = []
	for child in m.get_children():
		if child.get_class() == type:
			found.append(child)
	return found

func _click(m: Node2D, button: int) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.position = Vector2(320.0, 240.0)
	m._input(e)

func _test_the_pendulum_is_a_chain() -> void:
	print("the pendulum")
	var m := _make()
	expect(m._pend_bodies.size() == m.LINK_COUNT + 1, "an anchor plus a link per LINK_COUNT")
	for i in range(1, m._pend_bodies.size()):
		expect(m._pend_bodies[i] is RigidBody2D, "link %d is a body physics can move" % i)

func _test_the_pendulum_hangs_from_a_fixed_anchor() -> void:
	print("the anchor")
	var m := _make()
	# A pendulum hung from a movable body would simply fall.
	expect(m._pend_bodies[0] is StaticBody2D, "the top of the chain is fixed in place")
	expect(is_equal_approx(m._pend_bodies[0].position.y, m.PEND_ANCHOR_Y), "at the ceiling")

func _test_the_links_are_pinned_to_each_other() -> void:
	print("the pins")
	var m := _make()
	var pins := _joints(m, "PinJoint2D")
	expect(pins.size() == m.LINK_COUNT, "there is a pin per link")
	for pin in pins:
		expect_quiet(not (pin as PinJoint2D).node_a.is_empty(), "a pin names its upper body")
		expect_quiet(not (pin as PinJoint2D).node_b.is_empty(), "and its lower one")
	expect(_quiet_failures == 0, "every pin joins two bodies")

func _test_the_first_link_is_offset_so_it_swings() -> void:
	print("the starting nudge")
	var m := _make()
	# Hung dead straight, a pendulum sits there forever. The demo starts it
	# leaning so it has somewhere to fall.
	expect(not is_equal_approx(m._pend_bodies[1].position.x, m._pend_bodies[0].position.x),
		"the first link starts off to one side of the anchor")

func _test_the_spring_is_slung_between_two_anchors() -> void:
	print("the spring rig")
	var m := _make()
	expect(m._spring_left is StaticBody2D and m._spring_right is StaticBody2D,
		"the spring hangs from two fixed points")
	expect(m._spring_weight is RigidBody2D, "with a weight between them")
	expect(m._spring_weight.mass > 1.0, "heavy enough to stretch the springs")
	expect(_joints(m, "DampedSpringJoint2D").size() == 2, "and a spring to each anchor")

func _test_the_spring_is_stretched_at_rest() -> void:
	print("rest length")
	var m := _make()
	for joint in _joints(m, "DampedSpringJoint2D"):
		var spring := joint as DampedSpringJoint2D
		# A rest length shorter than the gap is what makes the springs pull;
		# equal lengths would leave the weight hanging slack.
		expect_quiet(spring.rest_length < spring.length, "a spring is stretched at rest")
		expect_quiet(spring.stiffness > 0.0, "and stiff enough to pull back")
		expect_quiet(spring.damping > 0.0, "with damping, so it settles")
	expect(_quiet_failures == 0, "both springs are stretched, stiff and damped")

func _test_the_pendulum_swings() -> void:
	print("swinging")
	var m := _make()
	var tip: RigidBody2D = m._pend_bodies[m._pend_bodies.size() - 1]
	var start: Vector2 = tip.position
	for i in 30:
		await get_tree().physics_frame
	expect(tip.position.distance_to(start) > 1.0, "the loose end of the chain moves under gravity")
	expect(m._pend_bodies[0].position.is_equal_approx(
		Vector2(m.PEND_X, m.PEND_ANCHOR_Y)), "while the anchor stays put")

func _test_the_chain_holds_together() -> void:
	print("the joints holding")
	var m := _make()
	for i in 30:
		await get_tree().physics_frame
	var apart := 0.0
	for i in range(1, m._pend_bodies.size()):
		apart = maxf(apart, m._pend_bodies[i].position.distance_to(m._pend_bodies[i - 1].position))
	# The pins hold the links roughly a link-spacing apart; a chain that has
	# come undone flies off across the screen.
	expect(apart < m.LINK_SPACING * 3.0,
		"the links stay joined rather than flying apart (worst gap %.0f px)" % apart)

func _test_clicking_kicks_the_pendulum() -> void:
	print("kicking the chain")
	# Measured against an untouched rig: an impulse goes to the physics server
	# and only shows up as velocity after a step, by which time gravity has
	# moved the chain too.
	var quiet := _make()
	var quiet_tip: RigidBody2D = quiet._pend_bodies[quiet._pend_bodies.size() - 1]
	for i in 5:
		await get_tree().physics_frame
	var drifting: Vector2 = quiet_tip.linear_velocity

	var m := _make()
	var tip: RigidBody2D = m._pend_bodies[m._pend_bodies.size() - 1]
	_click(m, MOUSE_BUTTON_LEFT)
	for i in 5:
		await get_tree().physics_frame
	expect(tip.linear_velocity.x > drifting.x, "a left click shoves the end of the chain sideways")
	expect(tip.linear_velocity.y < drifting.y, "and upwards, so the chain swings rather than sags")

func _test_right_clicking_kicks_the_weight() -> void:
	print("kicking the weight")
	var quiet := _make()
	for i in 5:
		await get_tree().physics_frame
	var settling: float = quiet._spring_weight.linear_velocity.y
	var quiet_tip: float = quiet._pend_bodies[quiet._pend_bodies.size() - 1].linear_velocity.x

	var m := _make()
	_click(m, MOUSE_BUTTON_RIGHT)
	for i in 5:
		await get_tree().physics_frame
	expect(m._spring_weight.linear_velocity.y < settling, "a right click throws the weight upwards")

	var tip: RigidBody2D = m._pend_bodies[m._pend_bodies.size() - 1]
	expect(is_equal_approx(tip.linear_velocity.x, quiet_tip),
		"and leaves the pendulum swinging as it was")

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
