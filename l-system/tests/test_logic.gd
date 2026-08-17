extends Node

# Drives the real rewriter and turtle from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_a_rule_rewrites_every_matching_symbol()
	_test_symbols_with_no_rule_survive_unchanged()
	_test_each_iteration_applies_the_rules_again()
	_test_zero_iterations_is_the_axiom()
	_test_the_turtle_draws_a_segment_per_f()
	_test_lowercase_f_moves_without_drawing()
	_test_turning_bends_the_path()
	_test_the_two_turns_are_opposites()
	_test_brackets_save_and_restore_the_turtle()
	_test_an_unmatched_bracket_does_not_crash()
	_test_every_preset_draws_something()
	_test_space_moves_to_the_next_preset()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[l-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

## Draw a string from the origin, facing right, with unit segments.
func _walk(m: Node2D, s: String, turn: float = 90.0) -> PackedVector2Array:
	return m._turtle(s, Vector2.ZERO, 0.0, turn, 10.0)

func _test_a_rule_rewrites_every_matching_symbol() -> void:
	print("rewriting")
	var m := _make()
	expect(m._expand("F", {"F": "FF"}, 1) == "FF", "one symbol becomes its replacement")
	expect(m._expand("FF", {"F": "AB"}, 1) == "ABAB", "and every occurrence is rewritten")

func _test_symbols_with_no_rule_survive_unchanged() -> void:
	print("constants")
	var m := _make()
	# The turning and bracket symbols have no rules; they have to pass through
	# untouched or the shape falls apart on the second iteration.
	expect(m._expand("F+F-[]", {"F": "FF"}, 1) == "FF+FF-[]",
		"symbols without a rule are carried through as they are")

func _test_each_iteration_applies_the_rules_again() -> void:
	print("iterating")
	var m := _make()
	expect(m._expand("F", {"F": "FF"}, 2) == "FFFF", "two iterations of doubling gives four")
	expect(m._expand("F", {"F": "FF"}, 3).length() == 8, "and three gives eight")
	expect(m._expand("A", {"A": "AB", "B": "A"}, 4) == "ABAABABA",
		"two rules applied together grow the string as the grammar says")

func _test_zero_iterations_is_the_axiom() -> void:
	print("no iterations")
	var m := _make()
	expect(m._expand("X", {"X": "FF"}, 0) == "X", "nought iterations leaves the axiom alone")

func _test_the_turtle_draws_a_segment_per_f() -> void:
	print("drawing")
	var m := _make()
	var pts := _walk(m, "F")
	expect(pts.size() == 2, "one F is one line — a start and an end")
	expect(pts[0] == Vector2.ZERO, "starting where the turtle stands")
	expect(is_equal_approx(pts[0].distance_to(pts[1]), 10.0), "a segment long")

	expect(_walk(m, "FFF").size() == 6, "three Fs are three lines")
	var trail := _walk(m, "FF")
	expect(trail[1] == trail[2], "and consecutive segments join end to end")

func _test_lowercase_f_moves_without_drawing() -> void:
	print("moving without drawing")
	var m := _make()
	expect(_walk(m, "f").is_empty(), "a lowercase f draws nothing")
	var gap := _walk(m, "fF")
	expect(gap.size() == 2, "but it still moves the turtle")
	expect(gap[0].x > 0.0, "so the next segment starts further along")

func _test_turning_bends_the_path() -> void:
	print("turning")
	var m := _make()
	var straight := _walk(m, "FF")
	var bent := _walk(m, "F+F", 90.0)
	expect(straight[3].y == 0.0, "without a turn the turtle keeps going straight")
	expect(not is_equal_approx(bent[3].y, 0.0), "a turn between segments bends the path")
	expect(is_equal_approx(bent[2].x, bent[3].x), "by ninety degrees, when that is the angle")

func _test_the_two_turns_are_opposites() -> void:
	print("left and right")
	var m := _make()
	var one_way := _walk(m, "F+F", 45.0)
	var other := _walk(m, "F-F", 45.0)
	expect(one_way[3].y < 0.0 or other[3].y < 0.0, "one of the turns goes up the screen")
	expect(is_equal_approx(one_way[3].y, -other[3].y), "and the two mirror each other exactly")

	var there_and_back := _walk(m, "F+-F", 45.0)
	var straight := _walk(m, "FF")
	expect(there_and_back[3].is_equal_approx(straight[3]), "turning both ways cancels out")

func _test_brackets_save_and_restore_the_turtle() -> void:
	print("branches")
	var m := _make()
	# This is what makes a tree a tree: the branch returns the turtle to where
	# it forked, so the trunk carries on from there.
	var branched := _walk(m, "F[+F]F", 90.0)
	expect(branched.size() == 6, "three segments: trunk, branch, trunk again")
	expect(branched[4] == branched[1], "the trunk resumes from the fork")
	expect(branched[5].is_equal_approx(_walk(m, "FF")[3]),
		"and continues in the direction it was going before the branch")

	var nested := _walk(m, "F[+F[+F]]F", 60.0)
	expect(nested[nested.size() - 2] == nested[1], "nested branches unwind back to the fork too")

func _test_an_unmatched_bracket_does_not_crash() -> void:
	print("malformed strings")
	var m := _make()
	var pts := _walk(m, "F]]]F")
	expect(pts.size() == 4, "a closing bracket with nothing to restore is ignored")

func _test_every_preset_draws_something() -> void:
	print("the presets")
	var m := _make()
	for i in m.PRESETS.size():
		var p: Dictionary = m.PRESETS[i]
		var s: String = m._expand(p["axiom"], p["rules"], p["iters"])
		var pts: PackedVector2Array = m._turtle(s, p["start"], p["start_angle"], p["angle"], p["length"])
		expect(pts.size() > 100, "%s expands into a real figure (%d points)" % [p["name"], pts.size()])
		expect(s.length() > p["axiom"].length(), "grown from a shorter axiom")

func _test_space_moves_to_the_next_preset() -> void:
	print("switching")
	var m := _make()
	var first: String = m._name_str
	var first_lines: PackedVector2Array = m._lines.duplicate()
	expect(m._lines.size() > 0, "the first preset is drawn on open")

	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.pressed = true
	m._input(e)
	expect(m._name_str != first, "space moves to the next preset")
	expect(m._lines != first_lines, "and redraws the figure")

	for i in m.PRESETS.size() - 1:
		m._input(e)
	expect(m._name_str == first, "and the list comes back round to the first")
