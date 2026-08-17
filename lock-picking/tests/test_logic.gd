extends Node

# Drives the real lock from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_a_new_lock_starts_shut()
	_test_the_pick_is_hidden_somewhere_reachable()
	_test_dragging_turns_the_cylinder()
	_test_the_cylinder_turns_the_long_way_round()
	_test_dragging_needs_the_button_held()
	_test_tension_builds_near_the_sweet_spot()
	_test_tension_drains_away_from_it()
	_test_enough_tension_unlocks()
	_test_an_open_lock_stops_simulating()
	_test_space_starts_a_fresh_lock()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[lock-picking] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _press(m: Node2D, at_x: float, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = Vector2(at_x, 240.0)
	m._input(e)

func _drag_to(m: Node2D, x: float) -> void:
	var e := InputEventMouseMotion.new()
	e.position = Vector2(x, 240.0)
	m._input(e)

func _key(m: Node2D, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._input(e)

## Park the cylinder exactly on the sweet spot, without dragging there.
func _line_up(m: Node2D) -> void:
	m._current_angle = m._correct_angle

func _test_a_new_lock_starts_shut() -> void:
	print("a fresh lock")
	var m := _make()
	expect(not m._unlocked, "the lock starts shut")
	expect(is_zero_approx(m._tension), "with no tension on the pick")
	expect(is_zero_approx(m._current_angle), "and the cylinder at rest")

func _test_the_pick_is_hidden_somewhere_reachable() -> void:
	print("where the sweet spot is")
	# Every lock should be pickable, and they should not all be the same lock.
	var seen := {}
	for i in 12:
		var m := _make()
		expect(absf(m._correct_angle) <= 180.0, "the sweet spot is a reachable angle")
		seen[roundi(m._correct_angle)] = true
	expect(seen.size() > 1, "and a new lock is not always in the same place")

func _test_dragging_turns_the_cylinder() -> void:
	print("dragging")
	var m := _make()
	_press(m, 300.0, true)
	_drag_to(m, 400.0)
	expect(m._current_angle > 0.0, "dragging right turns the cylinder one way")

	var back := _make()
	_press(back, 300.0, true)
	_drag_to(back, 200.0)
	expect(back._current_angle < 0.0, "and dragging left turns it the other")

	# The turn follows how far the mouse moved, not where it ended up.
	var far := _make()
	_press(far, 300.0, true)
	_drag_to(far, 340.0)
	var small: float = far._current_angle
	_drag_to(far, 440.0)
	expect(far._current_angle > small, "a longer drag turns it further")

func _test_the_cylinder_turns_the_long_way_round() -> void:
	print("wrapping")
	var m := _make()
	_press(m, 0.0, true)
	# Far enough to go past half a turn — the angle has to wrap, not run away.
	for i in 20:
		_drag_to(m, float(i + 1) * 100.0)
	expect(absf(m._current_angle) <= 180.0, "the angle wraps instead of growing forever")

func _test_dragging_needs_the_button_held() -> void:
	print("hovering")
	var m := _make()
	_drag_to(m, 500.0)
	expect(is_zero_approx(m._current_angle), "moving the mouse without holding it does nothing")

	_press(m, 300.0, true)
	_drag_to(m, 400.0)
	var turned: float = m._current_angle
	_press(m, 400.0, false)
	_drag_to(m, 600.0)
	expect(is_equal_approx(m._current_angle, turned), "and letting go stops the turning")

func _test_tension_builds_near_the_sweet_spot() -> void:
	print("finding the sweet spot")
	var m := _make()
	_line_up(m)
	m._process(STEP)
	expect(m._tension > 0.0, "holding the cylinder on the sweet spot builds tension")

	# Just inside the tolerance still counts — that margin is what makes the
	# lock pickable by feel rather than by luck.
	var edge := _make()
	edge._current_angle = wrapf(edge._correct_angle + edge.TOLERANCE * 0.8, -180.0, 180.0)
	edge._process(STEP)
	expect(edge._tension > 0.0, "and so does being just inside the tolerance")

func _test_tension_drains_away_from_it() -> void:
	print("losing it")
	var m := _make()
	_line_up(m)
	for i in 10:
		m._process(STEP)
	var held: float = m._tension
	expect(held > 0.0, "tension built up")

	m._current_angle = wrapf(m._correct_angle + m.TOLERANCE * 2.0, -180.0, 180.0)
	m._process(STEP)
	expect(m._tension < held, "turning off the sweet spot loses it again")

	for i in 120:
		m._process(STEP)
	expect(is_zero_approx(m._tension), "and it drains to nothing rather than going negative")
	expect(m.DRAIN_SPEED > m.FILL_SPEED, "losing tension is quicker than building it")

func _test_enough_tension_unlocks() -> void:
	print("picking it")
	var m := _make()
	_line_up(m)
	for i in 120:
		m._process(STEP)
	expect(m._unlocked, "holding the sweet spot long enough opens the lock")
	expect(m._tension <= 1.0, "and tension stops at full rather than overshooting")

func _test_an_open_lock_stops_simulating() -> void:
	print("once it is open")
	var m := _make()
	_line_up(m)
	for i in 120:
		m._process(STEP)
	expect(m._unlocked, "the lock is open")

	var angle: float = m._current_angle
	_press(m, 300.0, true)
	_drag_to(m, 500.0)
	expect(is_equal_approx(m._current_angle, angle), "the cylinder no longer turns")
	m._current_angle = wrapf(m._correct_angle + 90.0, -180.0, 180.0)
	m._process(STEP)
	expect(m._unlocked, "and it does not re-lock itself")

func _test_space_starts_a_fresh_lock() -> void:
	print("the next lock")
	var m := _make()
	_line_up(m)
	for i in 120:
		m._process(STEP)
	expect(m._unlocked, "picked the first lock")

	var attempts: int = m._attempts
	_key(m, KEY_SPACE)
	expect(not m._unlocked, "space sets up a new lock")
	expect(is_zero_approx(m._tension), "with the tension released")
	expect(is_zero_approx(m._current_angle), "and the cylinder back at rest")
	expect(m._attempts == attempts + 1, "counting the one just picked")
