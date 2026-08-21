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
	_test_cohesion_steers_toward_the_centre_not_away_from_the_origin()
	await _test_the_flock_wraps_at_every_edge()
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

## Cohesion aims at the flock's centre, which is a direction *from* the boid.
##
## The test above puts the neighbour below and to the same side of the origin,
## where the centre minus the position and the centre plus the position both
## point downward — so a sum passes for a difference. A flock up and to the left
## separates them: the difference points up-left, the sum points down-right.
func _test_cohesion_steers_toward_the_centre_not_away_from_the_origin() -> void:
	print("cohesion direction")
	var a := _make(Vector2(500, 400), Vector2(0, 0))
	var up_left := _make(Vector2(460, 350), Vector2(0, 0))
	a.step([a, up_left], STEP)
	expect(a.vel.y < 0.0,
		"a flock above steers the boid up (%s)" % a.vel)
	expect(a.vel.x < 0.0, "and one to the left steers it left (%s)" % a.vel)

	# The mirror: a flock below and to the right steers the other way, so the
	# rule is following the flock rather than a fixed direction.
	var b := _make(Vector2(500, 400), Vector2(0, 0))
	var down_right := _make(Vector2(540, 450), Vector2(0, 0))
	b.step([b, down_right], STEP)
	expect(b.vel.y > 0.0 and b.vel.x > 0.0,
		"and a flock below-right steers down-right (%s)" % b.vel)

## A boid leaving one edge comes back in at the opposite one.
##
## Four separate comparisons, one per edge, and none of them was driven. Any one
## flipped leaves a boid that either never wraps on that side — drifting off
## screen for good — or wraps on every frame, pinned to the edge.
func _test_the_flock_wraps_at_every_edge() -> void:
	print("wrapping")
	get_window().size = Vector2i(640, 480)
	await get_tree().process_frame
	var vp: Vector2 = get_viewport().get_visible_rect().size
	expect(vp.x > 100.0 and vp.y > 100.0,
		"the test viewport is a real size to wrap within (%s)" % vp)

	var edges := [
		["left", Vector2(2.0, vp.y * 0.5), Vector2(-200.0, 0.0), "x", vp.x * 0.5],
		["right", Vector2(vp.x - 2.0, vp.y * 0.5), Vector2(200.0, 0.0), "x", vp.x * 0.5],
		["top", Vector2(vp.x * 0.5, 2.0), Vector2(0.0, -200.0), "y", vp.y * 0.5],
		["bottom", Vector2(vp.x * 0.5, vp.y - 2.0), Vector2(0.0, 200.0), "y", vp.y * 0.5],
	]
	var quiet := 0
	for e in edges:
		var boid := _make(e[1], e[2])
		var before: float = boid.position.x if e[3] == "x" else boid.position.y
		boid.step([boid], STEP)
		var after: float = boid.position.x if e[3] == "x" else boid.position.y
		# It crossed to the far side: the coordinate jumped past the middle.
		if not ((before < float(e[4])) != (after < float(e[4]))):
			quiet += 1
			print("    (", e[0], ": did not wrap, ", before, " -> ", after, ")")
	expect(quiet == 0, "a boid leaving any edge reappears at the opposite one")

	# And a boid in open space is left where it is, rather than being wrapped
	# every frame — which is what a comparison the wrong way round produces.
	var middle := _make(Vector2(vp.x * 0.5, vp.y * 0.5), Vector2(60.0, 40.0))
	var start: Vector2 = middle.position
	middle.step([middle], STEP)
	expect(middle.position.distance_to(start) < 10.0,
		"a boid in the middle just moves (%s -> %s)" % [start, middle.position])
	expect(middle.position.x > start.x and middle.position.y > start.y,
		"in the direction it was going")
