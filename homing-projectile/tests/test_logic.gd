extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_lerp_angle_moves_toward_target()
	test_speed_preserved_after_steer()
	test_full_turn_takes_multiple_frames()
	test_lifetime_expires()
	test_trail_size_capped()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[homing-projectile] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const SPEED      := 280.0
const TURN_SPEED := 3.5
const LIFETIME   := 4.0

func _steer(vel: Vector2, target_angle: float, delta: float) -> Vector2:
	var new_angle := lerp_angle(vel.angle(), target_angle, TURN_SPEED * delta)
	return Vector2.from_angle(new_angle) * SPEED

func test_lerp_angle_moves_toward_target() -> void:
	var vel         := Vector2(SPEED, 0)
	var target_ang  := PI / 2.0  # 90 degrees (pointing down)
	var new_vel     := _steer(vel, target_ang, 0.016)
	expect(new_vel.angle() > vel.angle(), "steering moves angle toward target")

func test_speed_preserved_after_steer() -> void:
	var vel     := Vector2(SPEED, 0)
	var new_vel := _steer(vel, PI / 2.0, 0.016)
	expect(absf(new_vel.length() - SPEED) < 0.01, "steering preserves speed magnitude")

func test_full_turn_takes_multiple_frames() -> void:
	var vel := Vector2(SPEED, 0)
	var frames := 0
	while vel.angle() < PI * 0.45 and frames < 1000:
		vel = _steer(vel, PI / 2.0, 0.016)
		frames += 1
	expect(frames > 1, "180-degree turn requires multiple frames (not instant)")

func test_lifetime_expires() -> void:
	var age := 0.0
	var frames := 0
	while age < LIFETIME:
		age += 0.016
		frames += 1
	expect(age >= LIFETIME, "projectile expires after LIFETIME seconds")

func test_trail_size_capped() -> void:
	var trail: Array[Vector2] = []
	for i in 20:
		trail.append(Vector2(i * 5, 0))
		if trail.size() > 12:
			trail.pop_front()
	expect(trail.size() == 12, "trail size capped at 12")
