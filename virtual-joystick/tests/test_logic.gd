extends Node

# Drives the real joystick and player from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_stick_starts_centred()
	_test_pressing_the_pad_moves_the_knob()
	_test_the_knob_cannot_leave_the_base()
	_test_the_direction_is_a_fraction_of_full_deflection()
	_test_a_small_push_is_a_small_direction()
	_test_dragging_steers()
	_test_letting_go_re_centres()
	_test_moving_without_holding_does_nothing()
	_test_the_player_follows_the_stick()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[virtual-joystick] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _stick(m: Node2D) -> Control:
	return m.get_node("CanvasLayer/Joystick")

func _press(stick: Control, at: Vector2, pressed: bool = true) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	stick._gui_input(e)

func _drag(stick: Control, to: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = to
	stick._gui_input(e)

func _test_the_stick_starts_centred() -> void:
	print("at rest")
	var stick := _stick(_make())
	expect(stick.direction == Vector2.ZERO, "an untouched stick reports no direction")
	expect(stick._knob_pos == stick._origin, "with the knob sitting in the middle")

func _test_pressing_the_pad_moves_the_knob() -> void:
	print("pressing")
	var stick := _stick(_make())
	_press(stick, stick._origin + Vector2(20.0, 0.0))
	expect(stick._active, "pressing takes hold of the stick")
	expect(stick.direction.x > 0.0, "and pushing right reports right")
	expect(is_zero_approx(stick.direction.y), "with nothing on the other axis")

func _test_the_knob_cannot_leave_the_base() -> void:
	print("the edge of the base")
	var stick := _stick(_make())
	_press(stick, stick._origin + Vector2(500.0, 500.0))
	expect(stick._origin.distance_to(stick._knob_pos) <= stick.BASE_RADIUS + 0.001,
		"the knob stays inside the base however far the finger goes")
	expect(stick.direction.length() <= 1.0001, "and the direction never exceeds full deflection")

func _test_the_direction_is_a_fraction_of_full_deflection() -> void:
	print("full deflection")
	var stick := _stick(_make())
	_press(stick, stick._origin + Vector2(stick.BASE_RADIUS, 0.0))
	expect(is_equal_approx(stick.direction.length(), 1.0),
		"a finger at the edge of the base is full deflection")
	expect(is_equal_approx(stick.direction.x, 1.0), "straight right")

func _test_a_small_push_is_a_small_direction() -> void:
	print("analogue")
	var stick := _stick(_make())
	# The whole point of a stick over a d-pad: half way out is half speed.
	_press(stick, stick._origin + Vector2(stick.BASE_RADIUS * 0.5, 0.0))
	expect(is_equal_approx(stick.direction.length(), 0.5), "half way out is half a direction")

func _test_dragging_steers() -> void:
	print("steering")
	var stick := _stick(_make())
	_press(stick, stick._origin + Vector2(30.0, 0.0))
	expect(stick.direction.x > 0.0, "pushed right")
	_drag(stick, stick._origin + Vector2(0.0, -30.0))
	expect(stick.direction.y < 0.0, "dragging up steers up")
	expect(is_zero_approx(stick.direction.x), "and lets go of right")

func _test_letting_go_re_centres() -> void:
	print("releasing")
	var stick := _stick(_make())
	_press(stick, stick._origin + Vector2(40.0, 20.0))
	_press(stick, stick._origin + Vector2(40.0, 20.0), false)
	expect(not stick._active, "releasing lets go of the stick")
	expect(stick.direction == Vector2.ZERO, "the direction returns to nothing")
	expect(stick._knob_pos == stick._origin, "and the knob springs back to the middle")

func _test_moving_without_holding_does_nothing() -> void:
	print("hovering")
	var stick := _stick(_make())
	_drag(stick, stick._origin + Vector2(40.0, 0.0))
	expect(stick.direction == Vector2.ZERO, "moving the mouse without pressing does not steer")

func _test_the_player_follows_the_stick() -> void:
	print("the player")
	var m := _make()
	var stick := _stick(m)
	var player: CharacterBody2D = m.get_node("Player")
	expect(player.joystick == stick, "the player is wired to the stick")

	_press(stick, stick._origin + Vector2(stick.BASE_RADIUS, 0.0))
	player._physics_process(1.0 / 60.0)
	expect(player.velocity.x > 0.0, "full right on the stick moves the player right")
	expect(is_equal_approx(player.velocity.length(), player.SPEED), "at full speed")

	_press(stick, stick._origin, false)
	player._physics_process(1.0 / 60.0)
	expect(player.velocity == Vector2.ZERO, "and letting go stops them")
