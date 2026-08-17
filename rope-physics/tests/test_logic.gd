extends Node

# Drives the real simulation from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_rope_starts_straight_and_still()
	_test_the_anchor_stays_put()
	_test_the_rope_falls_and_holds_together()
	_test_damping_takes_energy_out()
	_test_grabbing_a_point_moves_it()
	_test_a_held_point_is_not_dragged_by_the_rope()
	_test_releasing_lets_go()
	_test_r_resets_the_rope()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[rope-physics] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _run(m: Node2D, frames: int) -> void:
	for i in frames:
		m._physics_process(STEP)

func _click(m: Node2D, at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	m._input(e)

func _move_mouse(m: Node2D, to: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = to
	m._input(e)

func _worst_segment_error(m: Node2D) -> float:
	var worst := 0.0
	for i in m.N - 1:
		worst = maxf(worst, absf(m._pos[i].distance_to(m._pos[i + 1]) - m.SEG_LEN))
	return worst

func _test_the_rope_starts_straight_and_still() -> void:
	print("initial state")
	var m := _make()
	expect(m._pos.size() == m.N, "every point has a position")
	expect(_worst_segment_error(m) < 0.001, "laid out straight, one segment length apart")
	var still := true
	for i in m.N:
		if m._pos[i] != m._prev[i]:
			still = false
	expect(still, "and at rest")

func _test_the_anchor_stays_put() -> void:
	print("the anchor")
	var m := _make()
	_run(m, 120)
	expect(m._pos[m._ANCHOR_IDX] == m._ANCHOR_POS, "the anchored end never moves")

func _test_the_rope_falls_and_holds_together() -> void:
	print("swinging")
	var m := _make()
	var tip_before: float = m._pos[m.N - 1].y
	_run(m, 90)
	expect(m._pos[m.N - 1].y > tip_before, "the free end swings down")
	expect(_worst_segment_error(m) < 1.0,
		"and the segments keep their length (worst %.2f)" % _worst_segment_error(m))

func _test_damping_takes_energy_out() -> void:
	print("damping")
	var m := _make()
	# A rope with no damping swings forever; this one has to settle.
	_run(m, 120)
	var early := 0.0
	for i in m.N:
		early = maxf(early, m._pos[i].distance_to(m._prev[i]))
	_run(m, 900)
	var late := 0.0
	for i in m.N:
		late = maxf(late, m._pos[i].distance_to(m._prev[i]))
	expect(late < early, "the rope loses speed over time rather than swinging forever")
	expect(m.DAMPING < 1.0, "which is what DAMPING below 1 buys")

func _test_grabbing_a_point_moves_it() -> void:
	print("dragging")
	var m := _make()
	var click_at: Vector2 = m._pos[7]
	_click(m, click_at, true)
	# The search takes the first point within 20 px, and the points start 12 px
	# apart, so the one picked up is a neighbour of the one clicked as often as
	# not. What matters is that it grabbed something under the cursor.
	expect(m._drag >= 0, "clicking near the rope picks up a point")
	expect(m._pos[m._drag].distance_to(click_at) < 20.0, "one that is under the cursor")

	var target := Vector2(500.0, 300.0)
	var held: int = m._drag
	_move_mouse(m, target)
	expect(m._pos[held] == target, "and the mouse carries it")

	var missed := _make()
	_click(missed, Vector2(10.0, 470.0), true)
	expect(missed._drag == -1, "clicking empty space picks up nothing")

	var anchor := _make()
	_click(anchor, anchor._ANCHOR_POS, true)
	expect(anchor._drag != anchor._ANCHOR_IDX, "and the anchor itself is never the held point")

func _test_a_held_point_is_not_dragged_by_the_rope() -> void:
	print("holding")
	var m := _make()
	_click(m, m._pos[7], true)
	var held: int = m._drag
	var target := Vector2(500.0, 300.0)
	_move_mouse(m, target)
	_run(m, 30)
	expect(m._pos[held] == target, "the rope's own weight cannot pull a held point away")
	expect(m._pos[m.N - 1].y > m._ANCHOR_POS.y, "while the rest of the rope hangs from it")

func _test_releasing_lets_go() -> void:
	print("releasing")
	var m := _make()
	_click(m, m._pos[7], true)
	var held: int = m._drag
	_move_mouse(m, Vector2(500.0, 300.0))
	_click(m, Vector2(500.0, 300.0), false)
	expect(m._drag == -1, "letting go clears the held point")
	_run(m, 30)
	expect(m._pos[held] != Vector2(500.0, 300.0), "after which the rope moves it again")

func _test_r_resets_the_rope() -> void:
	print("reset")
	var m := _make()
	_run(m, 120)
	expect(_worst_segment_error(m) < 1.0, "the rope has swung out")
	expect(m._pos[m.N - 1].y > m._ANCHOR_POS.y + 10.0, "and hangs below the anchor")

	var key := InputEventKey.new()
	key.keycode = KEY_R
	key.pressed = true
	m._input(key)
	expect(_worst_segment_error(m) < 0.001, "R lays the rope out straight again")
	var still := true
	for i in m.N:
		if m._pos[i] != m._prev[i]:
			still = false
	expect(still, "and at rest")
