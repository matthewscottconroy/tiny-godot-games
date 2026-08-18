extends Node

# Drives the real swimming from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_water_carries_a_shader()
	_test_the_shader_takes_the_wave_settings()
	_test_the_sliders_reach_the_shader()
	_test_the_player_starts_dry_and_airborne()
	_test_going_under_is_noticed()
	_test_the_waterline_is_measured_at_the_feet()
	_test_landing_and_leaving_the_floor()
	_test_standing_still_is_not_jumping()
	_test_water_slows_the_fall()
	_test_water_slows_the_swimmer()
	_test_a_swim_stroke_is_weaker_than_a_jump()
	_test_water_drags_the_player_to_a_stop()
	_test_the_player_stays_in_the_world()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[2d-water] %d/%d passed" % [_pass, _pass + _fail]
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

## Put the player above or below the waterline, at rest.
func _place(m: Node2D, y: float) -> void:
	m._player_pos = Vector2(320.0, y)
	m._vel = Vector2.ZERO
	m._on_floor = false

func _above_water(m: Node2D) -> float:
	return m.WATER_Y - 100.0

func _below_water(m: Node2D) -> float:
	return m.WATER_Y + 80.0

func _test_the_water_carries_a_shader() -> void:
	print("the water")
	var m := _make()
	expect(m._water_mat != null, "the water surface has a shader material")
	expect(m._water_mat != null and m._water_mat.shader != null, "with a shader in it")

func _test_the_shader_takes_the_wave_settings() -> void:
	print("the uniforms")
	var m := _make()
	var code: String = m._water_mat.shader.code
	begin_quiet()
	for uniform in ["wave_speed", "wave_amplitude"]:
		# A slider wired to a uniform the shader never declares moves nothing.
		expect_quiet(code.contains(uniform), "the shader has no %s uniform" % uniform)
	expect(_quiet_failures == 0, "the shader declares both wave settings")

func _test_the_sliders_reach_the_shader() -> void:
	print("the sliders")
	var m := _make()
	var speed: HSlider = m.get_node("HUD/SpeedRow/SpeedSlider")
	var amplitude: HSlider = m.get_node("HUD/AmpRow/AmpSlider")
	speed.value = 2.0
	expect(is_equal_approx(float(m._water_mat.get_shader_parameter("wave_speed")), 2.0),
		"the speed slider sets the wave speed")
	amplitude.value = 0.03
	expect(is_equal_approx(float(m._water_mat.get_shader_parameter("wave_amplitude")), 0.03),
		"and the amplitude slider the wave height")

func _test_going_under_is_noticed() -> void:
	print("the waterline")
	var m := _make()
	_place(m, _above_water(m))
	m.tick(STEP, 0.0, false)
	expect(not m._in_water, "above the line the player is dry")
	_place(m, _below_water(m))
	m.tick(STEP, 0.0, false)
	expect(m._in_water, "and below it they are in the water")

func _test_the_player_starts_dry_and_airborne() -> void:
	print("before the first step")
	var m := _make()
	# The demo drops the player in from above the water, so both flags start
	# false and the first tick works them out.
	expect(not m._in_water, "the player starts out of the water")
	expect(not m._on_floor, "and in the air")

func _test_the_waterline_is_measured_at_the_feet() -> void:
	print("where the waterline is measured")
	var m := _make()
	# Straddling the line: the player's feet are under it while their middle is
	# still above. Measuring from the middle would call this dry.
	_place(m, m.WATER_Y - 12.0)
	m.tick(STEP, 0.0, false)
	expect(m._in_water, "a player whose feet are under the line is in the water")

	# The waterline is copied out before the next scene is built, since making
	# it frees this one.
	var line: float = m.WATER_Y
	var clear := _make()
	_place(clear, line - 40.0)
	clear.tick(STEP, 0.0, false)
	expect(not clear._in_water, "and one entirely above it is not")

func _test_landing_and_leaving_the_floor() -> void:
	print("the floor")
	var m := _make()
	# Sinking is slow: underwater gravity is a fifth of normal and the drag
	# takes most of what is left, so this takes seconds rather than frames.
	_place(m, 400.0)
	for i in 900:
		m.tick(STEP, 0.0, false)
	expect(m._on_floor, "the player comes to rest on the floor")
	expect(is_equal_approx(m._player_pos.y, 460.0), "at the floor line")

	var airborne := _make()
	_place(airborne, 200.0)
	airborne.tick(STEP, 0.0, false)
	expect(not airborne._on_floor, "and is not on the floor while still above it")

func _test_standing_still_is_not_jumping() -> void:
	print("standing on the floor")
	var m := _make()
	_place(m, 460.0)
	for i in 5:
		m.tick(STEP, 0.0, false)
	expect(m._on_floor, "standing on the floor")
	# Jumping needs the key as well as the ground; without both, the player
	# would launch every frame they stood there.
	expect(m._vel.y >= 0.0, "and not pressing jump leaves them there")

func _test_water_slows_the_fall() -> void:
	print("sinking")
	var air := _make()
	_place(air, _above_water(air))
	air.tick(0.2, 0.0, false)
	var air_fall: float = air._vel.y

	var water := _make()
	_place(water, _below_water(water))
	water.tick(0.2, 0.0, false)
	expect(water._vel.y < air_fall,
		"a player in the water sinks more slowly than one falling through air")
	expect(water._vel.y > 0.0, "but still sinks")

func _test_water_slows_the_swimmer() -> void:
	print("swimming across")
	var air := _make()
	_place(air, _above_water(air))
	air.tick(STEP, 1.0, false)
	var air_speed: float = absf(air._vel.x)

	var water := _make()
	_place(water, _below_water(water))
	water.tick(STEP, 1.0, false)
	expect(absf(water._vel.x) < air_speed, "swimming across is slower than running")
	expect(absf(water._vel.x) > 0.0, "but the player still moves")

func _test_a_swim_stroke_is_weaker_than_a_jump() -> void:
	print("swimming up")
	# Measured against the jump constant rather than a staged dry jump: the
	# ground in this demo sits below the waterline, so there is nowhere dry to
	# jump from and a staged one would be a swim stroke as well.
	var swimmer := _make()
	_place(swimmer, _below_water(swimmer))
	swimmer.tick(STEP, 0.0, true)
	expect(swimmer._vel.y < 0.0, "a stroke carries the swimmer upwards")
	expect(swimmer._vel.y > swimmer.JUMP_VEL,
		"less strongly than a jump would (%.0f against %.0f)" % [swimmer._vel.y, swimmer.JUMP_VEL])

func _test_water_drags_the_player_to_a_stop() -> void:
	print("drag")
	var m := _make()
	_place(m, _below_water(m))
	m._vel = Vector2(300.0, 0.0)
	m.tick(STEP, 0.0, false)
	var after_one: float = absf(m._vel.x)
	# Drag is what stops the player gliding across the pool forever.
	expect(after_one < 300.0, "the water slows a moving player")

	for i in 120:
		m.tick(STEP, 0.0, false)
	expect(absf(m._vel.x) < 1.0, "and brings them to a stop when they stop swimming")

func _test_the_player_stays_in_the_world() -> void:
	print("the edges")
	var m := _make()
	_place(m, 200.0)
	for i in 300:
		m.tick(STEP, -1.0, false)
	expect(m._player_pos.x >= 14.0, "swimming left stops at the wall")
	for i in 600:
		m.tick(STEP, 1.0, false)
	expect(m._player_pos.x <= 626.0, "and swimming right at the other one")
	expect(m._player_pos.y <= 460.0, "with the floor holding them up")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
