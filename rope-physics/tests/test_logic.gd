extends Node

const N := 24
const SEG_LEN := 12.0
const GRAVITY := 600.0
const ITERS := 10
const _ANCHOR_IDX := 0
const _ANCHOR_POS := Vector2(320.0, 30.0)

var _pass := 0
var _fail := 0

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

func _ready() -> void:
	print("=== Rope Physics Tests ===")
	_test_constraint_shortens()
	_test_constraint_lengthens()
	_test_constraint_anchor_fixed()
	_test_verlet_gravity()
	_test_rope_length_preserved()
	_report()

func _apply_constraint(p0: Vector2, p1: Vector2, anchor_idx: int, drag_idx: int, i: int) -> Array:
	var diff := p1 - p0
	var dist := diff.length()
	if dist < 0.001:
		return [p0, p1]
	var correction := diff * (1.0 - SEG_LEN / dist) * 0.5
	if i != anchor_idx:
		p0 = p0 + correction
	if (i + 1) != drag_idx:
		p1 = p1 - correction
	return [p0, p1]

func _test_constraint_shortens() -> void:
	print("_test_constraint_shortens")
	# Two points too far apart: dist = 30, SEG_LEN = 12 → should move closer
	var p0 := Vector2(0.0, 0.0)
	var p1 := Vector2(30.0, 0.0)
	var result := _apply_constraint(p0, p1, -1, -1, 5)
	var new_dist: float = result[0].distance_to(result[1])
	expect(new_dist < 30.0, "constraint shortens distance when too far (30 → closer to 12)")
	expect(is_equal_approx(new_dist, SEG_LEN), "constraint reaches exact segment length")

func _test_constraint_lengthens() -> void:
	print("_test_constraint_lengthens")
	# Two points too close together: dist = 2, SEG_LEN = 12 → should push apart
	var p0 := Vector2(0.0, 0.0)
	var p1 := Vector2(2.0, 0.0)
	var result := _apply_constraint(p0, p1, -1, -1, 5)
	var new_dist: float = result[0].distance_to(result[1])
	expect(new_dist > 2.0, "constraint lengthens distance when too close (2 → closer to 12)")

func _test_constraint_anchor_fixed() -> void:
	print("_test_constraint_anchor_fixed")
	# Anchor point (i=0) should not move during constraint
	var anchor := Vector2(320.0, 30.0)
	var p1 := Vector2(400.0, 30.0)
	var result := _apply_constraint(anchor, p1, _ANCHOR_IDX, -1, _ANCHOR_IDX)
	expect(result[0].is_equal_approx(anchor), "anchor point stays fixed after constraint")

func _test_verlet_gravity() -> void:
	print("_test_verlet_gravity")
	# Single free point: start at rest, apply one verlet step with gravity
	var pos := Vector2(100.0, 100.0)
	var prev := Vector2(100.0, 100.0)
	var delta := 0.016  # ~60fps
	var vel := (pos - prev) * 0.985
	prev = pos
	pos = pos + vel + Vector2(0.0, GRAVITY) * delta * delta
	expect(pos.y > 100.0, "free point falls down under gravity after one Verlet step")

func _test_rope_length_preserved() -> void:
	print("_test_rope_length_preserved")
	# Initialize a straight rope, run many constraint iterations, check total length is ~(N-1)*SEG_LEN
	var pos: PackedVector2Array = PackedVector2Array()
	pos.resize(N)
	for i in N:
		pos[i] = _ANCHOR_POS + Vector2(float(i) * SEG_LEN, 0.0)

	# Run constraints many times (simulate settling)
	for _iter in 50:
		pos[_ANCHOR_IDX] = _ANCHOR_POS
		for i in N - 1:
			var diff := pos[i + 1] - pos[i]
			var dist := diff.length()
			if dist < 0.001:
				continue
			var correction := diff * (1.0 - SEG_LEN / dist) * 0.5
			if i != _ANCHOR_IDX:
				pos[i] = pos[i] + correction
			pos[i + 1] = pos[i + 1] - correction

	var total := 0.0
	for i in N - 1:
		total += pos[i].distance_to(pos[i + 1])

	var expected := float(N - 1) * SEG_LEN
	expect(absf(total - expected) < 1.0, "rope total length ≈ (N-1)*SEG_LEN after many constraint iters")
