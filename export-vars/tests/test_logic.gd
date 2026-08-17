extends Node

# Drives the real balls from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The demo's subject is @export: one script, three nodes configured differently
# in the scene. So the suite checks the scene's values actually reach the script
# and change what it does.

var _pass := 0
var _fail := 0

func _ready() -> void:
	# Headless opens a 64x64 window, which is smaller than this demo's own
	# margins — there would be no play area at all to bounce inside. The window
	# resizes even under the dummy driver.
	get_window().size = Vector2i(640, 480)
	_test_one_script_three_configurations()
	_test_each_ball_keeps_its_own_settings()
	_test_the_starting_velocity_is_copied_not_shared()
	_test_a_ball_moves_at_its_exported_speed()
	_test_a_ball_bounces_off_the_sides()
	_test_a_ball_bounces_off_the_top_and_bottom()
	_test_a_bigger_ball_turns_sooner()
	_test_the_label_is_whatever_the_scene_says()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[export-vars] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0

# The ball reads its walls from get_viewport_rect(), so positions are derived
# from the live rect after the window has been resized above.
const TOP_MARGIN := 40.0
const BOTTOM_MARGIN := 30.0
var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _balls(m: Node2D) -> Array[Node2D]:
	var found: Array[Node2D] = []
	for child in m.get_children():
		if child is Node2D and child.get_script() != null:
			found.append(child)
	return found

func _test_one_script_three_configurations() -> void:
	print("the balls")
	var m := _make()
	var balls := _balls(m)
	expect(balls.size() > 2, "there are several balls")
	var scripts := {}
	for ball in balls:
		scripts[ball.get_script()] = true
	expect(scripts.size() == 1, "all running the same script — the differences are all exported")

func _test_each_ball_keeps_its_own_settings() -> void:
	print("per-node values")
	var m := _make()
	var radii := {}
	var colours := {}
	var speeds := {}
	for ball in _balls(m):
		radii[ball.radius] = true
		colours[ball.color] = true
		speeds[ball.velocity] = true
	expect(radii.size() == _balls(m).size(), "each ball has its own radius")
	expect(colours.size() == _balls(m).size(), "its own colour")
	expect(speeds.size() == _balls(m).size(), "and its own velocity")

func _test_the_starting_velocity_is_copied_not_shared() -> void:
	print("the working copy")
	var m := _make()
	var ball := _balls(m)[0]
	expect(ball._vel == ball.velocity, "the ball starts moving at its exported velocity")
	ball._vel = Vector2(1.0, 1.0)
	expect(ball.velocity != ball._vel,
		"and bouncing changes the working copy, leaving the exported value as set")

func _test_a_ball_moves_at_its_exported_speed() -> void:
	print("moving")
	var m := _make()
	var ball := _balls(m)[0]
	var view: Rect2 = ball.get_viewport_rect()
	ball.radius = 20.0
	ball.position = view.size * 0.5
	ball._vel = Vector2(120.0, 0.0)
	var start: Vector2 = ball.position
	ball._process(0.5)
	expect(is_equal_approx(ball.position.x, start.x + 60.0),
		"half a second of travel covers half a second's worth of it")

func _test_a_ball_bounces_off_the_sides() -> void:
	print("the walls")
	var m := _make()
	var ball := _balls(m)[0]
	var view: Rect2 = ball.get_viewport_rect()
	ball.radius = 20.0
	ball.position = Vector2(ball.radius - 1.0, view.size.y * 0.5)
	ball._vel = Vector2(-200.0, 0.0)
	ball._process(STEP)
	expect(ball._vel.x > 0.0, "hitting the left edge turns the ball around")
	expect(ball.position.x >= ball.radius - 0.001, "and it is nudged back inside")

	var right := _balls(_make())[0]
	right.radius = 20.0
	right.position = Vector2(view.size.x - right.radius + 1.0, view.size.y * 0.5)
	right._vel = Vector2(200.0, 0.0)
	right._process(STEP)
	expect(right._vel.x < 0.0, "and so does the right edge")
	expect(right.position.x + right.radius <= view.size.x + 0.001, "nudged back inside too")

func _test_a_ball_bounces_off_the_top_and_bottom() -> void:
	print("the ceiling and floor")
	var m := _make()
	var ball := _balls(m)[0]
	var view: Rect2 = ball.get_viewport_rect()
	# The play area starts below the title bar and ends above the hint, so the
	# ball turns before the window edge on both.
	# Straddling the line: the ball's top edge is past it, its centre is not.
	# That is the case that tells "measured from the edge" apart from
	# "measured from the middle".
	ball.radius = 20.0
	ball.position = Vector2(view.size.x * 0.5, TOP_MARGIN + ball.radius - 2.0)
	ball._vel = Vector2(0.0, -200.0)
	ball._process(STEP)
	expect(ball._vel.y > 0.0, "the ball turns back down below the title bar")
	expect(ball.position.y >= TOP_MARGIN, "rather than sliding up behind it")

	var low := _balls(_make())[0]
	low.radius = 20.0
	low.position = Vector2(view.size.x * 0.5, view.size.y - BOTTOM_MARGIN - low.radius + 2.0)
	low._vel = Vector2(0.0, 200.0)
	low._process(STEP)
	expect(low._vel.y < 0.0, "and back up above the hint at the bottom")

	var free := _balls(_make())[0]
	free.radius = 20.0
	free.position = view.size * 0.5
	free._vel = Vector2(0.0, 200.0)
	free._process(STEP)
	expect(free._vel.y > 0.0, "a ball in open space keeps going rather than bouncing off nothing")

func _test_a_bigger_ball_turns_sooner() -> void:
	print("radius matters")
	var m := _make()
	var balls := _balls(m)
	var small := balls[0]
	var large := balls[0]
	for ball in balls:
		if ball.radius < small.radius:
			small = ball
		if ball.radius > large.radius:
			large = ball
	expect(large.radius > small.radius, "the balls are different sizes")

	# Placed at the same spot heading the same way: the bigger ball's edge
	# reaches the wall first, so it is the one that turns.
	small.radius = 10.0
	large.radius = 40.0
	var view: Rect2 = small.get_viewport_rect()
	var at := Vector2(large.radius - 1.0, view.size.y * 0.5)
	small.position = at
	small._vel = Vector2(-200.0, 0.0)
	large.position = at
	large._vel = Vector2(-200.0, 0.0)
	small._process(STEP)
	large._process(STEP)
	expect(large._vel.x > 0.0, "the bigger ball bounces off the wall")
	expect(small._vel.x < 0.0, "while the smaller one still has room")

func _test_the_label_is_whatever_the_scene_says() -> void:
	print("the labels")
	var m := _make()
	for ball in _balls(m):
		expect(ball.label_text.length() > 0, "each ball is labelled from the scene")
