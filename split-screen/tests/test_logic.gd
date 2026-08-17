extends Node

# Drives the real players from scripts/player.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_each_player_owns_its_keys()
	_test_the_two_players_share_no_key()
	_test_gravity_only_applies_in_the_air()
	_test_jumping_from_the_floor()
	_test_jumping_in_mid_air_does_nothing()
	_test_a_missed_jump_is_not_queued()
	_test_horizontal_speed_follows_input()
	_test_only_this_players_jump_key_latches()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) < tol, label)

func _report() -> void:
	var summary := "[split-screen] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/player.gd")

func _make(wasd: bool) -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.set_script(_script)
	p.use_wasd = wasd
	add_child(p)
	return p

func _test_each_player_owns_its_keys() -> void:
	print("key assignment")
	var one := _make(true)
	var two := _make(false)
	expect(one.jump_key() == KEY_W and one.left_key() == KEY_A and one.right_key() == KEY_D,
		"the WASD player gets W/A/D")
	expect(two.jump_key() == KEY_UP and two.left_key() == KEY_LEFT and two.right_key() == KEY_RIGHT,
		"the other gets the arrow keys")

func _test_the_two_players_share_no_key() -> void:
	print("no overlap")
	# Sharing even one key would make split-screen unplayable on one keyboard.
	var one := _make(true)
	var two := _make(false)
	var mine := [one.jump_key(), one.left_key(), one.right_key()]
	var theirs := [two.jump_key(), two.left_key(), two.right_key()]
	var overlap := false
	for k in mine:
		if theirs.has(k):
			overlap = true
	expect(not overlap, "the two players' key sets are disjoint")

func _test_gravity_only_applies_in_the_air() -> void:
	print("gravity")
	var p := _make(true)
	p.tick_velocity(1.0, 0.0, false)
	expect_approx(p.velocity.y, p.GRAVITY, "airborne, a second of falling adds a second of gravity")

	var grounded := _make(true)
	grounded.tick_velocity(1.0, 0.0, true)
	expect_approx(grounded.velocity.y, 0.0, "standing on the floor, it does not accumulate")

func _test_jumping_from_the_floor() -> void:
	print("jumping")
	var p := _make(true)
	p.request_jump()
	p.tick_velocity(STEP, 0.0, true)
	expect_approx(p.velocity.y, p.JUMP_VEL, "a jump from the floor sets the jump velocity")
	expect(p.JUMP_VEL < 0.0, "which is upward")
	expect(not p.jump_requested(), "and the request is consumed")

	# One press, one jump — holding the key must not re-trigger. Zeroing the
	# velocity first makes a second jump visible; without it the frame is a no-op
	# either way.
	p.velocity.y = 0.0
	p.tick_velocity(STEP, 0.0, true)
	expect_approx(p.velocity.y, 0.0, "the next frame does not jump again")

func _test_jumping_in_mid_air_does_nothing() -> void:
	print("mid-air jump")
	var p := _make(true)
	p.request_jump()
	p.tick_velocity(STEP, 0.0, false)
	expect(p.velocity.y > 0.0, "pressing jump while falling does not launch the player")

func _test_a_missed_jump_is_not_queued() -> void:
	print("no jump buffering here")
	var p := _make(true)
	p.request_jump()
	p.tick_velocity(STEP, 0.0, false)   # pressed in the air — dropped
	expect(not p.jump_requested(), "the request is spent even though it did not land")
	p.tick_velocity(STEP, 0.0, true)    # now touching down
	expect(p.velocity.y != p.JUMP_VEL, "so touching the floor does not fire a stored jump")

func _test_horizontal_speed_follows_input() -> void:
	print("horizontal movement")
	var p := _make(true)
	p.tick_velocity(STEP, 1.0, true)
	expect_approx(p.velocity.x, p.SPEED, "full right input moves at full speed")
	p.tick_velocity(STEP, -1.0, true)
	expect_approx(p.velocity.x, -p.SPEED, "and left is the mirror of it")
	p.tick_velocity(STEP, 0.0, true)
	expect_approx(p.velocity.x, 0.0, "no input stops immediately — no momentum in this demo")

func _key(code: Key, pressed: bool, echo: bool = false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = pressed
	e.echo = echo
	return e

func _test_only_this_players_jump_key_latches() -> void:
	print("the jump latch")
	var p := _make(true)
	p._unhandled_key_input(_key(p.jump_key(), true))
	expect(p.jump_requested(), "pressing this player's jump key latches a request")

	var other := _make(true)
	other._unhandled_key_input(_key(KEY_UP, true))
	expect(not other.jump_requested(), "the other player's jump key does not")

	var released := _make(true)
	released._unhandled_key_input(_key(released.jump_key(), false))
	expect(not released.jump_requested(), "releasing the key does not latch one either")

	# Held keys repeat as echo events; each would be a fresh jump.
	var repeated := _make(true)
	repeated._unhandled_key_input(_key(repeated.jump_key(), true, true))
	expect(not repeated.jump_requested(), "and neither does an auto-repeat echo")
