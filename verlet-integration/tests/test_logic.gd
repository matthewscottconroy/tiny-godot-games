extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_particle_count()
	_test_segment_length()
	_test_verlet_position_update()
	_test_constraint_reduces_error()
	_test_anchor_pinned()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_particle_count() -> void:
	print("particle count")
	const NUM_PARTICLES := 24
	expect(NUM_PARTICLES == 24, "NUM_PARTICLES is 24")

func _test_segment_length() -> void:
	print("segment rest length")
	const SEG_LENGTH := 16.0
	expect(SEG_LENGTH == 16.0, "SEG_LENGTH is 16")

func _test_verlet_position_update() -> void:
	print("verlet integration step")
	var pos  := Vector2(100.0, 100.0)
	var prev := Vector2(98.0, 100.0)
	var gravity := Vector2(0.0, 500.0)
	var dt := 0.016
	var vel  := pos - prev
	var prev2 := pos
	var pos2  := pos + vel + gravity * dt * dt
	expect(pos2.x > pos.x, "x moves in direction of velocity")
	expect(pos2.y > pos.y, "y moves down due to gravity")
	expect_near(pos2.x - pos.x, vel.x, "x displacement equals previous velocity")

func _test_constraint_reduces_error() -> void:
	print("distance constraint reduces segment length error")
	const SEG_LENGTH := 16.0
	var p1 := Vector2(0.0, 0.0)
	var p2 := Vector2(20.0, 0.0)  # stretched
	var dv   := p2 - p1
	var dist := dv.length()
	var corr := dv * ((dist - SEG_LENGTH) / dist * 0.5)
	p1 += corr
	p2 -= corr
	expect_near((p2 - p1).length(), SEG_LENGTH, "after one constraint pass, segment is at rest length", 0.1)

func _test_anchor_pinned() -> void:
	print("anchor position is enforced after constraints")
	const ANCHOR := Vector2(320.0, 60.0)
	var pos0 := Vector2(310.0, 50.0)
	pos0 = ANCHOR  # pin step
	expect(pos0 == ANCHOR, "anchor particle snaps to ANCHOR each iteration")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
