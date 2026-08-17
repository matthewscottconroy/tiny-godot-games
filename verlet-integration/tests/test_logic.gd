extends Node

# Drives the real simulation from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_rope_starts_where_it_was_built()
	_test_the_anchor_never_moves()
	_test_the_rope_falls()
	_test_the_segments_settle_to_their_length()
	_test_a_stretched_rope_is_pulled_back_in()
	_test_the_simulation_stays_finite()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[verlet-integration] %d/%d passed" % [_pass, _pass + _fail]
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

func _worst_segment_error(m: Node2D) -> float:
	var worst := 0.0
	for i in m.NUM_PARTICLES - 1:
		var length: float = m._pos[i].distance_to(m._pos[i + 1])
		worst = maxf(worst, absf(length - m.SEG_LENGTH))
	return worst

func _test_the_rope_starts_where_it_was_built() -> void:
	print("initial state")
	var m := _make()
	expect(m._pos.size() == m.NUM_PARTICLES, "every particle has a position")
	expect(m._prev.size() == m.NUM_PARTICLES, "and a previous one — that pair is the velocity")
	var at_rest := true
	for i in m.NUM_PARTICLES:
		if m._pos[i] != m._prev[i]:
			at_rest = false
	expect(at_rest, "position and previous start equal, so the rope starts at rest")

func _test_the_anchor_never_moves() -> void:
	print("the anchor")
	var m := _make()
	_run(m, 120)
	expect(m._pos[0] == m.ANCHOR, "particle 0 is pinned to the anchor whatever the rope does")

func _test_the_rope_falls() -> void:
	print("gravity")
	var m := _make()
	var tip_before: float = m._pos[m.NUM_PARTICLES - 1].y
	_run(m, 60)
	expect(m._pos[m.NUM_PARTICLES - 1].y > tip_before, "the free end falls")
	expect(m.GRAVITY.y > 0.0, "because gravity points down the screen")

func _test_the_segments_settle_to_their_length() -> void:
	print("the constraint")
	var m := _make()
	_run(m, 240)
	# This is the whole point of the relaxation pass: positions are moved
	# directly, and the segment lengths are what that has to preserve.
	expect(_worst_segment_error(m) < 1.0,
		"every segment settles within a pixel of SEG_LENGTH (worst %.2f)" % _worst_segment_error(m))

func _test_a_stretched_rope_is_pulled_back_in() -> void:
	print("recovery")
	var m := _make()
	_run(m, 60)
	# Yank the free end far away, as dragging it with the mouse would.
	var last: int = m.NUM_PARTICLES - 1
	m._pos[last] = m.ANCHOR + Vector2(600.0, 600.0)
	var stretched := _worst_segment_error(m)
	expect(stretched > 10.0, "the rope is badly stretched")
	_run(m, 120)
	expect(_worst_segment_error(m) < stretched, "and the constraint pulls it back together")

func _test_the_simulation_stays_finite() -> void:
	print("stability")
	var m := _make()
	_run(m, 600)
	var sane := true
	for i in m.NUM_PARTICLES:
		var p: Vector2 = m._pos[i]
		if is_nan(p.x) or is_nan(p.y) or absf(p.x) > 100000.0 or absf(p.y) > 100000.0:
			sane = false
	expect(sane, "ten seconds of simulation does not blow the rope up")
	expect(m._pos[m.NUM_PARTICLES - 1].distance_to(m.ANCHOR) <= m.SEG_LENGTH * m.NUM_PARTICLES + 1.0,
		"and the rope cannot end up longer than its segments allow")
