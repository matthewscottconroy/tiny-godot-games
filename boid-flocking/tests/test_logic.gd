extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_separation_pushes_away()
	test_cohesion_pulls_toward_center()
	test_alignment_matches_neighbors()
	test_speed_clamped_to_max()
	test_speed_not_below_min()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[boid-flocking] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const MAX_SPEED := 130.0
const MIN_SPEED := 55.0
const SEP_RADIUS := 28.0

func _separation_force(self_pos: Vector2, other_pos: Vector2) -> Vector2:
	var d    := other_pos - self_pos
	var dist := d.length()
	if dist < SEP_RADIUS and dist > 0.001:
		return -d.normalized() / dist
	return Vector2.ZERO

func _cohesion_desired(self_pos: Vector2, neighbors: Array) -> Vector2:
	if neighbors.is_empty():
		return Vector2.ZERO
	var center := Vector2.ZERO
	for p in neighbors: center += p
	center /= neighbors.size()
	return (center - self_pos).normalized() * MAX_SPEED

func _clamp_speed(vel: Vector2) -> Vector2:
	var spd := vel.length()
	if spd > MAX_SPEED: return vel.normalized() * MAX_SPEED
	if spd < MIN_SPEED and spd > 0.001: return vel.normalized() * MIN_SPEED
	return vel

func test_separation_pushes_away() -> void:
	var f := _separation_force(Vector2.ZERO, Vector2(10, 0))
	expect(f.x < 0.0, "separation force points away from nearby neighbor")

func test_cohesion_pulls_toward_center() -> void:
	var center_dir := _cohesion_desired(Vector2(0, 0), [Vector2(100, 0)])
	expect(center_dir.x > 0.0, "cohesion force points toward center of mass")

func test_alignment_matches_neighbors() -> void:
	var neighbor_vel := Vector2(100, 0)
	var ali_desired  := neighbor_vel.normalized() * MAX_SPEED
	expect(ali_desired.x > 0.0 and absf(ali_desired.length() - MAX_SPEED) < 0.01,
		"alignment desired velocity points in neighbor direction at MAX_SPEED")

func test_speed_clamped_to_max() -> void:
	var v := _clamp_speed(Vector2(MAX_SPEED * 2, 0))
	expect(absf(v.length() - MAX_SPEED) < 0.01, "speed clamped to MAX_SPEED")

func test_speed_not_below_min() -> void:
	var v := _clamp_speed(Vector2(MIN_SPEED * 0.5, 0))
	expect(absf(v.length() - MIN_SPEED) < 0.01, "speed floored at MIN_SPEED")
