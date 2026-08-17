extends Node

# Drives the real Boid from scripts/boid.gd. The previous suite recomputed the
# three steering rules inline, so any of them could be inverted in the real
# script without an assertion failing — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_isolated_boid_holds_course()
	_test_speed_is_clamped_to_max()
	_test_speed_is_raised_to_min()
	_test_separation_pushes_apart()
	_test_alignment_matches_heading()
	_test_cohesion_pulls_together()
	_test_neighbours_beyond_radius_are_ignored()
	_test_self_is_not_its_own_neighbour()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[boid-flocking] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/boid.gd")

# init() randomises the heading, so tests set position and vel directly to keep
# every case deterministic.
func _make(pos: Vector2, vel: Vector2) -> Node2D:
	var boid := Node2D.new()
	boid.set_script(_script)
	add_child(boid)
	boid.position = pos
	boid.vel = vel
	return boid

func _test_isolated_boid_holds_course() -> void:
	print("a boid with no neighbours")
	var b := _make(Vector2(300, 300), Vector2(100, 0))
	b.step([b], STEP)
	expect(b.vel.normalized().is_equal_approx(Vector2.RIGHT),
		"with nobody in range the heading is unchanged")

func _test_speed_is_clamped_to_max() -> void:
	print("maximum speed")
	var b := _make(Vector2(300, 300), Vector2(9999, 0))
	b.step([b], STEP)
	expect(is_equal_approx(b.vel.length(), b.MAX_SPEED), "speed is clamped down to MAX_SPEED")

func _test_speed_is_raised_to_min() -> void:
	print("minimum speed")
	# A near-stationary boid is pushed back up, so the flock never stalls.
	var b := _make(Vector2(300, 300), Vector2(1.0, 0))
	b.step([b], STEP)
	expect(is_equal_approx(b.vel.length(), b.MIN_SPEED), "speed is raised to MIN_SPEED")

func _test_separation_pushes_apart() -> void:
	print("separation")
	# Cohesion pulls toward a neighbour far harder than separation pushes away,
	# so "moves away" is not the property to assert. What separation actually
	# guarantees is a *relative* difference: a neighbour inside SEP_RADIUS damps
	# the approach that a neighbour just outside it does not.
	var close_a := _make(Vector2(300, 300), Vector2(100, 0))
	var close_b := _make(Vector2(300 + 10, 300), Vector2(100, 0))
	close_a.step([close_a, close_b], STEP)

	var far_a := _make(Vector2(300, 300), Vector2(100, 0))
	var far_b := _make(Vector2(300 + 40, 300), Vector2(100, 0))   # outside SEP_RADIUS
	far_a.step([far_a, far_b], STEP)

	expect(close_a.vel.x < far_a.vel.x,
		"a neighbour inside SEP_RADIUS damps the approach; one outside it does not")

func _test_alignment_matches_heading() -> void:
	print("alignment")
	# A neighbour inside NEIGHBOR_RADIUS but outside SEP_RADIUS, heading down.
	# Separation is not involved, so alignment should turn us toward it.
	var a := _make(Vector2(300, 300), Vector2(100, 0))
	var b := _make(Vector2(300 + 50, 300), Vector2(0, 100))
	a.step([a, b], STEP)
	expect(a.vel.y > 0.0, "the boid turns toward its neighbour's heading")

func _test_cohesion_pulls_together() -> void:
	print("cohesion")
	# A neighbour off to one side, at a distance where separation does not apply.
	var a := _make(Vector2(300, 300), Vector2(100, 0))
	var b := _make(Vector2(300, 300 + 50), Vector2(100, 0))
	a.step([a, b], STEP)
	expect(a.vel.y > 0.0, "the boid steers toward the flock's centre")

func _test_neighbours_beyond_radius_are_ignored() -> void:
	print("neighbour radius")
	var a := _make(Vector2(300, 300), Vector2(100, 0))
	var far := _make(Vector2(300, 300 + 400), Vector2(0, -100))
	a.step([a, far], STEP)
	expect(a.vel.normalized().is_equal_approx(Vector2.RIGHT),
		"a boid beyond NEIGHBOR_RADIUS exerts no influence")

func _test_self_is_not_its_own_neighbour() -> void:
	print("self exclusion")
	# Distance to self is zero; counting it would divide by zero or pin the boid.
	var a := _make(Vector2(300, 300), Vector2(100, 0))
	a.step([a], STEP)
	expect(is_finite(a.vel.x) and is_finite(a.vel.y),
		"a boid does not treat itself as a neighbour, so no NaN appears")
