extends Node

# Drives the real contouring from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_field_covers_the_grid()
	_test_the_field_is_smooth()
	_test_space_makes_a_new_field()
	_test_an_empty_cell_and_a_full_cell_have_no_contour()
	_test_each_corner_sets_its_own_bit()
	_test_opposite_corners_are_the_ambiguous_cases()
	_test_the_case_is_the_sum_of_its_corners()
	_test_inverting_the_field_inverts_the_case()
	_test_the_crossing_is_interpolated()
	_test_the_crossing_stays_on_the_edge()
	_test_two_equal_corners_cross_in_the_middle()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[marching-squares] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _in(m: Node2D) -> float:
	return m.THRESHOLD + 0.2

func _out(m: Node2D) -> float:
	return m.THRESHOLD - 0.2

func _test_the_field_covers_the_grid() -> void:
	print("the field")
	var m := _make()
	expect(m._field.size() == m.GRID_H, "a row per grid row")
	expect(m._field[0].size() == m.GRID_W, "and a value per column")
	var in_range := true
	for row in m._field:
		for v in row:
			if v < 0.0 or v > 1.0:
				in_range = false
	expect(in_range, "with every value in nought to one, where the threshold sits")

func _test_the_field_is_smooth() -> void:
	print("smoothness")
	var m := _make()
	# Noise, not random numbers: a field of static would produce contours that
	# are speckle rather than curves.
	var biggest := 0.0
	for y in m.GRID_H:
		for x in m.GRID_W - 1:
			biggest = maxf(biggest, absf(m._field[y][x + 1] - m._field[y][x]))
	expect(biggest < 0.5, "no cell jumps half the range from its neighbour")

func _test_space_makes_a_new_field() -> void:
	print("regenerating")
	var m := _make()
	var before: Array = m._field.duplicate(true)
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.pressed = true
	m._input(e)
	expect(m._field != before, "space reseeds the field")
	expect(m._field.size() == before.size(), "keeping the same grid")

func _test_an_empty_cell_and_a_full_cell_have_no_contour() -> void:
	print("the trivial cells")
	var m := _make()
	expect(m.contour_index(_out(m), _out(m), _out(m), _out(m)) == 0,
		"a cell wholly outside the surface is case 0")
	expect(m.contour_index(_in(m), _in(m), _in(m), _in(m)) == 15,
		"and one wholly inside is case 15")

func _test_each_corner_sets_its_own_bit() -> void:
	print("the corner bits")
	var m := _make()
	var lo: float = _out(m)
	var hi: float = _in(m)
	expect(m.contour_index(hi, lo, lo, lo) == 1, "the top-left corner is bit 1")
	expect(m.contour_index(lo, hi, lo, lo) == 2, "the top-right bit 2")
	expect(m.contour_index(lo, lo, hi, lo) == 4, "the bottom-right bit 4")
	expect(m.contour_index(lo, lo, lo, hi) == 8, "and the bottom-left bit 8")

func _test_opposite_corners_are_the_ambiguous_cases() -> void:
	print("the saddle cases")
	var m := _make()
	var lo: float = _out(m)
	var hi: float = _in(m)
	# 5 and 10 are the two cells that need two line segments rather than one;
	# getting their numbering wrong draws the contour through the wrong pair.
	expect(m.contour_index(hi, lo, hi, lo) == 5, "top-left and bottom-right together are case 5")
	expect(m.contour_index(lo, hi, lo, hi) == 10, "top-right and bottom-left are case 10")

func _test_the_case_is_the_sum_of_its_corners() -> void:
	print("combinations")
	var m := _make()
	var lo: float = _out(m)
	var hi: float = _in(m)
	expect(m.contour_index(hi, hi, lo, lo) == 3, "the top edge inside is case 3")
	expect(m.contour_index(lo, lo, hi, hi) == 12, "the bottom edge is case 12")
	expect(m.contour_index(hi, lo, lo, hi) == 9, "the left edge is case 9")
	expect(m.contour_index(lo, hi, hi, lo) == 6, "and the right edge case 6")

func _test_inverting_the_field_inverts_the_case() -> void:
	print("symmetry")
	var m := _make()
	var lo: float = _out(m)
	var hi: float = _in(m)
	# Swapping inside for outside gives the complementary case, which is why the
	# drawing table pairs 1 with 14, 2 with 13 and so on.
	for pair in [[hi, lo, lo, lo], [hi, hi, lo, lo], [hi, lo, hi, lo]]:
		var normal: int = m.contour_index(pair[0], pair[1], pair[2], pair[3])
		var flipped: int = m.contour_index(
			hi if pair[0] == lo else lo, hi if pair[1] == lo else lo,
			hi if pair[2] == lo else lo, hi if pair[3] == lo else lo)
		expect(normal + flipped == 15, "case %d and its inverse make fifteen" % normal)

func _test_the_crossing_is_interpolated() -> void:
	print("interpolation")
	var m := _make()
	# The threshold sits exactly between the two corner values, so the crossing
	# is exactly halfway along the edge.
	expect(is_equal_approx(m._t(m.THRESHOLD - 0.25, m.THRESHOLD + 0.25), 0.5),
		"an evenly straddled edge crosses in the middle")
	# Nearer the far corner: the crossing slides towards it.
	var near_far: float = m._t(0.0, 1.0)
	expect(is_equal_approx(near_far, m.THRESHOLD), "the crossing follows the values, not the geometry")
	expect(m._t(m.THRESHOLD - 0.4, m.THRESHOLD + 0.1) > 0.5,
		"a corner that is only just inside pulls the crossing towards itself")

func _test_the_crossing_stays_on_the_edge() -> void:
	print("clamping")
	var m := _make()
	# Both corners on the same side of the threshold: the crossing is not on
	# this edge at all, and an unclamped answer would put the line outside the cell.
	expect(m._t(0.9, 0.95) >= 0.0 and m._t(0.9, 0.95) <= 1.0, "a crossing above the edge is clamped")
	expect(m._t(0.1, 0.2) >= 0.0 and m._t(0.1, 0.2) <= 1.0, "and one below it too")

func _test_two_equal_corners_cross_in_the_middle() -> void:
	print("flat edges")
	var m := _make()
	# Dividing by the difference would be a division by zero.
	expect(is_equal_approx(m._t(0.5, 0.5), 0.5), "an edge with no gradient falls back to the midpoint")
	expect(not is_nan(m._t(0.0, 0.0)), "rather than a NaN")
