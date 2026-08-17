extends Node

# Drives the real particle field from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_field_starts_full()
	_test_leaves_start_off_the_edges()
	_test_the_wind_blows_them_along()
	_test_turning_the_wind_turns_the_leaves()
	_test_gravity_pulls_them_down()
	_test_a_leaf_fades_as_it_ages()
	_test_an_expired_leaf_is_recycled()
	_test_a_leaf_blown_off_screen_is_recycled()
	_test_the_field_never_empties_or_grows()
	_test_the_strength_keys_have_limits()
	_test_key_releases_change_nothing()
	_test_the_wind_gusts()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[wind-effect] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _run(m: Node2D, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		m._process(STEP)
		elapsed += STEP

func _press(m: Node2D, code: Key, pressed: bool = true) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = pressed
	m._input(e)

## One leaf, placed where the test wants it, and nothing else.
func _one_leaf(m: Node2D, at: Vector2) -> Dictionary:
	var leaf: Dictionary = m._particles[0]
	m._particles = [leaf]
	leaf["pos"] = at
	leaf["vel"] = Vector2.ZERO
	leaf["lifetime"] = 5.0
	leaf["max_lifetime"] = 5.0
	return leaf

func _test_the_field_starts_full() -> void:
	print("the field")
	var m := _make()
	expect(m._particles.size() == m.PARTICLE_COUNT, "the field starts with its full complement")
	var colours := {}
	for p in m._particles:
		colours[p["color"]] = true
	expect(colours.size() > 1, "in a mix of colours rather than one")

func _test_leaves_start_off_the_edges() -> void:
	print("where they come from")
	var m := _make()
	# Leaves blow in from the top or the left, so they should not simply
	# materialise in the middle of the sky.
	var from_edge := 0
	for p in m._particles:
		var pos: Vector2 = p["pos"]
		if pos.x <= 0.0 or pos.y <= 0.0:
			from_edge += 1
	expect(from_edge == m._particles.size(), "every leaf enters from the top or the left")

func _test_the_wind_blows_them_along() -> void:
	print("the wind")
	var m := _make()
	m._wind_angle = 0.0
	m._wind_strength = 100.0
	var leaf := _one_leaf(m, Vector2(320.0, 240.0))
	_run(m, 0.5)
	expect(leaf["vel"].x > 0.0, "wind blowing right pushes the leaves right")

func _test_turning_the_wind_turns_the_leaves() -> void:
	print("wind direction")
	var m := _make()
	m._wind_angle = PI
	m._wind_strength = 100.0
	var leaf := _one_leaf(m, Vector2(320.0, 240.0))
	_run(m, 0.5)
	expect(leaf["vel"].x < 0.0, "and wind turned about blows them the other way")

	var keys := _make()
	var before: float = keys._wind_angle
	_press(keys, KEY_RIGHT)
	expect(keys._wind_angle > before, "the right key turns the wind one way")
	_press(keys, KEY_LEFT)
	expect(is_equal_approx(keys._wind_angle, before), "and the left key back again")

func _test_gravity_pulls_them_down() -> void:
	print("gravity")
	var m := _make()
	m._wind_strength = 0.0
	var leaf := _one_leaf(m, Vector2(320.0, 100.0))
	_run(m, 0.5)
	expect(leaf["vel"].y > 0.0, "with no wind a leaf still falls")

func _test_a_leaf_fades_as_it_ages() -> void:
	print("fading")
	var m := _make()
	var leaf := _one_leaf(m, Vector2(320.0, 240.0))
	m._process(STEP)
	var early: float = leaf["alpha"]
	_run(m, 2.0)
	expect(leaf["alpha"] < early, "a leaf fades as its life runs down")
	expect(leaf["alpha"] > 0.0, "and is still visible part-way through")

func _test_an_expired_leaf_is_recycled() -> void:
	print("recycling")
	var m := _make()
	var leaf := _one_leaf(m, Vector2(320.0, 240.0))
	leaf["lifetime"] = STEP * 0.5
	m._process(STEP)
	expect(leaf["lifetime"] > 0.0, "a leaf that runs out of life is given a new one")
	expect(is_equal_approx(leaf["alpha"], 1.0), "at full opacity again")
	expect(leaf["pos"].x <= 0.0 or leaf["pos"].y <= 0.0, "and back at an edge to blow in from")

func _test_a_leaf_blown_off_screen_is_recycled() -> void:
	print("leaving the screen")
	begin_quiet()
	for corner in [Vector2(900.0, 240.0), Vector2(-200.0, 240.0),
			Vector2(320.0, 900.0), Vector2(320.0, -200.0)]:
		var m := _make()
		var leaf := _one_leaf(m, corner)
		m._process(STEP)
		expect_quiet(leaf["pos"].distance_to(corner) > 1.0,
			"a leaf at %s is brought back" % corner)
	expect(_quiet_failures == 0, "a leaf blown off any edge is recycled rather than drifting forever")

func _test_the_field_never_empties_or_grows() -> void:
	print("the count holds")
	var m := _make()
	m._wind_strength = 200.0
	_run(m, 12.0)
	expect(m._particles.size() == m.PARTICLE_COUNT,
		"after twelve seconds of hard wind the field still holds its count")
	var alive := 0
	for p in m._particles:
		if p["lifetime"] > 0.0:
			alive += 1
	expect(alive == m._particles.size(), "with every leaf still alive")

func _test_the_strength_keys_have_limits() -> void:
	print("strength")
	var m := _make()
	var start: float = m._wind_strength
	_press(m, KEY_UP)
	expect(m._wind_strength > start, "up strengthens the wind")
	_press(m, KEY_DOWN)
	expect(is_equal_approx(m._wind_strength, start), "and down eases it")

	for i in 60:
		_press(m, KEY_UP)
	expect(m._wind_strength <= 200.0, "the wind stops at a maximum")
	for i in 60:
		_press(m, KEY_DOWN)
	expect(m._wind_strength >= 0.0, "and at a dead calm rather than blowing backwards")

func _test_key_releases_change_nothing() -> void:
	print("key releases")
	var m := _make()
	var strength: float = m._wind_strength
	var angle: float = m._wind_angle
	_press(m, KEY_UP, false)
	_press(m, KEY_LEFT, false)
	expect(is_equal_approx(m._wind_strength, strength), "letting go of a key does not change the wind")
	expect(is_equal_approx(m._wind_angle, angle), "in strength or direction")

var _quiet_failures := 0

## Counted rather than printed, for checks that run once per item. Each test
## zeroes the tally first, so one failure cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")

func _test_the_wind_gusts() -> void:
	print("gusting")
	# The wind is its base strength plus a slow swell, so a leaf caught on the
	# rising half of that swell is pushed harder than one on the falling half.
	# Without the swell — or with it inverted — the two are the same.
	var rising := _make()
	rising._wind_angle = 0.0
	rising._wind_strength = 100.0
	rising._time = 0.0
	var on_the_gust := _one_leaf(rising, Vector2(320.0, 240.0))
	_run(rising, 0.4)

	var falling := _make()
	falling._wind_angle = 0.0
	falling._wind_strength = 100.0
	falling._time = PI / 0.7          # half a swell later, where it is dropping
	var in_the_lull := _one_leaf(falling, Vector2(320.0, 240.0))
	_run(falling, 0.4)

	expect(on_the_gust["vel"].x > in_the_lull["vel"].x,
		"a leaf caught on a gust is pushed harder than one in the lull")
