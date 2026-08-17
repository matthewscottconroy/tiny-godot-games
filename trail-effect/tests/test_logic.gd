extends Node

# Drives the real player and trail from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_trail_starts_empty()
	_test_each_step_adds_a_point()
	_test_the_newest_point_is_at_the_head()
	_test_the_trail_is_trimmed_to_its_length()
	_test_the_trail_follows_the_player()
	_test_gravity_and_the_floor()
	_test_jumping_needs_the_floor()
	_test_the_player_stays_on_screen()
	_test_the_buttons_change_the_length()
	_test_the_length_has_limits()
	_test_shortening_trims_the_trail_already_drawn()
	_test_the_trail_fades_towards_its_tail()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[trail-effect] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _trail(m: Node2D) -> Line2D:
	return m.get_node("Trail")

func _run(m: Node2D, frames: int, axis: float = 0.0) -> void:
	for i in frames:
		m.tick(STEP, axis, false)

func _press(m: Node2D, which: String) -> void:
	(m.get_node("HUD/BtnRow/" + which) as Button).pressed.emit()

func _test_the_trail_starts_empty() -> void:
	print("before moving")
	var m := _make()
	expect(_trail(m).get_point_count() == 0, "nothing is drawn until the player moves")
	expect(m._trail_len > 0, "but a length is set")

func _test_each_step_adds_a_point() -> void:
	print("laying the trail")
	var m := _make()
	_run(m, 1)
	expect(_trail(m).get_point_count() == 1, "one step, one point")
	_run(m, 4)
	expect(_trail(m).get_point_count() == 5, "and a point per step after that")

func _test_the_newest_point_is_at_the_head() -> void:
	print("which end is which")
	var m := _make()
	_run(m, 3, 1.0)
	var trail := _trail(m)
	# Points go in at the front, so index 0 is where the player is now and the
	# last index is the oldest — that is what makes the gradient a fade-out.
	expect(trail.get_point_position(0).is_equal_approx(m._pos), "index 0 is the player's position now")
	expect(trail.get_point_position(trail.get_point_count() - 1) != m._pos,
		"and the far end is where they were")

func _test_the_trail_is_trimmed_to_its_length() -> void:
	print("length")
	var m := _make()
	_run(m, m._trail_len + 40)
	expect(_trail(m).get_point_count() == m._trail_len,
		"the trail never grows past its length, however long the player runs")

func _test_the_trail_follows_the_player() -> void:
	print("following")
	var m := _make()
	_run(m, 10, 1.0)
	var moved: Vector2 = m._pos
	_run(m, 1, 1.0)
	expect(_trail(m).get_point_position(0) != moved, "the head keeps up with the player")
	expect(_trail(m).get_point_position(0).is_equal_approx(m._pos), "exactly, not a frame behind")

func _test_gravity_and_the_floor() -> void:
	print("falling")
	var m := _make()
	m._pos = Vector2(320.0, 100.0)
	m._velocity = Vector2.ZERO
	m.tick(STEP, 0.0, false)
	expect(m._velocity.y > 0.0, "the player falls")
	_run(m, 120)
	expect(is_equal_approx(m._pos.y, 440.0), "and lands on the floor line")
	expect(is_zero_approx(m._velocity.y), "with the fall stopped")
	expect(m._on_floor, "and reports being on the floor")

func _test_jumping_needs_the_floor() -> void:
	print("jumping")
	var m := _make()
	_run(m, 120)
	expect(m._on_floor, "standing on the floor")
	m.tick(STEP, 0.0, true)
	expect(m._velocity.y < 0.0, "a jump from the floor goes up")

	var airborne := _make()
	airborne._pos = Vector2(320.0, 100.0)
	airborne.tick(STEP, 0.0, false)
	airborne.tick(STEP, 0.0, true)
	expect(airborne._velocity.y > 0.0, "but a jump in mid-air does nothing")

func _test_the_player_stays_on_screen() -> void:
	print("the edges")
	var m := _make()
	_run(m, 300, -1.0)
	expect(m._pos.x >= 16.0, "running left stops at the edge of the window")
	_run(m, 600, 1.0)
	expect(m._pos.x <= 624.0, "and running right at the other one")

func _test_the_buttons_change_the_length() -> void:
	print("the buttons")
	var m := _make()
	var start: int = m._trail_len
	_press(m, "LongerBtn")
	expect(m._trail_len > start, "the longer button lengthens the trail")
	expect((m.get_node("HUD/LenLabel") as Label).text.contains(str(m._trail_len)),
		"and the readout says so")

	_press(m, "ShorterBtn")
	expect(m._trail_len == start, "the shorter button takes it back")
	expect((m.get_node("HUD/LenLabel") as Label).text.contains(str(m._trail_len)),
		"and the readout follows that way too")

func _test_the_length_has_limits() -> void:
	print("limits")
	var m := _make()
	for i in 40:
		_press(m, "LongerBtn")
	expect(m._trail_len <= 120, "the trail stops growing at its maximum")
	for i in 40:
		_press(m, "ShorterBtn")
	expect(m._trail_len >= 5, "and shrinking at a minimum — a zero-point trail is invisible")

func _test_shortening_trims_the_trail_already_drawn() -> void:
	print("shortening")
	var m := _make()
	_run(m, m._trail_len + 10)
	_press(m, "ShorterBtn")
	_run(m, 1)
	expect(_trail(m).get_point_count() == m._trail_len,
		"a trail longer than the new length is trimmed back to it")

func _test_the_trail_fades_towards_its_tail() -> void:
	print("the gradient")
	var m := _make()
	var grad: Gradient = _trail(m).gradient
	expect(grad != null, "the trail has a gradient")
	expect(grad.sample(0.0).a < grad.sample(1.0).a,
		"transparent at the tail and solid at the head — that is the fade")
