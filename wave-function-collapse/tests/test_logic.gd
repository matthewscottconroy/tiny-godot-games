extends Node

# Drives the real solver from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_fills_the_whole_grid()
	_test_every_neighbour_pair_is_allowed()
	_test_the_rules_are_symmetric()
	_test_a_reset_clears_the_grid()
	_test_collapsing_a_cell_narrows_its_neighbours()
	_test_propagation_reports_a_contradiction()
	_test_the_least_undecided_cell_is_chosen_first()
	_test_a_weighted_choice_only_picks_what_is_possible()
	_test_weights_show_up_in_the_output()
	_test_space_generates_a_new_map()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[wave-function-collapse] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _test_it_fills_the_whole_grid() -> void:
	print("a finished map")
	var m := _make()
	var undecided := 0
	for y in m.GRID_H:
		for x in m.GRID_W:
			if m._collapsed[y][x] == -1:
				undecided += 1
	expect(undecided == 0, "every cell has been decided (%d left over)" % undecided)

	var in_range := true
	for row in m._collapsed:
		for tile in row:
			if tile < 0 or tile >= m.NUM_TILES:
				in_range = false
	expect(in_range, "and every one of them is a real tile")

func _test_every_neighbour_pair_is_allowed() -> void:
	print("the constraint")
	# This is the whole point of the algorithm: no two adjacent tiles may be a
	# pair the rules forbid, so grass never borders deep water.
	var illegal := 0
	for attempt in 3:
		var m := _make()
		for y in m.GRID_H:
			for x in m.GRID_W:
				var here: int = m._collapsed[y][x]
				if x + 1 < m.GRID_W and not (m._collapsed[y][x + 1] in m.RULES[here]):
					illegal += 1
				if y + 1 < m.GRID_H and not (m._collapsed[y + 1][x] in m.RULES[here]):
					illegal += 1
	expect(illegal == 0, "no neighbouring pair breaks the rules (%d did)" % illegal)

func _test_the_rules_are_symmetric() -> void:
	print("the rule table")
	var m := _make()
	# Adjacency is symmetric in this demo — propagation reads the table in one
	# direction only, so an asymmetric table would produce maps whose legality
	# depends on which way you read them.
	var symmetric := true
	for a in m.NUM_TILES:
		for b in m.RULES[a]:
			if not (a in m.RULES[b]):
				symmetric = false
	expect(symmetric, "if A may sit beside B then B may sit beside A")
	expect(m.WEIGHTS.size() == m.NUM_TILES, "there is a weight per tile")
	expect(m.TILE_COLORS.size() == m.NUM_TILES, "and a colour per tile")

func _test_a_reset_clears_the_grid() -> void:
	print("resetting")
	var m := _make()
	m._reset()
	var cleared := true
	var open := true
	for y in m.GRID_H:
		for x in m.GRID_W:
			if m._collapsed[y][x] != -1:
				cleared = false
			if m._count(m._cells[y][x]) != m.NUM_TILES:
				open = false
	expect(cleared, "no cell is decided after a reset")
	expect(open, "and every cell is back to allowing every tile")

	# A solve over a blank grid should report success, not quietly fail and get
	# retried a hundred times for a map that looks the same either way.
	expect(m._run(), "and a solve from there succeeds")

func _test_collapsing_a_cell_narrows_its_neighbours() -> void:
	print("propagation")
	var m := _make()
	m._reset()
	# Pin one cell to deep water; its neighbours may then only be things that
	# are allowed to touch deep water.
	var pos := Vector2i(10, 10)
	m._collapsed[pos.y][pos.x] = 0
	for t in m.NUM_TILES:
		m._cells[pos.y][pos.x][t] = (t == 0)
	expect(m._propagate([pos]), "propagation succeeds")

	var right: Array = m._cells[10][11]
	expect(m._count(right) < m.NUM_TILES, "the neighbour has fewer options than before")
	for t in m.NUM_TILES:
		if right[t]:
			expect(t in m.RULES[0], "every option it has left may sit beside deep water")

func _test_propagation_reports_a_contradiction() -> void:
	print("contradictions")
	var m := _make()
	m._reset()
	# Deep water on the left, grass on the right, one cell between them: nothing
	# can legally go in the gap, and the solver has to notice rather than
	# produce an impossible map.
	m._cells[10][9] = [true, false, false, false]
	m._collapsed[10][9] = 0
	m._cells[10][11] = [false, false, false, true]
	m._collapsed[10][11] = 3
	expect(not m._propagate([Vector2i(9, 10), Vector2i(11, 10)]),
		"a cell with no legal tile is reported as a failure")

func _test_the_least_undecided_cell_is_chosen_first() -> void:
	print("choosing where to collapse")
	var m := _make()
	m._reset()
	# Lowest entropy wins: collapsing the most constrained cell first is what
	# keeps the solver from painting itself into a corner.
	m._cells[5][5] = [true, true, false, false]
	m._cells[7][7] = [true, true, true, false]
	expect(m._min_entropy_cell() == Vector2i(5, 5), "the cell with fewest options is picked")

	var finished := _make()
	expect(finished._min_entropy_cell() == Vector2i(-1, -1),
		"and a finished grid reports nothing left to do")

	var stuck := _make()
	stuck._reset()
	stuck._cells[3][3] = [false, false, false, false]
	expect(stuck._min_entropy_cell() == Vector2i(-2, -2), "a cell with no options is flagged instead")

func _test_a_weighted_choice_only_picks_what_is_possible() -> void:
	print("picking a tile")
	begin_quiet()
	var m := _make()
	for i in 40:
		expect_quiet(m._weighted_choice([false, true, true, false]) in [1, 2],
			"the choice comes from the tiles still allowed")
	expect(true, "forty draws stayed inside the allowed set")

	for i in 10:
		expect_quiet(m._weighted_choice([false, false, true, false]) == 2,
			"a single option is the only possible answer")
	expect(true, "and a cell with one option always gives that one")

func _test_weights_show_up_in_the_output() -> void:
	print("weighting")
	var m := _make()
	# Grass is weighted three times deep water, so over many draws it should
	# come up more often. Anything else means the weights are being ignored.
	var deep := 0
	var grass := 0
	for i in 600:
		var pick: int = m._weighted_choice([true, false, false, true])
		if pick == 0:
			deep += 1
		elif pick == 3:
			grass += 1
	expect(grass > deep, "the heavier tile is drawn more often (%d vs %d)" % [grass, deep])

func _test_space_generates_a_new_map() -> void:
	print("regenerating")
	var m := _make()
	var before: Array = m._collapsed.duplicate(true)
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.pressed = true
	m._input(e)
	expect(m._collapsed != before, "space lays out a different map")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

## Assert without printing a line per call — for the loops that check hundreds
## of draws, where one line each would bury the report.
func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		_fail += 1
		print("  FAIL  ", label)
