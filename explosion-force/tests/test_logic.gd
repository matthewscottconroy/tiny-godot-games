extends Node

const EXPLOSION_RADIUS := 180.0
const EXPLOSION_STRENGTH := 450.0

var _pass := 0
var _fail := 0

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

func _ready() -> void:
	print("=== Explosion Force Tests ===")
	_test_push_direction()
	_test_push_falloff()
	_test_outside_radius()
	_test_multiple_balls()
	_report()

func _compute_impulse(ball_pos: Vector2, epicenter: Vector2) -> Vector2:
	var diff := ball_pos - epicenter
	var dist := diff.length()
	if dist < EXPLOSION_RADIUS and dist > 0.1:
		return diff.normalized() * EXPLOSION_STRENGTH * (1.0 - dist / EXPLOSION_RADIUS)
	return Vector2.ZERO

func _test_push_direction() -> void:
	print("_test_push_direction")
	var ball_pos := Vector2(200.0, 0.0)
	var epicenter := Vector2(0.0, 0.0)
	var impulse := _compute_impulse(ball_pos, epicenter)
	# Direction should be (1, 0) — purely to the right
	expect(impulse.x > 0.0 and is_equal_approx(impulse.y, 0.0), "push direction is (1,0) for ball at (200,0) from (0,0)")

func _test_push_falloff() -> void:
	print("_test_push_falloff")
	# Ball very close to epicenter gets near-full strength
	var near_impulse := _compute_impulse(Vector2(1.0, 0.0), Vector2.ZERO)
	# Ball at edge of radius gets near-zero strength
	var far_impulse := _compute_impulse(Vector2(EXPLOSION_RADIUS - 0.01, 0.0), Vector2.ZERO)
	expect(near_impulse.length() > far_impulse.length(), "closer ball gets stronger impulse (falloff)")
	expect(far_impulse.length() < EXPLOSION_STRENGTH * 0.01, "ball near radius edge gets near-zero impulse")

func _test_outside_radius() -> void:
	print("_test_outside_radius")
	var ball_pos := Vector2(EXPLOSION_RADIUS + 1.0, 0.0)
	var impulse := _compute_impulse(ball_pos, Vector2.ZERO)
	expect(impulse.length() == 0.0, "ball outside explosion radius gets no impulse")

func _test_multiple_balls() -> void:
	print("_test_multiple_balls")
	var epicenter := Vector2(200.0, 200.0)
	var balls := [
		{pos = Vector2(250.0, 200.0), vel = Vector2.ZERO},
		{pos = Vector2(150.0, 200.0), vel = Vector2.ZERO},
		{pos = Vector2(200.0, 250.0), vel = Vector2.ZERO},
	]
	for ball in balls:
		var impulse := _compute_impulse(ball.pos, epicenter)
		ball.vel += impulse

	# Each ball should be pushed away from epicenter
	var all_pushed_away := true
	for ball in balls:
		var away_dir := (ball.pos - epicenter).normalized()
		if ball.vel.dot(away_dir) <= 0.0:
			all_pushed_away = false
	expect(all_pushed_away, "all 3 balls pushed away from epicenter")
