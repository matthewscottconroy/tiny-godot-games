extends Node

# Drives the real platform from scripts/moving_platform.gd — see
# docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_starts_at_its_origin()
	_test_first_move_follows_the_axis()
	_test_oscillates_about_the_origin()
	_test_stays_within_amplitude()
	_test_completes_one_period()
	_test_moves_along_its_axis_only()
	_test_axis_is_normalised()
	_test_constant_linear_velocity_tracks_motion()
	_test_velocity_reverses_with_direction()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[moving-platforms] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/moving_platform.gd")

func _make(axis := Vector2(0, 1), amplitude := 80.0, period := 2.5) -> StaticBody2D:
	var p := StaticBody2D.new()
	p.set_script(_script)
	p.position = Vector2(300, 200)
	add_child(p)          # _ready() records the origin
	p.axis = axis
	p.amplitude = amplitude
	p.period = period
	return p

func _test_starts_at_its_origin() -> void:
	print("origin")
	var p := _make()
	# sin(0) is 0, so the first step must not jump the platform anywhere.
	p._physics_process(STEP)
	expect(p.position.distance_to(Vector2(300, 200)) < 20.0,
		"the platform starts near where it was placed")

func _test_first_move_follows_the_axis() -> void:
	print("initial direction")
	# sin() is positive just after zero, so the first movement must be ALONG the
	# axis, not against it. Without this, offsetting the wrong way still
	# oscillates symmetrically and looks identical over time.
	var p := _make(Vector2(0, 1), 80.0, 2.5)
	p._physics_process(STEP)
	expect(p.position.y > 200.0, "a +Y axis moves the platform down first")

	var up := _make(Vector2(0, -1), 80.0, 2.5)
	up._physics_process(STEP)
	expect(up.position.y < 200.0, "and a -Y axis moves it up first")

func _test_oscillates_about_the_origin() -> void:
	print("oscillation")
	var p := _make()
	var lowest := INF
	var highest := -INF
	for i in 300:
		p._physics_process(STEP)
		lowest = minf(lowest, p.position.y)
		highest = maxf(highest, p.position.y)
	expect(highest > 200.0, "it travels one way past the origin")
	expect(lowest < 200.0, "and the other way too — it oscillates rather than drifting")

func _test_stays_within_amplitude() -> void:
	print("amplitude")
	var p := _make(Vector2(0, 1), 50.0)
	for i in 400:
		p._physics_process(STEP)
		expect(absf(p.position.y - 200.0) <= 50.0 + 0.001,
			"never travels further than the amplitude")
		if i > 8:
			break                      # a few frames is enough to catch an overshoot

func _test_completes_one_period() -> void:
	print("period")
	var period := 1.0
	var p := _make(Vector2(0, 1), 60.0, period)
	# After exactly one period it should be back where it started.
	var frames := int(period / STEP)
	for i in frames:
		p._physics_process(STEP)
	expect(absf(p.position.y - 200.0) < 3.0,
		"after one full period it is back at the origin")

func _test_moves_along_its_axis_only() -> void:
	print("axis")
	var vertical := _make(Vector2(0, 1))
	for i in 30:
		vertical._physics_process(STEP)
	expect(is_equal_approx(vertical.position.x, 300.0), "a vertical platform does not drift sideways")

	var horizontal := _make(Vector2(1, 0))
	for i in 30:
		horizontal._physics_process(STEP)
	expect(is_equal_approx(horizontal.position.y, 200.0), "a horizontal one does not drift vertically")
	expect(horizontal.position.x != 300.0, "but it does move")

func _test_axis_is_normalised() -> void:
	print("axis length")
	# An un-normalised axis would scale the amplitude by its length.
	var long_axis := _make(Vector2(0, 5), 40.0)
	for i in 200:
		long_axis._physics_process(STEP)
		expect(absf(long_axis.position.y - 200.0) <= 40.0 + 0.001,
			"a long axis vector does not multiply the travel")
		if i > 30:
			break

func _test_constant_linear_velocity_tracks_motion() -> void:
	print("carrying the player")
	# This is the whole point of the demo: a StaticBody2D carries a
	# CharacterBody2D only if constant_linear_velocity reports its motion.
	var p := _make()
	p._physics_process(STEP)
	var before: Vector2 = p.position
	p._physics_process(STEP)
	var moved: Vector2 = p.position - before
	expect(p.constant_linear_velocity.length() > 0.0, "the platform reports a velocity")
	expect(p.constant_linear_velocity.is_equal_approx(moved / STEP),
		"and it equals the distance actually travelled over the step")

func _test_velocity_reverses_with_direction() -> void:
	print("velocity sign")
	var p := _make(Vector2(0, 1), 80.0, 0.5)
	var signs := {}
	for i in 60:
		p._physics_process(STEP)
		signs[signf(p.constant_linear_velocity.y)] = true
	expect(signs.has(1.0) and signs.has(-1.0),
		"the reported velocity reverses as the platform turns round")
