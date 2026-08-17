extends Node

# Drives the real simulation from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_balls_start_scattered_and_still()
	_test_attraction_pulls_a_ball_in()
	_test_repulsion_pushes_it_away()
	_test_a_moves_between_the_two()
	_test_the_force_is_bounded_close_up()
	_test_the_pull_is_stronger_close_than_far()
	_test_the_balls_stay_on_screen()
	_test_the_magnet_can_be_dragged()
	_test_r_scatters_the_balls_again()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[magnet] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

## One ball, placed exactly where the test wants it, and nothing else.
func _one_ball_at(m: Node2D, pos: Vector2) -> Dictionary:
	m._balls.clear()
	m._balls.append({"pos": pos, "vel": Vector2.ZERO, "color": Color.WHITE})
	return m._balls[0]

func _click(m: Node2D, at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	m._input(e)

func _move_mouse(m: Node2D, to: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = to
	m._input(e)

func _key(m: Node2D, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._input(e)

func _test_the_balls_start_scattered_and_still() -> void:
	print("initial state")
	var m := _make()
	expect(m._balls.size() == m.BALL_COUNT, "the scene starts with a handful of balls")
	var still := true
	var on_screen := true
	for ball in m._balls:
		if ball["vel"] != Vector2.ZERO:
			still = false
		if ball["pos"].x < 0.0 or ball["pos"].x > 640.0 or ball["pos"].y < 0.0 or ball["pos"].y > 480.0:
			on_screen = false
	expect(still, "all of them at rest")
	expect(on_screen, "and all of them on screen")
	expect(m._attract, "with the magnet attracting to start with")

func _test_attraction_pulls_a_ball_in() -> void:
	print("attracting")
	var m := _make()
	# Level with the magnet, so gravity cannot be mistaken for attraction.
	var ball := _one_ball_at(m, m._magnet_pos + Vector2(200.0, 0.0))
	m._physics_process(STEP)
	expect(ball["vel"].x < 0.0, "a ball to the right of the magnet is pulled left, towards it")

func _test_repulsion_pushes_it_away() -> void:
	print("repelling")
	var m := _make()
	m._attract = false
	var ball := _one_ball_at(m, m._magnet_pos + Vector2(200.0, 0.0))
	m._physics_process(STEP)
	expect(ball["vel"].x > 0.0, "in repel mode the same ball is pushed further right")

func _test_a_moves_between_the_two() -> void:
	print("the mode key")
	var m := _make()
	expect(m._attract, "attracting")
	_key(m, KEY_A)
	expect(not m._attract, "A switches to repel")
	_key(m, KEY_A)
	expect(m._attract, "and back again")

func _test_the_force_is_bounded_close_up() -> void:
	print("no singularity")
	var m := _make()
	# An inverse-square force goes to infinity at zero distance. MIN_DIST and
	# MAX_FORCE are what stop a ball sitting on the magnet from being flung
	# across the screen.
	var ball := _one_ball_at(m, m._magnet_pos + Vector2(0.5, 0.0))
	m._physics_process(STEP)
	var speed: float = ball["vel"].length()
	expect(not is_nan(speed), "a ball on top of the magnet does not produce a NaN")
	expect(speed <= m.MAX_FORCE * STEP + m.GRAVITY * STEP + 0.001,
		"and is accelerated no harder than MAX_FORCE allows")

func _test_the_pull_is_stronger_close_than_far() -> void:
	print("falling off with distance")
	var near := _make()
	var near_ball := _one_ball_at(near, near._magnet_pos + Vector2(120.0, 0.0))
	near._physics_process(STEP)

	var far := _make()
	var far_ball := _one_ball_at(far, far._magnet_pos + Vector2(300.0, 0.0))
	far._physics_process(STEP)

	expect(absf(near_ball["vel"].x) > absf(far_ball["vel"].x),
		"a nearby ball is pulled harder than a distant one")

func _test_the_balls_stay_on_screen() -> void:
	print("the walls")
	var m := _make()
	var ball := _one_ball_at(m, Vector2(320.0, 240.0))
	ball["vel"] = Vector2(4000.0, 4000.0)
	for i in 120:
		m._physics_process(STEP)
	var inside: bool = m._balls[0]["pos"].x >= m.BALL_R - 0.001 \
		and m._balls[0]["pos"].x <= 640.0 - m.BALL_R + 0.001 \
		and m._balls[0]["pos"].y >= m.BALL_R - 0.001 \
		and m._balls[0]["pos"].y <= 480.0 - m.BALL_R + 0.001
	expect(inside, "even a very fast ball is kept inside the window")

	var wall := _make()
	var bounced := _one_ball_at(wall, Vector2(640.0 - wall.BALL_R - 1.0, 240.0))
	bounced["vel"] = Vector2(500.0, 0.0)
	wall._physics_process(STEP)
	expect(bounced["vel"].x < 0.0, "hitting the right wall sends it back left")
	expect(absf(bounced["vel"].x) < 500.0, "having lost speed in the bounce")

func _test_the_magnet_can_be_dragged() -> void:
	print("moving the magnet")
	var m := _make()
	var start: Vector2 = m._magnet_pos
	_click(m, start, true)
	_move_mouse(m, start + Vector2(100.0, 50.0))
	expect(m._magnet_pos == start + Vector2(100.0, 50.0), "grabbing the magnet moves it")

	_click(m, m._magnet_pos, false)
	var parked: Vector2 = m._magnet_pos
	_move_mouse(m, Vector2(50.0, 50.0))
	expect(m._magnet_pos == parked, "letting go leaves it where it was")

	var missed := _make()
	var elsewhere: Vector2 = missed._magnet_pos
	_click(missed, elsewhere + Vector2(200.0, 0.0), true)
	_move_mouse(missed, Vector2(10.0, 10.0))
	expect(missed._magnet_pos == elsewhere, "and clicking away from it picks up nothing")

func _test_r_scatters_the_balls_again() -> void:
	print("reset")
	var m := _make()
	for i in 60:
		m._physics_process(STEP)
	var moving := false
	for ball in m._balls:
		if ball["vel"].length() > 1.0:
			moving = true
	expect(moving, "the balls are in motion")

	_key(m, KEY_R)
	expect(m._balls.size() == m.BALL_COUNT, "R puts the same number of balls back")
	var still := true
	for ball in m._balls:
		if ball["vel"] != Vector2.ZERO:
			still = false
	expect(still, "all of them stopped again")
