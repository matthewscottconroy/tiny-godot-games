extends Node

# Drives the real HomingProjectile from scripts/projectile.gd rather than a copy
# of its lerp_angle steering.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_init_sets_heading_and_speed()
	test_steering_turns_toward_the_target()
	test_speed_preserved_after_steer()
	test_full_turn_takes_multiple_frames()
	test_rotation_follows_velocity()
	test_trail_size_capped()
	test_lifetime_expires()
	test_survives_a_freed_target()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

const DELTA := 0.016

func _make(dir: Vector2, target_pos: Vector2) -> Array:
	var target := Node2D.new()
	target.position = target_pos
	add_child(target)

	var projectile := HomingProjectile.new()
	add_child(projectile)
	projectile.init(Vector2.ZERO, dir, target)
	return [projectile, target]

func test_init_sets_heading_and_speed() -> void:
	print("init sets the initial heading and speed")
	var pair := _make(Vector2.RIGHT, Vector2(500, 0))
	var p: HomingProjectile = pair[0]
	expect(p.position == Vector2.ZERO, "it starts at the requested position")
	expect(is_equal_approx(p._vel.length(), p.speed), "it launches at the configured speed")
	expect(p._vel.normalized().is_equal_approx(Vector2.RIGHT), "it launches along the given direction")

func test_steering_turns_toward_the_target() -> void:
	print("steering turns toward the target")
	# Fired to the right, target straight up: the heading should rotate upward.
	var pair := _make(Vector2.RIGHT, Vector2(0, -500))
	var p: HomingProjectile = pair[0]
	var before := p._vel.angle()
	p._process(DELTA)
	var after := p._vel.angle()
	expect(absf(angle_difference(after, Vector2.UP.angle())) < absf(angle_difference(before, Vector2.UP.angle())),
		"steering moves the heading toward the target")

func test_speed_preserved_after_steer() -> void:
	print("steering changes direction, never speed")
	var pair := _make(Vector2.RIGHT, Vector2(0, -500))
	var p: HomingProjectile = pair[0]
	for i in 20:
		p._process(DELTA)
		if not is_equal_approx(p._vel.length(), p.speed):
			expect(false, "steering preserves speed magnitude")
			return
	expect(true, "steering preserves speed magnitude")

func test_full_turn_takes_multiple_frames() -> void:
	print("a 180 degree turn is not instant")
	var pair := _make(Vector2.RIGHT, Vector2(-500, 0))
	var p: HomingProjectile = pair[0]
	p._process(DELTA)
	expect(absf(angle_difference(p._vel.angle(), Vector2.LEFT.angle())) > 0.1,
		"180-degree turn requires multiple frames (not instant)")

func test_rotation_follows_velocity() -> void:
	print("the sprite rotation follows the velocity")
	var pair := _make(Vector2.RIGHT, Vector2(0, -500))
	var p: HomingProjectile = pair[0]
	p._process(DELTA)
	expect(is_equal_approx(p.rotation, p._vel.angle()), "rotation is kept in sync with the heading")

func test_trail_size_capped() -> void:
	print("the trail is capped")
	var pair := _make(Vector2.RIGHT, Vector2(500, 0))
	var p: HomingProjectile = pair[0]
	for i in 40:
		p._process(DELTA)
	expect(p._trail.size() <= 12, "trail size capped at 12")

func test_lifetime_expires() -> void:
	print("the projectile frees itself after its lifetime")
	var pair := _make(Vector2.RIGHT, Vector2(500, 0))
	var p: HomingProjectile = pair[0]
	p.lifetime = 0.1
	var elapsed := 0.0
	while elapsed < 0.2 and is_instance_valid(p) and not p.is_queued_for_deletion():
		p._process(DELTA)
		elapsed += DELTA
	expect(p.is_queued_for_deletion(), "projectile expires after its lifetime")

func test_survives_a_freed_target() -> void:
	print("a freed target does not break the projectile")
	var pair := _make(Vector2.RIGHT, Vector2(0, -500))
	var p: HomingProjectile = pair[0]
	var target: Node2D = pair[1]
	target.free()
	p._process(DELTA)   # must not error — it flies straight instead
	expect(p._vel.normalized().is_equal_approx(Vector2.RIGHT),
		"with no target it keeps its last heading")

func _report() -> void:
	var summary := "[homing-projectile] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
