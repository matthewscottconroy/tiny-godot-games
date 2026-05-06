extends Node

var _pass := 0
var _fail := 0

const N := 8
const SEG_LEN := 28.0
const ITERS := 8

func expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("  PASS: ", label)
	else:
		_fail += 1
		print("  FAIL: ", label)

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])

# Standalone FABRIK solver for testing
func _fabrik_solve(joints: PackedVector2Array, target: Vector2, base: Vector2) -> PackedVector2Array:
	var j := PackedVector2Array(joints)
	for _iter in range(ITERS):
		# Forward pass
		j[0] = target
		for i in range(1, N + 1):
			var dir := (j[i] - j[i - 1]).normalized()
			j[i] = j[i - 1] + dir * SEG_LEN
		# Backward pass
		j[N] = base
		for i in range(N - 1, -1, -1):
			var dir := (j[i] - j[i + 1]).normalized()
			j[i] = j[i + 1] + dir * SEG_LEN
	return j

func _make_chain(base: Vector2) -> PackedVector2Array:
	var j := PackedVector2Array()
	j.resize(N + 1)
	for i in range(N + 1):
		j[i] = base + Vector2(0, i * SEG_LEN)
	return j

func _test_fabrik_forward_reach() -> void:
	print("TEST: fabrik forward reach")
	var base := Vector2(320, 400)
	var target := Vector2(200, 150)
	var joints := _make_chain(base)
	var result := _fabrik_solve(joints, target, base)
	expect(result[0].distance_to(target) < 1.0, "head at target after solve")

func _test_fabrik_segment_length() -> void:
	print("TEST: fabrik segment lengths")
	var base := Vector2(320, 400)
	var target := Vector2(200, 150)
	var joints := _make_chain(base)
	var result := _fabrik_solve(joints, target, base)
	var all_ok := true
	for i in range(N):
		var dist := result[i].distance_to(result[i + 1])
		if abs(dist - SEG_LEN) >= 0.1:
			all_ok = false
			print("    segment %d length=%f expected=%f" % [i, dist, SEG_LEN])
	expect(all_ok, "all segment lengths ≈ SEG_LEN (within 0.1)")

func _test_fabrik_base_constraint() -> void:
	print("TEST: fabrik base constraint")
	var base := Vector2(320, 400)
	var target := Vector2(200, 150)
	var joints := _make_chain(base)
	var result := _fabrik_solve(joints, target, base)
	expect(result[N].distance_to(base) < 0.1, "tail ≈ base after solve")

func _test_fabrik_converges() -> void:
	print("TEST: fabrik converges (reachable target)")
	var base := Vector2(320, 400)
	# Target within reach: chain total length = N * SEG_LEN = 8 * 28 = 224
	var target := Vector2(320, 200)  # 200px away from base, reachable
	var joints := _make_chain(base)
	var result := _fabrik_solve(joints, target, base)
	expect(result[0].distance_to(target) < 1.0, "head within 1px of reachable target")

func _test_unreachable() -> void:
	print("TEST: unreachable target")
	var base := Vector2(320, 400)
	# Target 600px away, chain reach = 224px — unreachable
	var target := Vector2(320, -200)
	var joints := _make_chain(base)
	var result := _fabrik_solve(joints, target, base)
	# Chain should point toward target (head should be above base)
	expect(result[0].y < result[N].y, "chain points toward target (head above base)")
	# Base still held
	expect(result[N].distance_to(base) < 0.1, "base constraint held even when unreachable")

func _ready() -> void:
	print("=== Procedural Animation Tests ===")
	_test_fabrik_forward_reach()
	_test_fabrik_segment_length()
	_test_fabrik_base_constraint()
	_test_fabrik_converges()
	_test_unreachable()
	_report()
