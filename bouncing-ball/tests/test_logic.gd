extends Node

# Drives the real scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The bounce here belongs to the physics engine, not to a script: the demo is a
# RigidBody2D with a bouncy PhysicsMaterial inside four static walls. So the
# suite runs the actual scene and watches the ball, rather than reimplementing
# a bounce that exists nowhere in the demo. tests/frames buys the physics time.

var _pass := 0
var _fail := 0

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

const RADIUS := 20.0
const FLOOR_TOP := 460.0     # Floor body sits at y=470 with a 20-tall box
const LEFT_WALL := 20.0      # inner face of the left wall
const RIGHT_WALL := 620.0

var _ball: RigidBody2D
var _samples: Array[Vector2] = []

func _ready() -> void:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	_ball = scene.get_node("Ball")

	var start := _ball.position
	# ~1.3s of simulation: long enough to fall, land, and come back up.
	for i in 80:
		await get_tree().physics_frame
		_samples.append(_ball.position)

	_test_the_ball_falls()
	_test_it_never_leaves_the_box(start)
	_test_it_bounces_back_up()
	_test_the_bounce_loses_energy()
	_test_the_material_is_what_makes_it_bounce()
	_test_the_walls_are_visible(scene)
	await _test_clicking_puts_the_ball_back(scene)
	_report()

func _lowest_index() -> int:
	var idx := 0
	for i in _samples.size():
		if _samples[i].y > _samples[idx].y:
			idx = i
	return idx

func _test_the_ball_falls() -> void:
	print("gravity")
	expect(_samples.size() > 0, "the simulation ran")
	expect(_samples[_samples.size() - 1].y > 60.0, "the ball leaves its starting height")
	expect(_samples[_lowest_index()].y > 300.0, "and gets most of the way down the screen")

func _test_it_never_leaves_the_box(start: Vector2) -> void:
	print("containment")
	# Measured against the ball's centre, not its edge. A fast body overlaps a
	# surface by up to one step of travel before the solver pushes it out —
	# around 13 px here — but the centre crossing a wall means it tunnelled.
	var contained := true
	for p in _samples:
		if p.y > FLOOR_TOP or p.x < LEFT_WALL or p.x > RIGHT_WALL:
			contained = false
	expect(contained, "the ball never passes through a wall")
	expect(start.y < FLOOR_TOP, "which it started inside of")

func _test_it_bounces_back_up() -> void:
	print("the bounce")
	var low := _lowest_index()
	var rebound := 0.0
	for i in range(low, _samples.size()):
		rebound = maxf(rebound, _samples[low].y - _samples[i].y)
	expect(low < _samples.size() - 1, "the ball reaches the floor before the run ends")
	expect(rebound > 20.0, "and comes back up afterwards rather than resting on it")

func _test_the_bounce_loses_energy() -> void:
	print("restitution")
	var low := _lowest_index()
	var apex := _samples[low].y
	for i in range(low, _samples.size()):
		apex = minf(apex, _samples[i].y)
	expect(apex > _samples[0].y, "the rebound falls short of the drop height — the bounce is lossy")

func _test_the_material_is_what_makes_it_bounce() -> void:
	print("scene setup")
	# The demo's whole point: bounce lives on the PhysicsMaterial, not in code.
	var mat := _ball.physics_material_override
	expect(mat != null, "the ball has a physics material override")
	expect(mat != null and mat.bounce > 0.5, "with a high restitution")
	expect(mat != null and mat.bounce < 1.0, "but short of perfectly elastic")

func _test_the_walls_are_visible(scene: Node2D) -> void:
	print("the box")
	# The walls used to be bare collision shapes, which the editor draws and a
	# running game does not — the ball rebounded off nothing visible. main.tscn
	# now draws them, reading the rectangles back out of the shapes so the
	# drawing cannot drift away from the physics.
	var drawn: Array[Rect2] = scene.wall_rects()
	expect(drawn.size() == 4, "all four walls are drawn (%d)" % drawn.size())

	_quiet_failures = 0
	for wall_name in ["Floor", "Ceiling", "LeftWall", "RightWall"]:
		var body: StaticBody2D = scene.get_node(wall_name)
		var collider: CollisionShape2D = body.get_node("CollisionShape2D")
		var box: RectangleShape2D = collider.shape
		var want := Rect2(body.position + collider.position - box.size * 0.5, box.size)
		var found := false
		for rect in drawn:
			if rect.position.is_equal_approx(want.position) and rect.size.is_equal_approx(want.size):
				found = true
		expect_quiet(found, "%s is drawn where its collider is (%s)" % [wall_name, want])
	expect(_quiet_failures == 0, "every wall is drawn exactly where the physics puts it")

	# The box has to enclose the play area, or the ball is falling past the
	# picture rather than inside it.
	var union: Rect2 = drawn[0]
	for rect in drawn:
		union = union.merge(rect)
	expect(union.size.x >= 640.0 and union.size.y >= 480.0,
		"the walls span the whole window (%s)" % union.size)

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")

func _test_clicking_puts_the_ball_back(scene: Node2D) -> void:
	print("the reset")
	# The hint on screen promises this, and for a long time nothing implemented
	# it — the scene had no script at all. Driving the handler rather than
	# calling reset_ball() directly, so the wiring is covered too.
	var away: Vector2 = _ball.position
	expect(away.distance_to(scene.BALL_START) > 100.0,
		"the ball has moved well away from its start (%s)" % away)

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	scene._unhandled_input(click)
	# The physics server owns the transform; the write lands on the next step.
	await get_tree().physics_frame
	await get_tree().physics_frame

	expect(_ball.position.distance_to(scene.BALL_START) < 40.0,
		"clicking returns it to the top (%s)" % _ball.position)
	expect(_ball.linear_velocity.length() < 200.0,
		"and it arrives without the speed it had (%.0f)" % _ball.linear_velocity.length())

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	var before: Vector2 = _ball.position
	scene._unhandled_input(release)
	await get_tree().physics_frame
	expect(_ball.position.y > before.y, "releasing the button does not reset it again")
