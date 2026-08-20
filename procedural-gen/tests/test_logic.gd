extends Node

# Drives the real generator from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_map_covers_the_grid()
	_test_the_map_is_indexed_row_by_row()
	_test_regenerating_gives_a_different_world()
	_test_r_regenerates_too()
	_test_the_buttons_switch_modes()
	_test_terrain_reads_height_as_bands()
	_test_caves_are_a_two_tone_split()
	_test_islands_have_water_at_the_edges()
	_test_the_island_bands_run_sea_sand_grass_rock()
	_test_moisture_runs_from_dry_to_wet()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[procedural-gen] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _test_the_map_covers_the_grid() -> void:
	print("the map")
	var m := _make()
	expect(m._map.size() == m.MAP_W * m.MAP_H, "there is a noise sample per cell")
	var in_range := true
	for n in m._map:
		if n < -1.0 or n > 1.0:
			in_range = false
	expect(in_range, "and every one of them is in the -1..1 noise range")

func _test_the_map_is_indexed_row_by_row() -> void:
	print("indexing")
	var m := _make()
	# _noise_at flattens (x, y); getting the stride wrong shows up as a map that
	# looks plausible but is sheared.
	expect(is_equal_approx(m._noise_at(0, 0), m._map[0]), "the first cell is the first sample")
	expect(is_equal_approx(m._noise_at(1, 0), m._map[1]), "x runs along the row")
	expect(is_equal_approx(m._noise_at(0, 1), m._map[m.MAP_W]), "and y steps a whole row at a time")
	expect(is_equal_approx(m._noise_at(m.MAP_W - 1, m.MAP_H - 1), m._map[m.MAP_W * m.MAP_H - 1]),
		"with the last cell at the end of the map")

func _test_regenerating_gives_a_different_world() -> void:
	print("regenerating")
	var m := _make()
	var before: Array[float] = m._map.duplicate()
	var seed_before: int = m._seed
	m._regenerate()
	expect(m._seed != seed_before, "a new seed is drawn")
	expect(m._map != before, "and the map changes with it")
	expect(m._map.size() == before.size(), "while staying the same size")

func _test_r_regenerates_too() -> void:
	print("the R key")
	var m := _make()
	var before: Array[float] = m._map.duplicate()
	var e := InputEventKey.new()
	e.keycode = KEY_R
	e.pressed = true
	m._unhandled_input(e)
	expect(m._map != before, "R rolls a new world")

	var ignored := _make()
	var untouched: Array[float] = ignored._map.duplicate()
	var other := InputEventKey.new()
	other.keycode = KEY_Q
	other.pressed = true
	ignored._unhandled_input(other)
	expect(ignored._map == untouched, "and other keys leave it alone")

func _test_the_buttons_switch_modes() -> void:
	print("modes")
	var m := _make()
	expect(m._mode == m.Mode.TERRAIN, "it opens on the terrain view")
	m._set_mode(m.Mode.CAVES)
	expect(m._mode == m.Mode.CAVES, "and switches when asked")
	expect(m.mode_label.text.contains("Caves"), "with the label naming the view")

	# The same noise, read four different ways — that is the demo's point.
	var samples: Array[float] = m._map.duplicate()
	m._set_mode(m.Mode.ISLAND)
	expect(m._map == samples, "switching view does not regenerate the noise")

func _test_terrain_reads_height_as_bands() -> void:
	print("terrain")
	var m := _make()
	m._set_mode(m.Mode.TERRAIN)
	var deep: Color = m._sample_color(10, 10, -0.9)
	var shallow: Color = m._sample_color(10, 10, -0.2)
	var grass: Color = m._sample_color(10, 10, 0.1)
	var snow: Color = m._sample_color(10, 10, 0.9)
	expect(deep != shallow, "deep and shallow water are different bands")
	expect(deep.b > deep.r, "the lowest ground is water-blue")
	expect(grass.g > grass.r and grass.g > grass.b, "midway up it is green")
	expect(snow.r > 0.8 and snow.g > 0.8 and snow.b > 0.8, "and the peaks are white")

func _test_caves_are_a_two_tone_split() -> void:
	print("caves")
	var m := _make()
	m._set_mode(m.Mode.CAVES)
	var rock: Color = m._sample_color(10, 10, 0.5)
	var open: Color = m._sample_color(10, 10, -0.5)
	expect(rock != open, "the cave view splits the noise in two")
	expect(rock == Color.BLACK, "solid rock is the dark half")

