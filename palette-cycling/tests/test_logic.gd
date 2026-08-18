extends Node

# Drives the real palette from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_index_map_covers_the_grid()
	_test_every_index_addresses_a_colour()
	_test_the_palette_is_a_ring()
	_test_each_pattern_looks_different()
	_test_the_pattern_keys_switch()
	_test_switching_pattern_rebuilds_both_halves()
	_test_the_offset_advances_and_wraps()
	_test_the_speed_keys_have_a_floor()
	_test_cycling_recolours_without_moving_anything()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[palette-cycling] %d/%d passed" % [_pass, _pass + _fail]
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

## The colour shown at a cell, at the current palette offset.
func _colour_at(m: Node2D, col: int, row: int) -> Color:
	var raw: int = m._index_map[row * m.COLS + col]
	return m._palette[int(raw + m._palette_offset) % 16]

func _test_the_index_map_covers_the_grid() -> void:
	print("the index map")
	var m := _make()
	expect(m._index_map.size() == m.COLS * m.ROWS, "there is an index per cell")

func _test_every_index_addresses_a_colour() -> void:
	print("indices and palette")
	var m := _make()
	begin_quiet()
	for pattern in 3:
		m._pattern = pattern
		m._build_index_map()
		m._build_palette()
		expect_quiet(m._palette.size() == 16, "pattern %d has a 16-colour palette" % pattern)
		for index in m._index_map:
			# An index past the end of the palette is an out-of-range read every
			# frame, for every cell that carries it.
			expect_quiet(index >= 0 and index < m._palette.size(),
				"pattern %d stores index %d, outside its palette" % [pattern, index])
	expect(_quiet_failures == 0, "every index in every pattern addresses a real colour")

func _test_the_palette_is_a_ring() -> void:
	print("the ramps")
	var m := _make()
	begin_quiet()
	for pattern in 3:
		m._pattern = pattern
		m._build_palette()
		# Cycling walks off the end of the palette and back to the start, so a
		# ramp whose ends do not meet flashes once per cycle.
		var first: Color = m._palette[0]
		var last: Color = m._palette[m._palette.size() - 1]
		var gap: float = absf(first.r - last.r) + absf(first.g - last.g) + absf(first.b - last.b)
		expect_quiet(gap < 0.5, "pattern %d jumps from its last colour back to its first" % pattern)
	expect(_quiet_failures == 0, "each palette joins up into a ring")

func _test_each_pattern_looks_different() -> void:
	print("the patterns")
	var maps := {}
	var palettes := {}
	for pattern in 3:
		var m := _make()
		m._pattern = pattern
		m._build_index_map()
		m._build_palette()
		maps[m._index_map] = true
		palettes[str(m._palette)] = true
	expect(maps.size() == 3, "the three patterns lay out different index maps")
	expect(palettes.size() == 3, "and use different palettes")

func _test_the_pattern_keys_switch() -> void:
	print("the keys")
	var m := _make()
	_press(m, KEY_L)
	expect(m._pattern == 1, "L selects lava")
	_press(m, KEY_R)
	expect(m._pattern == 2, "R selects the rainbow")
	_press(m, KEY_W)
	expect(m._pattern == 0, "and W goes back to water")

func _test_switching_pattern_rebuilds_both_halves() -> void:
	print("switching")
	var m := _make()
	var water_map: PackedByteArray = m._index_map.duplicate()
	var water_palette := str(m._palette)
	_press(m, KEY_L)
	# Rebuilding one and not the other shows lava colours through a water
	# pattern, which looks plausible enough to miss.
	expect(m._index_map != water_map, "the index map is rebuilt for the new pattern")
	expect(str(m._palette) != water_palette, "and so is the palette")

func _test_the_offset_advances_and_wraps() -> void:
	print("cycling")
	var m := _make()
	m._palette_offset = 0.0
	m._process(0.5)
	expect(m._palette_offset > 0.0, "the palette shifts along")
	m._palette_offset = 15.9
	m._process(1.0)
	expect(m._palette_offset < 16.0, "and wraps at the end of the palette")
	expect(m._palette_offset >= 0.0, "rather than running off it")

func _test_the_speed_keys_have_a_floor() -> void:
	print("speed")
	var m := _make()
	var start: float = m._cycle_speed
	_press(m, KEY_EQUAL)
	expect(m._cycle_speed > start, "+ cycles faster")
	_press(m, KEY_MINUS)
	expect(is_equal_approx(m._cycle_speed, start), "and - slower")
	for i in 40:
		_press(m, KEY_MINUS)
	expect(m._cycle_speed > 0.0, "the speed never reaches zero, which would stop the animation")

func _test_cycling_recolours_without_moving_anything() -> void:
	print("what cycling changes")
	var m := _make()
	var before: PackedByteArray = m._index_map.duplicate()
	var colour_before := _colour_at(m, 5, 5)
	for i in 60:
		m._process(STEP)
	# This is the whole trick: the picture never changes, only the colours
	# its indices point at.
	expect(m._index_map == before, "the picture itself is untouched")
	expect(_colour_at(m, 5, 5) != colour_before, "but the colour on screen has moved along")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
