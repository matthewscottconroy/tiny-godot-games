extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_ball_moves_by_velocity_times_delta()
	test_bounce_reverses_x_on_left_wall()
	test_bounce_reverses_x_on_right_wall()
	test_bounce_reverses_y_on_top_wall()
	test_bounce_reverses_y_on_bottom_wall()
	test_no_bounce_in_open_space()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[bouncing-ball] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Simulate the physics step from ball.gd
const RADIUS  := 16.0
const W       := 640.0
const H       := 480.0

func _step(pos: Vector2, vel: Vector2, delta: float) -> Array:
	pos += vel * delta
	if pos.x - RADIUS < 0 or pos.x + RADIUS > W:
		vel.x = -vel.x
	if pos.y - RADIUS < 0 or pos.y + RADIUS > H:
		vel.y = -vel.y
	return [pos, vel]

# --- tests ---

func test_ball_moves_by_velocity_times_delta() -> void:
	var pos := Vector2(320, 240)
	var vel := Vector2(100, 50)
	var res  := _step(pos, vel, 1.0)
	var new_pos : Vector2 = res[0]
	expect(is_equal_approx(new_pos.x, 420.0), "x moves by vel.x * delta")
	expect(is_equal_approx(new_pos.y, 290.0), "y moves by vel.y * delta")

func test_bounce_reverses_x_on_left_wall() -> void:
	var pos := Vector2(RADIUS - 5, 240)  # Already past left edge
	var vel := Vector2(-200, 0)
	var res  := _step(pos, vel, 0.016)
	var new_vel : Vector2 = res[1]
	expect(new_vel.x > 0, "x velocity flipped positive after left wall hit")

func test_bounce_reverses_x_on_right_wall() -> void:
	var pos := Vector2(W - RADIUS + 5, 240)  # Past right edge
	var vel := Vector2(200, 0)
	var res  := _step(pos, vel, 0.016)
	var new_vel : Vector2 = res[1]
	expect(new_vel.x < 0, "x velocity flipped negative after right wall hit")

func test_bounce_reverses_y_on_top_wall() -> void:
	var pos := Vector2(320, RADIUS - 5)  # Past top edge
	var vel := Vector2(0, -200)
	var res  := _step(pos, vel, 0.016)
	var new_vel : Vector2 = res[1]
	expect(new_vel.y > 0, "y velocity flipped positive after top wall hit")

func test_bounce_reverses_y_on_bottom_wall() -> void:
	var pos := Vector2(320, H - RADIUS + 5)  # Past bottom edge
	var vel := Vector2(0, 200)
	var res  := _step(pos, vel, 0.016)
	var new_vel : Vector2 = res[1]
	expect(new_vel.y < 0, "y velocity flipped negative after bottom wall hit")

func test_no_bounce_in_open_space() -> void:
	var pos := Vector2(320, 240)
	var vel := Vector2(100, 80)
	var res  := _step(pos, vel, 0.016)
	var new_vel : Vector2 = res[1]
	expect(is_equal_approx(new_vel.x, 100.0), "no x flip in open space")
	expect(is_equal_approx(new_vel.y, 80.0),  "no y flip in open space")