func _test_islands_have_water_at_the_edges() -> void:
	print("islands")
	var m := _make()
	m._set_mode(m.Mode.ISLAND)
	# The island view subtracts distance from the centre, so the same noise
	# value reads as land in the middle and as sea at the corner.
	var middle: Color = m._sample_color(m.MAP_W / 2, m.MAP_H / 2, 0.2)
	var corner: Color = m._sample_color(0, 0, 0.2)
	expect(middle != corner, "the falloff makes position matter, not just height")
	expect(corner.b > corner.r, "the corners of the map are sea")

## The island view has the same bands as terrain, in the same order.
##
## The test above compares the middle of the map with a corner, which only
## proves position matters. The bands themselves — sea, then sand, then grass,
## then rock as the ground rises — are four thresholds in a row, and any one of
## them flipping leaves a map that still has four colours in it.
func _test_the_island_bands_run_sea_sand_grass_rock() -> void:
	print("the island's bands")
	var m := _make()
	m._set_mode(m.Mode.ISLAND)

	# Sampled at the exact centre, where the falloff is zero, so `v` is the
	# noise value and the thresholds can be hit directly.
	var mid_x: int = m.MAP_W / 2
	var mid_y: int = m.MAP_H / 2
	var sea: Color = m._sample_color(mid_x, mid_y, -0.5)
	var sand: Color = m._sample_color(mid_x, mid_y, -0.15)
	var grass: Color = m._sample_color(mid_x, mid_y, 0.15)
	var rock: Color = m._sample_color(mid_x, mid_y, 0.5)

	expect(sea.b > sea.r and sea.b > sea.g, "the lowest band is blue — sea (%s)" % sea)
	expect(sand.r > sand.b and sand.g > sand.b,
		"then a pale band above it — sand (%s)" % sand)
	expect(grass.g > grass.r and grass.g > grass.b,
		"then green — grass (%s)" % grass)
	expect(rock.r > rock.b and rock.g > rock.b and rock.r < sand.r,
		"then a darker brown — rock (%s)" % rock)

	# Four distinct bands, in order, and each one actually different.
	var bands := [sea, sand, grass, rock]
	var quiet := 0
	for i in bands.size():
		for j in range(i + 1, bands.size()):
			if bands[i] == bands[j]:
				quiet += 1
	expect(quiet == 0, "no two bands share a colour")

	# Rising ground never goes back to sea: the thresholds are ordered.
	expect(m._sample_color(mid_x, mid_y, 0.9).b < sea.b,
		"the highest ground is nothing like the sea")

## The moisture view runs from dry to wet across the whole noise range.
func _test_moisture_runs_from_dry_to_wet() -> void:
	print("moisture")
	var m := _make()
	m._set_mode(m.Mode.MOISTURE)

	# Noise runs -1..1 and the view remaps it to 0..1. Get that remap wrong and
	# half the range lands outside 0..1, where the colour clamps flat.
	var dry: Color = m._sample_color(0, 0, -1.0)
	var wet: Color = m._sample_color(0, 0, 1.0)
	var mid: Color = m._sample_color(0, 0, 0.0)

	expect(dry != wet, "the two ends of the range are different colours")
	expect(wet.g > dry.g, "wetter ground is greener (%.2f vs %.2f)" % [wet.g, dry.g])
	expect(wet.b < dry.b, "and less blue (%.2f vs %.2f)" % [wet.b, dry.b])
	expect(dry.b > 0.5, "the dry end is the deep blue the ramp starts on (%.2f)" % dry.b)

	# The middle of the range sits between the ends rather than at one of them,
	# which is what a mis-remapped input collapses.
	expect(mid.g > dry.g and mid.g < wet.g,
		"the middle of the range is between them (%.2f in %.2f..%.2f)"
		% [mid.g, dry.g, wet.g])
	expect(mid.b < dry.b and mid.b > wet.b, "on both channels that move")

	# All three channels move with the ramp, in the direction the ramp says.
	# Red rises with moisture too — subtract it instead and the driest ground
	# has the *most* red in it, which reads as arid rather than deep water.
	expect(wet.r > dry.r,
		"the red channel rises with moisture as well (%.3f vs %.3f)" % [wet.r, dry.r])
	expect(dry.r >= 0.0,
		"and the dry end does not run off the bottom of it (%.3f)" % dry.r)

	# Every channel stays in range, or the ramp is clipping and the far end of
	# the map is a flat block of colour.
	for n in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		var c: Color = m._sample_color(0, 0, n)
		expect_quiet(c.r >= 0.0 and c.r <= 1.0 and c.g >= 0.0 and c.g <= 1.0
			and c.b >= 0.0 and c.b <= 1.0, "n=%.1f gives %s" % [n, c])
	expect(_quiet_failures == 0, "no sample clips outside a drawable colour")

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("    (", label, " — failed)")
