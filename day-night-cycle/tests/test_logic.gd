extends Node

# Drives the real cycle from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_keyframes_run_from_midnight_to_midnight()
	_test_the_cycle_loops_seamlessly()
	_test_time_advances_and_wraps()
	_test_a_full_day_takes_the_stated_length()
	_test_the_speed_buttons_change_the_pace()
	_test_a_keyframe_returns_its_own_colour()
	_test_between_keyframes_the_colour_is_blended()
	_test_the_sky_is_darkest_at_midnight()
	_test_the_clock_reads_the_time()
	_test_the_canvas_is_tinted_from_the_cycle()
	_test_a_time_outside_the_day_falls_back()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[day-night-cycle] %d/%d passed" % [_pass, _pass + _fail]
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

func _run(m: Node2D, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		m._process(STEP)
		elapsed += STEP

func _sky(m: Node2D, t: float) -> Color:
	return m._lerp_keyframes(t, 0)

func _test_the_keyframes_run_from_midnight_to_midnight() -> void:
	print("the keyframes")
	var m := _make()
	begin_quiet()
	var previous := -1.0
	for frame in m.KEYFRAMES:
		expect_quiet(frame[0] > previous, "keyframe times run forwards")
		previous = frame[0]
	expect(_quiet_failures == 0, "the keyframes are in order")
	expect(is_zero_approx(m.KEYFRAMES[0][0]), "starting at the top of the cycle")
	expect(is_equal_approx(m.KEYFRAMES[m.KEYFRAMES.size() - 1][0], 1.0), "and ending at the end of it")

func _test_the_cycle_loops_seamlessly() -> void:
	print("the loop")
	var m := _make()
	# The last keyframe is the first one again: any difference would show as a
	# jump in the sky at midnight.
	expect(_sky(m, 0.0).is_equal_approx(_sky(m, 1.0)),
		"midnight at each end of the cycle is the same colour")
	expect(m._lerp_keyframes(0.0, 1).is_equal_approx(m._lerp_keyframes(1.0, 1)),
		"and so is the light it casts")

func _test_time_advances_and_wraps() -> void:
	print("time passing")
	var m := _make()
	m._time = 0.0
	_run(m, 1.0)
	expect(m._time > 0.0, "time moves on")
	m._time = 0.999
	_run(m, 1.0)
	expect(m._time < 0.5, "and wraps round rather than running past the end of the day")

func _test_a_full_day_takes_the_stated_length() -> void:
	print("day length")
	var m := _make()
	m._time = 0.0
	m._speed = 1.0
	_run(m, m.DAY_LENGTH * 0.5)
	expect(absf(m._time - 0.5) < 0.02, "half the day length is half a day (%.3f)" % m._time)

func _test_the_speed_buttons_change_the_pace() -> void:
	print("the speed buttons")
	var m := _make()
	(m.get_node("HUD/SpeedRow/FastBtn") as Button).pressed.emit()
	var fast: float = m._speed
	(m.get_node("HUD/SpeedRow/SlowBtn") as Button).pressed.emit()
	var slow: float = m._speed
	(m.get_node("HUD/SpeedRow/NormalBtn") as Button).pressed.emit()
	expect(fast > m._speed and m._speed > slow, "fast, normal and slow are three different paces")
	expect(slow > 0.0, "and none of them stops time")

	# Each measured before the next scene is built: _make() frees the previous
	# one, and reading from a freed node aborts this test rather than failing it.
	var quick := _make()
	quick._time = 0.0
	(quick.get_node("HUD/SpeedRow/FastBtn") as Button).pressed.emit()
	_run(quick, 1.0)
	var quick_time: float = quick._time

	var steady := _make()
	steady._time = 0.0
	_run(steady, 1.0)
	expect(quick_time > steady._time, "and the fast one really does run the day down quicker")

func _test_a_keyframe_returns_its_own_colour() -> void:
	print("on a keyframe")
	var m := _make()
	begin_quiet()
	for frame in m.KEYFRAMES:
		expect_quiet(_sky(m, frame[0]).is_equal_approx(frame[1]),
			"the sky at t=%.2f is that keyframe's colour" % frame[0])
	expect(_quiet_failures == 0, "landing exactly on a keyframe gives that keyframe's colour")

func _test_between_keyframes_the_colour_is_blended() -> void:
	print("between keyframes")
	var m := _make()
	var before: Color = m.KEYFRAMES[2][1]
	var after: Color = m.KEYFRAMES[3][1]
	var midpoint: float = (m.KEYFRAMES[2][0] + m.KEYFRAMES[3][0]) * 0.5
	var blended := _sky(m, midpoint)
	expect(blended.is_equal_approx(before.lerp(after, 0.5)),
		"halfway between two keyframes is halfway between their colours")
	expect(not blended.is_equal_approx(before), "rather than holding the earlier one")

func _test_the_sky_is_darkest_at_midnight() -> void:
	print("night and day")
	var m := _make()
	expect(_sky(m, 0.5).get_luminance() > _sky(m, 0.0).get_luminance(),
		"noon is brighter than midnight")
	expect(_sky(m, 0.25).get_luminance() > _sky(m, 0.0).get_luminance(),
		"and dawn is brighter than the night before it")

func _test_the_clock_reads_the_time() -> void:
	print("the clock")
	var m := _make()
	expect(m._time_name(0.5).contains("12"), "half way through the day reads twelve")
	expect(m._time_name(0.5).contains("noon"), "and is called noon")
	expect(m._time_name(0.0).contains("midnight"), "the start of the cycle is midnight")
	expect(m._time_name(0.25).contains("AM"), "a quarter through is morning")
	expect(m._time_name(0.75).contains("PM"), "and three quarters is afternoon")

	# The hour itself, not just the suffix: a twelve-hour clock has to convert
	# rather than print whatever the twenty-four hour count was.
	expect(m._time_name(0.25).begins_with("06"), "a quarter through the day reads six o'clock")
	expect(m._time_name(0.75).begins_with("06"), "and three quarters reads six as well")
	expect(m._time_name(0.0).begins_with("12"), "midnight reads twelve, not zero")
	expect(m._time_name(13.0 / 24.0).begins_with("01"), "and one in the afternoon reads one")

func _test_the_canvas_is_tinted_from_the_cycle() -> void:
	print("the tint")
	var m := _make()
	var modulate: CanvasModulate = m.get_node("CanvasModulate")
	m._time = 0.5
	m._process(STEP)
	var noon: Color = modulate.color
	m._time = 0.0
	m._process(STEP)
	# Without the CanvasModulate following, the world would stay lit at
	# midnight and only the painted sky would change.
	expect(modulate.color.get_luminance() < noon.get_luminance(),
		"the whole scene is dimmed at night, not just the sky")
	expect((m.get_node("HUD/TimeLabel") as Label).text.length() > 0, "and the clock is on screen")

func _test_a_time_outside_the_day_falls_back() -> void:
	print("out of range")
	var m := _make()
	begin_quiet()
	# fmod keeps _time inside the day, but the lookup is called with whatever it
	# is given. A time no span covers has to fall back to a colour rather than
	# running off the end of the keyframe list.
	# Held as Variant on purpose: a lookup that runs off the end of the keyframe
	# list returns null, and a typed local would abort this function instead of
	# failing it.
	for t in [-0.5, 1.5, 12.0]:
		var sky: Variant = m._lerp_keyframes(t, 0)
		var light: Variant = m._lerp_keyframes(t, 1)
		expect_quiet(sky is Color and (sky as Color).is_equal_approx(m.KEYFRAMES[0][1]),
			"t=%.1f falls back to the first keyframe's sky" % t)
		expect_quiet(light is Color and (light as Color).is_equal_approx(m.KEYFRAMES[0][2]),
			"t=%.1f falls back to its light too" % t)
	expect(_quiet_failures == 0, "a time outside the day falls back to midnight")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
