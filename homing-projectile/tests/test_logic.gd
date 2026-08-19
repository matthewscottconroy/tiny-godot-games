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
	test_the_target_orbits_where_the_level_is()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

const DELTA := 0.016

## A projectile and a target. `from` defaults to the origin for the tests that
## do not care, but anything checking the steering direction must pass a real
## position — see test_steering_turns_toward_the_target.
func _make(dir: Vector2, target_pos: Vector2, from: Vector2 = Vector2.ZERO) -> Array:
	var target := Node2D.new()
	target.position = target_pos
	add_child(target)

	var projectile := HomingProjectile.new()
	add_child(projectile)
	projectile.init(from, dir, target)
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

	# Away from the origin, which is the case that tells a bearing from a sum.
	# With the projectile at (0, 0), `target - position` and `target + position`
	# are the same vector, so a test fired from there cannot see the difference
	# — and the mutation that steers by the sum aims at a point reflected
	# through the origin, sending the projectile the wrong way entirely.
	var offset := _make(Vector2.RIGHT, Vector2(600, 400), Vector2(500, 400))
	var q: HomingProjectile = offset[0]
	expect(q.global_position.x > 0.0 and q.global_position.y > 0.0,
		"the projectile is launched well away from the origin (%s)" % q.global_position)
	# The target is directly to its right, so the heading should stay right.
	for _i in 30:
		q._process(DELTA)
	expect(q._vel.x > 0.0,
		"it keeps heading toward a target on its right (%s)" % q._vel)

	# And from the same spot, a target on its left turns it around.
	var back := _make(Vector2.RIGHT, Vector2(100, 400), Vector2(500, 400))
	var r: HomingProjectile = back[0]
	for _i in 120:
		r._process(DELTA)
	expect(r._vel.x < 0.0,
		"and turns around for one on its left (%s)" % r._vel)

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
	# ...and it actually fills up. A cap alone is also satisfied by a trail that
	# is trimmed every frame and never draws more than one dot, which is the
	# same demo with its tail missing.
	expect(p._trail.size() == 12,
		"the trail reaches its full length rather than being trimmed away (%d)"
		% p._trail.size())

	# Each entry is a position it actually passed through, oldest first — the
	# fade in _draw() reads them in order.
	expect(p._trail[0].distance_to(p.position) > p._trail[11].distance_to(p.position),
		"the trail runs from oldest to newest (%s .. %s, now at %s)"
		% [p._trail[0], p._trail[11], p.position])

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

## The target drifts around the right-hand side of the play area.
##
## Its position is a pair of offsets from a fixed centre, and the centre is the
## part worth holding: negate one and the whole demo happens off the left edge
## of a 640-wide window, where nothing can be seen chasing anything.
func test_the_target_orbits_where_the_level_is() -> void:
	print("the target's orbit")
	var target: Node2D = load("res://scripts/target.gd").new()
	add_child(target)

	# Where it starts, before anything has moved. Over a whole orbit a mirrored
	# cosine traces the same loop, so the sign is only visible at the phase it
	# begins on: the target opens at the far right of its path, as far from the
	# launcher as it gets.
	target._process(1.0 / 60.0)
	expect(target.position.x > 460.0,
		"the target starts on the outside of its orbit (%.0f)" % target.position.x)
	expect(target.position.y > 240.0 - 5.0 and target.position.y < 240.0 + 5.0,
		"level with its centre, a quarter turn from the top (%.0f)" % target.position.y)

	var xs: Array[float] = []
	var ys: Array[float] = []
	for _i in 600:
		target._process(1.0 / 60.0)
		xs.append(target.position.x)
		ys.append(target.position.y)

	var lo_x := xs.min() as float
	var hi_x := xs.max() as float
	var lo_y := ys.min() as float
	var hi_y := ys.max() as float

	expect(lo_x > 0.0 and hi_x < 640.0,
		"it stays inside the window horizontally (%.0f .. %.0f)" % [lo_x, hi_x])
	expect(lo_y > 0.0 and hi_y < 480.0,
		"and vertically (%.0f .. %.0f)" % [lo_y, hi_y])
	expect((lo_x + hi_x) * 0.5 > 320.0,
		"it orbits the right-hand half, away from where the projectile launches (%.0f)"
		% ((lo_x + hi_x) * 0.5))
	expect(hi_y - lo_y > hi_x - lo_x,
		"on a taller-than-wide path, so the chase is not a straight line (%.0f x %.0f)"
		% [hi_x - lo_x, hi_y - lo_y])

	target.queue_free()
