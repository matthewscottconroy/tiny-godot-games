extends Node

# Drives the real RingLayout from scripts/ring_layout.gd. The layout maths lives
# in static functions precisely so it can be tested without an editor.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_empty_and_single()
	test_full_ring_does_not_double_up()
	test_partial_arc_occupies_both_ends()
	test_radius_is_respected()
	test_start_angle_rotates_the_whole_ring()
	test_even_spacing()
	test_rotations_point_outward()
	test_setters_clamp()
	test_apply_positions_children()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[tool-script] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func test_empty_and_single() -> void:
	print("degenerate counts")
	expect(RingLayout.positions_for(0, 100.0, 0.0, 1.0).is_empty(), "zero children produce no slots")
	expect(RingLayout.positions_for(-3, 100.0, 0.0, 1.0).is_empty(), "a negative count is not an error")
	var one := RingLayout.positions_for(1, 100.0, 0.0, 1.0)
	expect(one.size() == 1, "one child gets one slot")
	expect(one[0].is_equal_approx(Vector2(100, 0)), "and sits at the start angle")

func test_full_ring_does_not_double_up() -> void:
	print("a full ring wraps")
	var p := RingLayout.positions_for(4, 100.0, 0.0, 1.0)
	# With a full turn the last slot must not land on the first — that is the
	# off-by-one that puts two objects on top of each other.
	expect(p.size() == 4, "four slots")
	expect(p[0].distance_to(p[3]) > 1.0, "the last slot is not on top of the first")
	expect(p[0].is_equal_approx(Vector2(100, 0)), "the first is at angle 0")
	expect(p[1].is_equal_approx(Vector2(0, 100)), "the second is a quarter turn round")

func test_partial_arc_occupies_both_ends() -> void:
	print("a partial arc does not wrap")
	# Half a turn across 3 slots should put one at each end and one in the middle.
	var p := RingLayout.positions_for(3, 100.0, 0.0, 0.5)
	expect(p[0].is_equal_approx(Vector2(100, 0)), "the first is at the start of the arc")
	expect(p[2].is_equal_approx(Vector2(-100, 0)), "the last is at the end of the arc")
	expect(p[1].is_equal_approx(Vector2(0, 100)), "the middle is halfway along")

func test_radius_is_respected() -> void:
	print("radius")
	for p in RingLayout.positions_for(8, 75.0, 30.0, 1.0):
		expect(is_equal_approx(p.length(), 75.0), "every slot sits on the radius")

func test_start_angle_rotates_the_whole_ring() -> void:
	print("start angle")
	var base := RingLayout.positions_for(6, 100.0, 0.0, 1.0)
	var turned := RingLayout.positions_for(6, 100.0, 90.0, 1.0)
	expect(turned[0].is_equal_approx(Vector2(0, 100)), "the first slot moves to the new start angle")
	expect(is_equal_approx(base[0].angle_to(turned[0]), PI / 2.0), "every slot rotates by the same amount")

func test_even_spacing() -> void:
	print("spacing is even")
	var p := RingLayout.positions_for(8, 100.0, 0.0, 1.0)
	var first_gap := p[0].distance_to(p[1])
	for i in range(1, p.size() - 1):
		expect(is_equal_approx(p[i].distance_to(p[i + 1]), first_gap),
			"gap %d matches the first" % i)

func test_rotations_point_outward() -> void:
	print("facing")
	var rot := RingLayout.rotations_for(4, 0.0, 1.0)
	expect(rot.size() == 4, "one rotation per slot")
	expect(is_equal_approx(rot[0], 0.0), "the slot at angle 0 faces right")
	expect(is_equal_approx(rot[1], PI / 2.0), "the slot a quarter turn round faces down")

func test_setters_clamp() -> void:
	print("exported setters guard their ranges")
	var ring := RingLayout.new()
	add_child(ring)
	ring.radius = -50.0
	expect(is_zero_approx(ring.radius), "a negative radius clamps to zero")
	ring.count = -4
	expect(ring.count == 0, "a negative count clamps to zero")
	ring.arc = 5.0
	expect(is_equal_approx(ring.arc, 1.0), "arc clamps to a full turn")
	ring.arc = 0.0
	expect(ring.arc >= 0.05, "arc has a lower bound, so the ring never collapses")

func test_apply_positions_children() -> void:
	print("_apply moves the real children")
	var ring := RingLayout.new()
	ring.radius = 50.0
	add_child(ring)
	for i in 4:
		ring.add_child(Node2D.new())
	ring.count = 4
	ring._apply()
	var expected := RingLayout.positions_for(4, 50.0, ring.start_angle, ring.arc)
	var children := ring.get_children()
	for i in 4:
		expect((children[i] as Node2D).position.is_equal_approx(expected[i]),
			"child %d sits on its slot" % i)
