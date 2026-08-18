extends Node

# Drives the real sprite from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_sprite_has_something_to_show()
	_test_it_moves_in_each_direction()
	_test_it_moves_at_its_exported_speed()
	_test_a_diagonal_is_no_faster()
	_test_holding_nothing_moves_nothing()
	_test_opposite_arrows_cancel()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[arrow-sprite] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Sprite2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	for child in scene.get_children():
		if child is Sprite2D:
			return child
	return null

func _test_the_sprite_has_something_to_show() -> void:
	print("the sprite")
	var s := _make()
	expect(s != null, "there is a sprite in the scene")
	expect(s != null and s.texture != null, "with a texture — an empty Sprite2D draws nothing")
	expect(s != null and s.speed > 0.0, "and a speed to move at")

func _test_it_moves_in_each_direction() -> void:
	print("directions")
	var cases := {
		"right": [Vector2.RIGHT, Vector2(1.0, 0.0)],
		"left": [Vector2.LEFT, Vector2(-1.0, 0.0)],
		"down": [Vector2.DOWN, Vector2(0.0, 1.0)],
		"up": [Vector2.UP, Vector2(0.0, -1.0)],
	}
	begin_quiet()
	for name in cases:
		var s := _make()
		var start: Vector2 = s.position
		s.move(0.1, (cases[name] as Array)[0])
		var travelled: Vector2 = s.position - start
		expect_quiet(travelled.normalized().is_equal_approx((cases[name] as Array)[1]),
			"holding %s moves %s" % [name, name])
	expect(_quiet_failures == 0, "each arrow moves the sprite its own way")

func _test_it_moves_at_its_exported_speed() -> void:
	print("speed")
	var s := _make()
	var start: Vector2 = s.position
	s.move(0.5, Vector2.RIGHT)
	expect(is_equal_approx(s.position.distance_to(start), s.speed * 0.5),
		"half a second covers half a second's worth of travel")

func _test_a_diagonal_is_no_faster() -> void:
	print("diagonals")
	var straight := _make()
	var straight_start: Vector2 = straight.position
	straight.move(0.5, Vector2.RIGHT)

	var diagonal := _make()
	var diagonal_start: Vector2 = diagonal.position
	diagonal.move(0.5, Vector2(1.0, 1.0))
	# Unnormalised, a diagonal would travel about 1.41 times as far.
	expect(is_equal_approx(diagonal.position.distance_to(diagonal_start),
		straight.position.distance_to(straight_start)),
		"two arrows together travel no further than one")

func _test_holding_nothing_moves_nothing() -> void:
	print("no input")
	var s := _make()
	var start: Vector2 = s.position
	s.move(1.0, Vector2.ZERO)
	# Normalising a zero vector is a division by zero; the guard is what stops
	# a NaN position that never comes back.
	expect(s.position == start, "no arrows held leaves the sprite where it is")
	expect(not is_nan(s.position.x) and not is_nan(s.position.y), "and not at a NaN")

func _test_opposite_arrows_cancel() -> void:
	print("opposite arrows")
	var s := _make()
	var start: Vector2 = s.position
	s.move(1.0, Vector2.RIGHT + Vector2.LEFT)
	expect(s.position == start, "holding both left and right stays put")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
