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
