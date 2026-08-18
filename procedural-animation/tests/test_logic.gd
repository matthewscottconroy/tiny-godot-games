extends Node

# Drives the real FABRIK solver from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_chain_starts_laid_out()
	_test_the_tail_stays_on_the_base()
	_test_the_segments_keep_their_length()
	_test_the_head_reaches_a_target_within_range()
	_test_an_out_of_range_target_stretches_towards_it()
	_test_the_chain_follows_a_moving_target()
	_test_the_solver_settles()
	_test_a_target_on_the_base_does_not_break_it()
	_test_the_mouse_sets_the_target()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[procedural-animation] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

## Solve for a target, without going through the mouse.
func _solve_for(m: Node2D, target: Vector2) -> void:
	m._target = target
	m._fabrik_solve()

func _worst_segment_error(m: Node2D) -> float:
	var worst := 0.0
	for i in m.N:
		worst = maxf(worst, absf(m._joints[i].distance_to(m._joints[i + 1]) - m.SEG_LEN))
	return worst

func _reach(m: Node2D) -> float:
	return m.SEG_LEN * m.N

func _test_the_chain_starts_laid_out() -> void:
	print("the chain")
	var m := _make()
	expect(m._joints.size() == m.N + 1, "there is a joint at each end of every segment")
	expect(_worst_segment_error(m) < 0.001, "laid out one segment length apart")
	# Hanging down from the base, which is what is on screen before the mouse
	# is moved — laid out the other way it starts off the top of the window.
	expect(m._joints[m.N].y > m._joints[0].y, "hanging down from the head")
	expect(m._joints[0].is_equal_approx(m._base), "with the head at the base to begin with")

func _test_the_tail_stays_on_the_base() -> void:
	print("the anchor")
	var m := _make()
	begin_quiet()
	for target in [Vector2(100.0, 100.0), Vector2(600.0, 300.0), Vector2(320.0, 460.0)]:
		_solve_for(m, target)
		expect_quiet(m._joints[m.N].is_equal_approx(m._base),
			"the tail left the base reaching for %s" % target)
	expect(_quiet_failures == 0, "the tail stays pinned to the base wherever the head goes")

func _test_the_segments_keep_their_length() -> void:
	print("segment lengths")
	var m := _make()
	begin_quiet()
	for target in [Vector2(100.0, 100.0), Vector2(600.0, 420.0), Vector2(320.0, 240.0)]:
		_solve_for(m, target)
		expect_quiet(_worst_segment_error(m) < 1.0,
			"reaching %s stretched a segment by %.2f px" % [target, _worst_segment_error(m)])
	expect(_quiet_failures == 0, "no segment stretches, whatever the chain is reaching for")

func _test_the_head_reaches_a_target_within_range() -> void:
	print("reaching")
	var m := _make()
	# Comfortably inside the chain's reach, so it should arrive rather than
	# merely point — and off to the sides as well as straight ahead, where a
	# solver that is subtly wrong still lands within a pixel.
	var offsets := [
		Vector2(0.0, -_reach(m) * 0.5),
		Vector2(_reach(m) * 0.5, -_reach(m) * 0.3),
		Vector2(-_reach(m) * 0.6, 0.0),
		Vector2(_reach(m) * 0.2, _reach(m) * 0.4),
	]
	begin_quiet()
	for offset in offsets:
		var target: Vector2 = m._base + offset
		_solve_for(m, target)
		var miss: float = m._joints[0].distance_to(target)
		expect_quiet(miss < 1.0, "the head lands %.2f px from a target at %s" % [miss, offset])
	expect(_quiet_failures == 0, "the head arrives at any target inside the chain's reach")

func _test_an_out_of_range_target_stretches_towards_it() -> void:
	print("out of reach")
	var m := _make()
	var far: Vector2 = m._base + Vector2(0.0, -_reach(m) * 3.0)
	_solve_for(m, far)
	# It cannot arrive, but it should straighten out pointing that way rather
	# than curling up or coming apart.
	expect(m._joints[0].distance_to(far) > 1.0, "the head cannot reach a target beyond the chain")
	expect(_worst_segment_error(m) < 1.0, "and does not stretch trying")
	expect(m._joints[0].distance_to(m._base) > _reach(m) * 0.9,
		"the chain straightens out towards it instead")

func _test_the_chain_follows_a_moving_target() -> void:
	print("following")
	var m := _make()
	var first: Vector2 = m._base + Vector2(-100.0, -100.0)
	_solve_for(m, first)
	var head_left: Vector2 = m._joints[0]
	var second: Vector2 = m._base + Vector2(100.0, -100.0)
	_solve_for(m, second)
	expect(m._joints[0].x > head_left.x, "the head follows the target across")

func _test_the_solver_settles() -> void:
	print("settling")
	var m := _make()
	var target: Vector2 = m._base + Vector2(60.0, -120.0)
	_solve_for(m, target)
	var settled: PackedVector2Array = m._joints.duplicate()
	_solve_for(m, target)
	var moved := 0.0
	for i in m._joints.size():
		moved = maxf(moved, m._joints[i].distance_to(settled[i]))
	# Solving again for the same target should barely move anything; a solver
	# that keeps wandering makes the limb jitter while the mouse is still.
	expect(moved < 1.0, "solving again for the same target barely moves the chain (%.2f px)" % moved)

func _test_a_target_on_the_base_does_not_break_it() -> void:
	print("a degenerate target")
	var m := _make()
	# Normalising a zero-length difference is a division by zero, and a NaN
	# joint never comes back.
	_solve_for(m, m._base)
	var sane := true
	for joint in m._joints:
		if is_nan(joint.x) or is_nan(joint.y):
			sane = false
	expect(sane, "a target on the base leaves every joint a real position")
	expect(m._joints[m.N].is_equal_approx(m._base), "with the tail still anchored")

func _test_the_mouse_sets_the_target() -> void:
	print("the mouse")
	var m := _make()
	var e := InputEventMouseMotion.new()
	e.position = Vector2(200.0, 150.0)
	m._input(e)
	expect(m._target == Vector2(200.0, 150.0), "moving the mouse sets the target")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
