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
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

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
