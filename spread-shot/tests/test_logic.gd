extends Node

# Drives the real player and bullet from scripts/ — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_fires_the_configured_count()
	_test_fan_is_centred_on_facing()
	_test_fan_spans_the_full_spread()
	_test_bullets_occupy_both_ends()
	_test_directions_are_unit_length()
	_test_facing_left_mirrors_the_fan()
	_test_bullet_travels_along_its_direction()
	_test_bullet_expires()
	await test_the_gun_reloads_and_says_so()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

## The gun's cooldown, the readout it drives, and where the fan comes out.
func test_the_gun_reloads_and_says_so() -> void:
	print("the cooldown")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame
	var player: CharacterBody2D = scene.get_node("Player")

	player._cooldown = 0.0
	expect(player.can_fire(), "a rested gun is ready")
	expect(player.status_text() == "READY",
		"and says so (%s)" % player.status_text())

	player._cooldown = player.FIRE_COOLDOWN
	expect(not player.can_fire(), "a just-fired gun is not")
	expect(player.status_text().begins_with("CD"),
		"and the readout counts it down instead (%s)" % player.status_text())

	# It counts down, not up — an unclamped timer running the wrong way leaves
	# the gun permanently ready or permanently jammed.
	var before: float = player._cooldown
	player.tick_cooldown(1.0 / 60.0)
	expect(player._cooldown < before,
		"the cooldown ages downward (%.3f -> %.3f)" % [before, player._cooldown])
	for _i in 120:
		player.tick_cooldown(1.0 / 60.0)
	expect(player._cooldown == 0.0,
		"and stops at zero rather than going negative (%.3f)" % player._cooldown)
	expect(player.can_fire(), "so the gun comes back")

	# Firing puts the fan in front of the player, on the side it faces.
	player._facing = 1.0
	expect(player.muzzle().x > player.global_position.x,
		"facing right, the fan starts to the right (%s)" % player.muzzle())
	player._facing = -1.0
	expect(player.muzzle().x < player.global_position.x, "facing left, to the left")
	expect(is_equal_approx(player.muzzle().distance_to(player.global_position),
			player.MUZZLE_OFFSET),
		"always one muzzle length out (%.1f)"
		% player.muzzle().distance_to(player.global_position))

	# A released key leaves the aim where it was.
	expect(player.facing_for(0.0, -1.0) == -1.0, "no input keeps the facing")
	expect(player.facing_for(1.0, -1.0) == 1.0, "a push right turns it right")
	expect(player.facing_for(-0.5, 1.0) == -1.0,
		"and a partial push left is still left (%.0f)" % player.facing_for(-0.5, 1.0))

	# Nothing pressed, nothing fired and nothing jumped.
	player._cooldown = 0.0
	var quiet := scene.get_child_count()
	for _i in 40:
		await get_tree().physics_frame
	expect(player.can_fire(), "the gun is off cooldown")
	expect(scene.get_child_count() == quiet,
		"but nothing is fired with no key pressed (%d -> %d)"
		% [quiet, scene.get_child_count()])
	expect(player.is_on_floor(), "and the player is on the ground")
	var resting: float = player.global_position.y
	var highest := resting
	for _i in 40:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"where it stays (rose %.1f px)" % (resting - highest))

	scene.queue_free()

func _report() -> void:
	var summary := "[spread-shot] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _player_script: GDScript = load("res://scripts/player.gd")
var _bullet_script: GDScript = load("res://scripts/bullet.gd")

func _player() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.set_script(_player_script)
	add_child(p)
	return p

func _bullet(pos: Vector2, dir: Vector2) -> Node2D:
	var b := Node2D.new()
	b.set_script(_bullet_script)
	add_child(b)
	b.init(pos, dir)
	return b

func _test_fires_the_configured_count() -> void:
	print("bullet count")
	var p := _player()
	expect(p.spread_directions(1.0).size() == p.BULLET_COUNT,
		"one shot produces exactly BULLET_COUNT directions")

func _test_fan_is_centred_on_facing() -> void:
	print("centred fan")
	var p := _player()
	var dirs: Array = p.spread_directions(1.0)
	# With an odd count the middle bullet flies straight ahead.
	var middle: Vector2 = dirs[dirs.size() / 2]
	expect(absf(middle.angle()) < 0.001, "the centre bullet travels straight along the facing")

func _test_fan_spans_the_full_spread() -> void:
	print("spread angle")
	var p := _player()
	var dirs: Array = p.spread_directions(1.0)
	var first: Vector2 = dirs[0]
	var last: Vector2 = dirs[-1]
	var span := absf(first.angle_to(last))
	expect(is_equal_approx(span, deg_to_rad(p.SPREAD_DEG)),
		"the outer bullets are SPREAD_DEG apart")

func _test_bullets_occupy_both_ends() -> void:
	print("endpoints")
	var p := _player()
	var dirs: Array = p.spread_directions(1.0)
	var half := deg_to_rad(p.SPREAD_DEG * 0.5)
	# Dividing by COUNT - 1 is what puts a bullet on each edge of the arc.
	expect(is_equal_approx(dirs[0].angle(), -half), "the first bullet sits on one edge")
	expect(is_equal_approx(dirs[-1].angle(), half), "the last sits on the other")

func _test_directions_are_unit_length() -> void:
	print("unit directions")
	var p := _player()
	for d in p.spread_directions(1.0):
		expect(is_equal_approx((d as Vector2).length(), 1.0),
			"every direction is normalised, so all bullets fly at one speed")

func _test_facing_left_mirrors_the_fan() -> void:
	print("facing left")
	var p := _player()
	var right: Array = p.spread_directions(1.0)
	var left: Array = p.spread_directions(-1.0)
	expect(left.size() == right.size(), "the same number of bullets either way")
	for d in left:
		expect((d as Vector2).x < 0.0, "every bullet in the left fan travels left")

func _test_bullet_travels_along_its_direction() -> void:
	print("bullet motion")
	var b := _bullet(Vector2(100, 100), Vector2.RIGHT)
	b._process(0.1)
	expect(b.position.x > 100.0, "the bullet advances along its direction")
	expect(is_equal_approx(b.position.y, 100.0), "and does not drift off-axis")

func _test_bullet_expires() -> void:
	print("lifetime")
	var b := _bullet(Vector2(100, 100), Vector2.UP)   # never leaves horizontally
	var elapsed := 0.0
	while elapsed < b.LIFETIME + 0.1 and not b.is_queued_for_deletion():
		b._process(0.05)
		elapsed += 0.05
	expect(b.is_queued_for_deletion(), "a bullet frees itself after LIFETIME")
