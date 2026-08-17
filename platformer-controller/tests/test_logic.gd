extends Node

# Drives the real player from scripts/player.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_gravity_only_pulls_in_the_air()
	_test_jumping_from_the_ground()
	_test_jumping_just_after_walking_off_a_ledge()
	_test_coyote_time_runs_out()
	_test_a_jump_pressed_just_before_landing_still_fires()
	_test_the_buffer_runs_out()
	_test_one_press_is_one_jump()
	_test_a_jump_in_open_air_does_nothing()
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
	var summary := "[platformer-controller] %d/%d passed" % [_pass, _pass + _fail]
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

## Stand on the floor for a moment, so the coyote window is full.
func _grounded(p: CharacterBody2D) -> void:
	p.tick_jump(STEP, false, true)

func _jumped(p: CharacterBody2D) -> bool:
	return is_equal_approx(p.velocity.y, p.JUMP_VEL)

func _test_gravity_only_pulls_in_the_air() -> void:
	print("gravity")
	var p := _make()
	p.tick_jump(1.0, false, false)
	expect(is_equal_approx(p.velocity.y, p.GRAVITY), "a second of falling is a second of gravity")

	var standing := _make()
	standing.tick_jump(1.0, false, true)
	expect(is_zero_approx(standing.velocity.y), "standing on the floor it does not build up")

func _test_jumping_from_the_ground() -> void:
	print("the ordinary jump")
	var p := _make()
	_grounded(p)
	p.tick_jump(STEP, true, true)
	expect(_jumped(p), "pressing jump on the ground jumps")
	expect(p.JUMP_VEL < 0.0, "upwards")

func _test_jumping_just_after_walking_off_a_ledge() -> void:
	print("coyote time")
	var p := _make()
	_grounded(p)
	# One frame of air — the player has left the ledge but has not registered it.
	p.tick_jump(STEP, false, false)
	p.tick_jump(STEP, true, false)
	expect(_jumped(p), "a jump just after leaving the ledge still fires")

func _test_coyote_time_runs_out() -> void:
	print("coyote expiry")
	var p := _make()
	_grounded(p)
	expect(p.coyote_left() > 0.0, "the window opens on the ground")
	var frames := int(p.COYOTE_TIME / STEP) + 2
	for i in frames:
		p.tick_jump(STEP, false, false)
	expect(is_zero_approx(p.coyote_left()), "and closes after COYOTE_TIME in the air")
	p.velocity.y = 0.0
	p.tick_jump(STEP, true, false)
	expect(not _jumped(p), "after which a jump in mid-air does nothing")

func _test_a_jump_pressed_just_before_landing_still_fires() -> void:
	print("jump buffering")
	var p := _make()
	# Falling, and the player presses jump slightly too early.
	p.tick_jump(STEP, true, false)
	expect(not _jumped(p), "the press does not jump in mid-air")
	expect(p.buffer_left() > 0.0, "but it is remembered")
	p.tick_jump(STEP, false, true)
	expect(_jumped(p), "and fires the moment the player lands")

func _test_the_buffer_runs_out() -> void:
	print("buffer expiry")
	var p := _make()
	p.tick_jump(STEP, true, false)
	var frames := int(p.JUMP_BUFFER / STEP) + 2
	for i in frames:
		p.tick_jump(STEP, false, false)
	expect(is_zero_approx(p.buffer_left()), "a press held in the buffer expires")
	p.velocity.y = 0.0
	p.tick_jump(STEP, false, true)
	expect(not _jumped(p), "so landing much later does not jump on its own")

func _test_one_press_is_one_jump() -> void:
	print("no double jumps")
	var p := _make()
	_grounded(p)
	p.tick_jump(STEP, true, true)
	expect(_jumped(p), "the press jumps")
	p.velocity.y = 0.0
	p.tick_jump(STEP, false, false)
	expect(not _jumped(p), "and the leftovers of it do not jump again")
	expect(is_zero_approx(p.buffer_left()), "both windows were spent by the jump")

func _test_a_jump_in_open_air_does_nothing() -> void:
	print("no free jumps")
	var p := _make()
	# Never touched the ground, so there is no coyote window to spend.
	for i in 30:
		p.tick_jump(STEP, false, false)
	p.velocity.y = 0.0
	p.tick_jump(STEP, true, false)
	expect(not _jumped(p), "a player who never left a ledge cannot jump from mid-air")

func _test_the_readout_names_the_state() -> void:
	print("the on-screen readout")
	# This one needs the player from the real scene, because the label it writes
	# to is a child node the scene supplies.
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	var p: CharacterBody2D = scene.get_node("Player")
	var label: Label = p.get_node("InfoLabel")

	p._update_label()
	expect(label.text.length() > 0, "the label says something")

	# Just off a ledge: the coyote window is open and nothing is buffered. The
	# two readings never appear together — a press with both open jumps at once,
	# spending them.
	p.tick_jump(STEP, false, true)
	p.tick_jump(STEP, false, false)
	p._update_label()
	expect(label.text.contains("COYOTE"), "it shows coyote time while the window is open")
	expect(not label.text.contains("BUFFERED"), "with nothing buffered yet")

	# Falling from a height nobody walked off: a press is buffered, not spent.
	p.tick_jump(STEP, true, false)
	for i in 40:
		p.tick_jump(STEP, false, false)
	p.tick_jump(STEP, true, false)
	p._update_label()
	expect(label.text.contains("AIR"), "once the coyote window closes it just says AIR")
	expect(label.text.contains("BUFFERED"), "and shows the press waiting to land")

	for i in 40:
		p.tick_jump(STEP, false, false)
	p._update_label()
	expect(not label.text.contains("BUFFERED"), "an expired buffer stops being reported")
	scene.free()
