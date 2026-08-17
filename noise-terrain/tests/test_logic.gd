extends Node

# Drives the real generator from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_terrain_spans_the_screen()
	_test_every_column_is_between_the_top_and_the_bottom()
	_test_the_terrain_is_not_flat()
	_test_neighbouring_columns_are_close_together()
	_test_a_new_seed_gives_new_terrain()
	_test_the_settings_reach_the_noise()
	_test_frequency_has_limits()
	_test_octaves_have_limits()
	_test_every_control_rebuilds_the_terrain()
	_test_nothing_held_regenerates_nothing()
	_test_a_higher_frequency_makes_rougher_ground()
	_test_the_labels_report_the_settings()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[noise-terrain] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

## How much the ground moves from one column to the next, on average.
func _roughness(m: Node2D) -> float:
	var total := 0.0
	for i in m._heights.size() - 1:
		total += absf(m._heights[i + 1] - m._heights[i])
	return total / float(m._heights.size() - 1)

func _test_the_terrain_spans_the_screen() -> void:
	print("the terrain")
	var m := _make()
	expect(m._heights.size() == m.COLS, "there is a height per column")

func _test_every_column_is_between_the_top_and_the_bottom() -> void:
	print("bounds")
	var m := _make()
	var inside := true
	for h in m._heights:
		if h < m.TERRAIN_TOP - 0.001 or h > m.TERRAIN_BOTTOM + 0.001:
			inside = false
	expect(inside, "no column reaches above the sky or below the ground")

func _test_the_terrain_is_not_flat() -> void:
	print("relief")
	var m := _make()
	var lowest: float = m._heights[0]
	var highest: float = m._heights[0]
	for h in m._heights:
		lowest = maxf(lowest, h)
		highest = minf(highest, h)
	expect(lowest - highest > 20.0, "the ground actually rises and falls")

func _test_neighbouring_columns_are_close_together() -> void:
	print("continuity")
	var m := _make()
	# Noise, not randomness: adjacent columns have to be related, or the result
	# is static rather than terrain.
	var biggest := 0.0
	for i in m._heights.size() - 1:
		biggest = maxf(biggest, absf(m._heights[i + 1] - m._heights[i]))
	expect(biggest < (m.TERRAIN_BOTTOM - m.TERRAIN_TOP) * 0.5,
		"no column jumps halfway down the screen from its neighbour")

func _test_a_new_seed_gives_new_terrain() -> void:
	print("reseeding")
	var m := _make()
	var before: Array = m._heights.duplicate()
	m._noise.seed = 12345
	m._update_noise()
	expect(m._heights != before, "a different seed gives different ground")
	expect(m._heights.size() == before.size(), "of the same width")

func _test_the_settings_reach_the_noise() -> void:
	print("the settings")
	var m := _make()
	m._freq = 0.05
	m._octaves = 6
	m._update_noise()
	expect(is_equal_approx(m._noise.frequency, 0.05), "the frequency setting reaches the noise")
	expect(m._noise.fractal_octaves == 6, "and so does the octave count")

func _test_frequency_has_limits() -> void:
	print("frequency limits")
	var m := _make()
	var start: float = m._freq
	m.apply_controls(true, false, false, false)
	expect(m._freq > start, "F raises the frequency")
	m.apply_controls(false, true, false, false)
	expect(is_equal_approx(m._freq, start), "and G lowers it again")

	for i in 400:
		m.apply_controls(true, false, false, false)
	expect(m._freq <= 0.2, "the frequency has a ceiling")
	for i in 400:
		m.apply_controls(false, true, false, false)
	expect(m._freq >= 0.001, "and a floor above zero — a zero frequency is a flat line")
	expect(m._heights.size() == m.COLS, "the terrain still generates at the extremes")

func _test_octaves_have_limits() -> void:
	print("octave limits")
	var m := _make()
	var start: int = m._octaves
	m.apply_controls(false, false, true, false)
	expect(m._octaves == start + 1, "O adds an octave")
	m.apply_controls(false, false, false, true)
	expect(m._octaves == start, "and P takes one away")

	for i in 20:
		m.apply_controls(false, false, true, false)
	expect(m._octaves == 8, "octaves stop at eight")
	for i in 20:
		m.apply_controls(false, false, false, true)
	expect(m._octaves == 1, "and at one — zero octaves is no noise at all")
	expect(m._noise.fractal_octaves >= 1, "the noise never runs with none")

func _test_every_control_rebuilds_the_terrain() -> void:
	print("regenerating")
	# Changing a setting without rebuilding would leave the old terrain on
	# screen, so the controls would look like they did nothing.
	var controls := {
		"F raises the frequency": [true, false, false, false],
		"G lowers it": [false, true, false, false],
		"O adds an octave": [false, false, true, false],
		"P removes one": [false, false, false, true],
	}
	for label in controls:
		var m := _make()
		var keys: Array = controls[label]
		m._heights.clear()
		m.apply_controls(keys[0], keys[1], keys[2], keys[3])
		expect(m._heights.size() == m.COLS, "%s, and the terrain is rebuilt" % label)

func _test_nothing_held_regenerates_nothing() -> void:
	print("idle frames")
	var m := _make()
	m._heights.clear()
	m.apply_controls(false, false, false, false)
	expect(m._heights.is_empty(), "a frame with no keys held does not rebuild the terrain")

func _test_a_higher_frequency_makes_rougher_ground() -> void:
	print("frequency")
	var smooth := _make()
	smooth._freq = 0.005
	smooth._update_noise()

	var rough := _make()
	rough._freq = 0.15
	rough._update_noise()

	expect(_roughness(rough) > _roughness(smooth),
		"a higher frequency makes the ground change faster (%.1f vs %.1f)" %
		[_roughness(rough), _roughness(smooth)])

func _test_the_labels_report_the_settings() -> void:
	print("the readout")
	var m := _make()
	m._freq = 0.05
	m._octaves = 6
	m._update_noise()
	expect((m.get_node("HUD/FreqLabel") as Label).text.contains("0.05"), "the frequency is on screen")
	expect((m.get_node("HUD/OctLabel") as Label).text.contains("6"), "and so is the octave count")
