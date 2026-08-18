extends Node

# Drives the real dissolve from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_noise_grid_covers_the_sprite()
	_test_the_noise_is_spread_across_the_range()
	_test_it_starts_whole_and_still()
	_test_d_dissolves()
	_test_a_dissolve_finishes_and_stops()
	_test_a_dissolve_hides_the_sprite_a_cell_at_a_time()
	_test_a_appears()
	_test_appearing_finishes_and_stops()
	_test_the_two_cancel_each_other()
	_test_r_resets()
	_test_a_still_sprite_does_not_drift()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[dissolve-effect] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _press(m: Node2D, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._input(e)

func _run(m: Node2D, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		m._process(STEP)
		elapsed += STEP

## How many cells are still drawn at the current threshold.
func _visible_cells(m: Node2D) -> int:
	var count := 0
	for value in m._noise_grid:
		if value >= m._threshold:
			count += 1
	return count

func _test_the_noise_grid_covers_the_sprite() -> void:
	print("the noise grid")
	var m := _make()
	expect(m._noise_grid.size() == m.COLS * m.ROWS, "there is a noise value per cell")

func _test_the_noise_is_spread_across_the_range() -> void:
	print("the noise")
	var m := _make()
	var lowest := 1.0
	var highest := 0.0
	for value in m._noise_grid:
		lowest = minf(lowest, value)
		highest = maxf(highest, value)
	# Values bunched together would make the sprite vanish all at once instead
	# of eroding.
	expect(lowest < 0.2, "some cells go early")
	expect(highest > 0.8, "and some hang on to the end")

func _test_it_starts_whole_and_still() -> void:
	print("before anything happens")
	var m := _make()
	expect(is_zero_approx(m._threshold), "the sprite starts whole")
	expect(not m._dissolving and not m._appearing, "and nothing is happening to it")
	expect(_visible_cells(m) == m._noise_grid.size(), "every cell is drawn")

func _test_d_dissolves() -> void:
	print("dissolving")
	var m := _make()
	_press(m, KEY_D)
	expect(m._dissolving, "D starts a dissolve")
	_run(m, 0.3)
	expect(m._threshold > 0.0, "and the threshold climbs")
	expect(_visible_cells(m) < m._noise_grid.size(), "taking cells off the sprite")

func _test_a_dissolve_finishes_and_stops() -> void:
	print("finishing")
	var m := _make()
	_press(m, KEY_D)
	_run(m, 5.0)
	expect(is_equal_approx(m._threshold, 1.0), "the dissolve stops at fully gone")
	expect(not m._dissolving, "and switches itself off")
	expect(_visible_cells(m) == 0, "with nothing left drawn")

func _test_a_dissolve_hides_the_sprite_a_cell_at_a_time() -> void:
	print("eroding")
	var m := _make()
	_press(m, KEY_D)
	var counts: Array[int] = []
	for i in 8:
		_run(m, 0.15)
		counts.append(_visible_cells(m))
	# Cells go a few at a time rather than all together, which is what makes it
	# read as a dissolve.
	var partial := 0
	for count in counts:
		if count > 0 and count < m._noise_grid.size():
			partial += 1
	expect(partial >= 4, "the sprite spends several frames part-way gone")
	begin_quiet()
	for i in counts.size() - 1:
		expect_quiet(counts[i + 1] <= counts[i], "the sprite grew back mid-dissolve")
	expect(_quiet_failures == 0, "and never grows back while dissolving")

func _test_a_appears() -> void:
	print("appearing")
	var m := _make()
	_press(m, KEY_D)
	_run(m, 5.0)
	expect(is_equal_approx(m._threshold, 1.0), "gone")
	_press(m, KEY_A)
	expect(m._appearing, "A starts it coming back")
	_run(m, 0.3)
	expect(m._threshold < 1.0, "and the threshold falls")
	expect(_visible_cells(m) > 0, "putting cells back on the sprite")

func _test_appearing_finishes_and_stops() -> void:
	print("fully back")
	var m := _make()
	m._threshold = 1.0
	_press(m, KEY_A)
	_run(m, 5.0)
	expect(is_zero_approx(m._threshold), "it stops at fully present")
	expect(not m._appearing, "and switches itself off")
	expect(_visible_cells(m) == m._noise_grid.size(), "with the whole sprite back")

func _test_the_two_cancel_each_other() -> void:
	print("changing direction")
	var m := _make()
	_press(m, KEY_D)
	expect(m._dissolving and not m._appearing, "dissolving")
	_press(m, KEY_A)
	# Running both at once would leave the threshold hovering while the two
	# cancel out.
	expect(m._appearing and not m._dissolving, "A takes over from D rather than fighting it")
	_press(m, KEY_D)
	expect(m._dissolving and not m._appearing, "and D takes back over")

func _test_r_resets() -> void:
	print("reset")
	var m := _make()
	_press(m, KEY_D)
	_run(m, 0.8)
	_press(m, KEY_R)
	expect(is_zero_approx(m._threshold), "R puts the sprite back whole")
	expect(not m._dissolving and not m._appearing, "and stops whatever was running")

func _test_a_still_sprite_does_not_drift() -> void:
	print("at rest")
	var m := _make()
	m._threshold = 0.4
	_run(m, 1.0)
	expect(is_equal_approx(m._threshold, 0.4),
		"a sprite left part-way through stays where it is until asked to move")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
