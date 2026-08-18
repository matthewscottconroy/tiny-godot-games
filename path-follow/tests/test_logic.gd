extends Node

# Drives the real patrol from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_path_is_a_closed_circuit()
	_test_the_patrol_rides_the_path()
	_test_it_starts_on_the_path()
	_test_progress_advances_at_its_speed()
	_test_it_loops_rather_than_stopping_at_the_end()
	_test_it_stays_on_the_curve_all_the_way_round()
	_test_it_visits_the_whole_circuit()
	await _test_it_moves_on_its_own()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[path-follow] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _patrol(m: Node2D) -> PathFollow2D:
	return m.get_node("PatrolPath/Patrol")

func _curve(m: Node2D) -> Curve2D:
	return (m.get_node("PatrolPath") as Path2D).curve

func _test_the_path_is_a_closed_circuit() -> void:
	print("the path")
	var m := _make()
	var curve := _curve(m)
	expect(curve != null, "the path has a curve")
	expect(curve.point_count > 2, "with enough points to make a circuit")
	expect(curve.get_baked_length() > 100.0, "and real length to walk")

func _test_the_patrol_rides_the_path() -> void:
	print("the patrol")
	var m := _make()
	var patrol := _patrol(m)
	# A PathFollow2D outside a Path2D has nothing to follow and simply sits at
	# the origin.
	expect(patrol.get_parent() is Path2D, "the patrol is a child of the path")
	expect(patrol.speed > 0.0, "and has a speed to travel at")

func _test_it_starts_on_the_path() -> void:
	print("the start")
	var m := _make()
	var patrol := _patrol(m)
	expect(is_zero_approx(patrol.progress), "it starts at the beginning of the path")
	var start: Vector2 = _curve(m).sample_baked(0.0)
	expect(patrol.position.distance_to(start) < 1.0, "which puts it on the curve's first point")

func _test_progress_advances_at_its_speed() -> void:
	print("advancing")
	var m := _make()
	var patrol := _patrol(m)
	patrol._process(1.0)
	expect(is_equal_approx(patrol.progress, patrol.speed),
		"a second of travel covers a second's worth of path")

func _test_it_loops_rather_than_stopping_at_the_end() -> void:
	print("looping")
	var m := _make()
	var patrol := _patrol(m)
	expect(patrol.loop, "the patrol is set to loop")
	var length: float = _curve(m).get_baked_length()
	patrol.progress = length - 1.0
	patrol._process(1.0)
	# Without looping it would stop dead at the last point and stay there.
	expect(patrol.progress < length * 0.5,
		"walking past the end comes back round to the start (%.1f of %.1f)"
		% [patrol.progress, length])

func _test_it_stays_on_the_curve_all_the_way_round() -> void:
	print("staying on the path")
	var m := _make()
	var patrol := _patrol(m)
	var curve := _curve(m)
	var length: float = curve.get_baked_length()
	begin_quiet()
	for i in 40:
		patrol.progress = length * float(i) / 40.0
		var expected: Vector2 = curve.sample_baked(patrol.progress)
		expect_quiet(patrol.position.distance_to(expected) < 1.0,
			"at %.0f along the path the patrol is %.1f px off it"
			% [patrol.progress, patrol.position.distance_to(expected)])
	expect(_quiet_failures == 0, "the patrol sits on the curve the whole way round")

func _test_it_visits_the_whole_circuit() -> void:
	print("the circuit")
	var m := _make()
	var patrol := _patrol(m)
	var length: float = _curve(m).get_baked_length()
	var box := Rect2(patrol.position, Vector2.ZERO)
	for i in 60:
		patrol.progress = length * float(i) / 60.0
		box = box.expand(patrol.position)
	# A patrol that only wanders round one corner is not patrolling.
	expect(box.size.x > 200.0 and box.size.y > 150.0,
		"the route covers a real area of the screen (%s)" % box.size)

func _test_it_moves_on_its_own() -> void:
	print("under its own steam")
	var m := _make()
	var patrol := _patrol(m)
	var start: Vector2 = patrol.position
	for i in 30:
		await get_tree().process_frame
	expect(patrol.progress > 0.0, "the patrol advances without being pushed")
	expect(patrol.position.distance_to(start) > 1.0, "and moves along the path as it does")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
