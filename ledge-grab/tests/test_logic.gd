extends Node

# Drives the real player from scripts/player.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_player_starts_idle()
	_test_walking_on_the_ground()
	_test_jumping_from_the_ground()
	_test_falling_in_the_air()
	_test_air_control_is_gradual()
	_test_a_wall_slows_the_fall()
	_test_a_wall_takes_away_horizontal_control()
	_test_a_wall_jump_pushes_off_the_wall()
	_test_a_wall_jump_goes_up()
	_test_the_state_follows_what_the_player_is_doing()
	_test_the_readout_names_the_state()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[ledge-grab] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/player.gd")

func _make() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.set_script(_script)
	add_child(p)
	return p

func _ground(p: CharacterBody2D, dir: float, jump: bool = false) -> void:
	p.tick(STEP, dir, jump, true, false, 0.0)

func _air(p: CharacterBody2D, dir: float, jump: bool = false) -> void:
	p.tick(STEP, dir, jump, false, false, 0.0)

## On a wall whose normal points right — that is, a wall on the player's left.
func _wall(p: CharacterBody2D, dir: float, jump: bool = false, normal_x: float = 1.0) -> void:
	p.tick(STEP, dir, jump, false, true, normal_x)

func _test_the_player_starts_idle() -> void:
	print("standing")
	var p := _make()
	expect(p.state == p.State.IDLE, "the player starts idle")

func _test_walking_on_the_ground() -> void:
	print("walking")
	var p := _make()
	_ground(p, 1.0)
	expect(is_equal_approx(p.velocity.x, p.SPEED), "on the ground the player moves at full speed at once")
	_ground(p, -1.0)
	expect(is_equal_approx(p.velocity.x, -p.SPEED), "in either direction")
	_ground(p, 0.0)
	expect(is_zero_approx(p.velocity.x), "and stops as soon as the key is released")

func _test_jumping_from_the_ground() -> void:
	print("jumping")
	var p := _make()
	_ground(p, 0.0, true)
	expect(is_equal_approx(p.velocity.y, p.JUMP_VEL), "a jump from the floor takes the jump velocity")
	expect(p.JUMP_VEL < 0.0, "which is upward")

func _test_falling_in_the_air() -> void:
	print("falling")
	var p := _make()
	_air(p, 0.0)
	expect(p.velocity.y > 0.0, "gravity pulls in the air")
	var first: float = p.velocity.y
	_air(p, 0.0)
	expect(p.velocity.y > first, "and keeps accelerating")

func _test_air_control_is_gradual() -> void:
	print("air control")
	var p := _make()
	_ground(p, 0.0)
	_air(p, 1.0)
	# Full speed instantly in mid-air would make the jump arc pointless.
	expect(p.velocity.x > 0.0, "steering in the air does something")
	expect(p.velocity.x < p.SPEED, "but not everything at once")
	for i in 120:
		_air(p, 1.0)
	expect(absf(p.velocity.x - p.SPEED) < 1.0, "given long enough it reaches full speed")

func _test_a_wall_slows_the_fall() -> void:
	print("wall slide")
	var p := _make()
	p.velocity.y = 500.0
	_wall(p, 0.0)
	expect(p.velocity.y <= p.WALL_SLIDE, "sliding a wall caps the fall speed")
	expect(p.WALL_SLIDE > 0.0, "at a slow slide rather than a stop")

	# From rest, a player on a wall slides down it — not up it.
	var resting := _make()
	for i in 10:
		_wall(resting, 0.0)
	expect(resting.velocity.y > 0.0, "and a player at rest on a wall slides downwards")

	var falling := _make()
	for i in 120:
		_air(falling, 0.0)
	expect(falling.velocity.y > p.WALL_SLIDE, "which is much slower than an open fall")

func _test_a_wall_takes_away_horizontal_control() -> void:
	print("stuck to the wall")
	var p := _make()
	_wall(p, 1.0)
	expect(is_zero_approx(p.velocity.x), "pressing away from the wall does not peel the player off")

func _test_a_wall_jump_pushes_off_the_wall() -> void:
	print("wall jump")
	# The wall normal points away from the wall, so the push follows it. A wall
	# on the left gives a normal pointing right, and the jump has to go right.
	var from_left := _make()
	_wall(from_left, 0.0, true, 1.0)
	expect(from_left.velocity.x > 0.0, "a wall on the left throws the player right")

	var from_right := _make()
	_wall(from_right, 0.0, true, -1.0)
	expect(from_right.velocity.x < 0.0, "and a wall on the right throws them left")
	expect(is_equal_approx(absf(from_right.velocity.x), from_right.WALL_JUMP_X),
		"at the wall-jump strength")

func _test_a_wall_jump_goes_up() -> void:
	print("wall jump height")
	var p := _make()
	p.velocity.y = 60.0
	_wall(p, 0.0, true, 1.0)
	expect(p.velocity.y < 0.0, "a wall jump also carries the player upwards")
	expect(is_equal_approx(p.velocity.y, p.WALL_JUMP_Y), "by the wall-jump height")

func _test_the_state_follows_what_the_player_is_doing() -> void:
	print("states")
	var p := _make()
	_ground(p, 0.0)
	expect(p.state == p.State.IDLE, "standing still on the ground is idle")
	_ground(p, 1.0)
	expect(p.state == p.State.RUN, "moving along it is running")
	# The frame the jump is pressed the player is still on the floor; the state
	# turns over once they have left it.
	_ground(p, 0.0, true)
	p.update_state(false, false)
	expect(p.state == p.State.JUMP, "rising is jumping")
	var falling := _make()
	_air(falling, 0.0)
	expect(falling.state == falling.State.FALL, "and coming down is falling")
	var sliding := _make()
	_wall(sliding, 0.0)
	expect(sliding.state == sliding.State.WALL_SLIDE, "on a wall it is a wall slide")

func _test_the_readout_names_the_state() -> void:
	print("the readout")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	var player: CharacterBody2D = scene.get_node("Player")
	var label: Label = player.get_node("StateLabel")
	player.update_state(true, false)
	player.velocity.x = 200.0
	player.update_state(true, false)
	expect(label.text == "RUN", "the label names the state the player is in")
	player.velocity.x = 0.0
	player.update_state(true, false)
	expect(label.text == "IDLE", "and follows it as it changes")
	scene.free()
