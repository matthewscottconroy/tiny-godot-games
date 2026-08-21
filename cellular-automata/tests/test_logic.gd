extends Node

# Drives the real simulation from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_world_opens_with_something_in_it()
	_test_the_seed_is_the_same_every_run()
	_test_clearing_empties_the_grid()
	_test_painting_puts_material_down()
	_test_painting_at_the_edge_stays_on_the_grid()
	_test_the_number_keys_pick_a_material()
	_test_sand_falls()
	_test_sand_slides_off_a_pile()
	_test_sand_rests_on_stone()
	_test_stone_never_moves()
	_test_water_spreads_out_flat()
	_test_nothing_is_created_or_destroyed()
	_test_the_scan_direction_alternates()
	_test_water_spreads_to_both_sides()
	_test_a_key_release_selects_nothing()
	_test_the_divider_stands_between_the_two_materials()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[cellular-automata] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

## The demo as it opens: seeded, with sand already falling.
func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

## The same demo cleared, for the tests that build one specific arrangement of
## cells and watch what it does. Seeded material elsewhere on the grid would
## not change the answer, but it would make the setup harder to read.
func _make_empty() -> Node2D:
	var m := _make()
	m._reset()
	return m

func _count(m: Node2D, mat: int) -> int:
	var total := 0
	for row in m._grid:
		for cell in row:
			if cell == mat:
				total += 1
	return total

## The demo used to open onto an empty grid and do nothing until clicked, which
## is a poor way to show an automaton. It seeds itself now, and this is the check
## that it still does — a blank opening frame is the failure to catch.
func _test_the_world_opens_with_something_in_it() -> void:
	print("the opening frame")
	var m := _make()
	var counts: Dictionary = m.census()
	expect(counts[m.Cell.SAND] > 100, "there is sand in the world before anything is clicked (%d)" % counts[m.Cell.SAND])
	expect(counts[m.Cell.WATER] > 100, "and water (%d)" % counts[m.Cell.WATER])
	expect(counts[m.Cell.STONE] > 100, "and stone for them to land on (%d)" % counts[m.Cell.STONE])

	# Something has to be falling, or the opening frame is a still life.
	var before: int = _lowest_row(m, m.Cell.SAND)
	for _i in 20:
		m._step()
	expect(_lowest_row(m, m.Cell.SAND) > before,
		"and the sand is falling from the first step (row %d -> %d)" % [before, _lowest_row(m, m.Cell.SAND)])

func _test_the_seed_is_the_same_every_run() -> void:
	print("determinism")
	# randf lives in the falling rules, not in the seed. If it crept into the
	# seed the opening frame would differ run to run and nothing above could be
	# asserted against it.
	var a: Dictionary = _make().census()
	var b: Dictionary = _make().census()
	expect(a == b, "two fresh worlds start identical")

func _lowest_row(m: Node2D, mat: int) -> int:
	var lowest := -1
	for y in m.GRID_H:
		for x in m.GRID_W:
			if m._grid[y][x] == mat:
				lowest = y
	return lowest

func _test_clearing_empties_the_grid() -> void:
	print("a clean slate")
	var m := _make()
	expect(m._grid.size() == m.GRID_H, "the grid is GRID_H rows")
	expect(m._grid[0].size() == m.GRID_W, "of GRID_W cells")
	m._reset()
	expect(_count(m, m.Cell.EMPTY) == m.GRID_W * m.GRID_H, "and C empties every one of them")

func _test_painting_puts_material_down() -> void:
	print("the brush")
	var m := _make_empty()
	m._paint(Vector2(40 * m.CELL, 20 * m.CELL), m.Cell.SAND)
	expect(m._grid[20][40] == m.Cell.SAND, "painting fills the cell under the cursor")
	var width: int = m._brush * 2 + 1
	expect(_count(m, m.Cell.SAND) == width * width, "and a square of cells around it")

	m._paint(Vector2(40 * m.CELL, 20 * m.CELL), m.Cell.EMPTY)
	expect(_count(m, m.Cell.SAND) == 0, "painting empty rubs it out again")

func _test_painting_at_the_edge_stays_on_the_grid() -> void:
	print("painting off the edge")
	var m := _make_empty()
	# Half the brush hangs off the corner; the other half still lands.
	m._paint(Vector2(0.0, 0.0), m.Cell.SAND)
	expect(m._grid[0][0] == m.Cell.SAND, "the corner cell is painted")
	expect(_count(m, m.Cell.SAND) < (m._brush * 2 + 1) * (m._brush * 2 + 1),
		"and the part of the brush past the edge is simply dropped")

	# Dropped, not wrapped: a negative index would quietly paint the far side of
	# the grid, which looks like material appearing out of nowhere.
	var wrapped := false
	for y in m.GRID_H:
		if m._grid[y][m.GRID_W - 1] != m.Cell.EMPTY:
			wrapped = true
	for x in m.GRID_W:
		if m._grid[m.GRID_H - 1][x] != m.Cell.EMPTY:
			wrapped = true
	expect(not wrapped, "and nothing appears on the opposite edge")

func _test_the_number_keys_pick_a_material() -> void:
	print("choosing a material")
	var m := _make_empty()
	for pair in [[KEY_1, m.Cell.SAND], [KEY_2, m.Cell.WATER], [KEY_3, m.Cell.STONE]]:
		var e := InputEventKey.new()
		e.keycode = pair[0]
		e.pressed = true
		m._input(e)
		expect(m._selected == pair[1], "a number key selects its material")

	m._paint(Vector2(40 * m.CELL, 20 * m.CELL), m._selected)
	var clear := InputEventKey.new()
	clear.keycode = KEY_C
	clear.pressed = true
	m._input(clear)
	expect(_count(m, m.Cell.EMPTY) == m.GRID_W * m.GRID_H, "and C wipes the grid")

func _test_sand_falls() -> void:
	print("sand")
	var m := _make_empty()
	m._grid[10][40] = m.Cell.SAND
	m._step()
	expect(m._grid[10][40] == m.Cell.EMPTY, "a grain leaves the cell it was in")
	expect(m._grid[11][40] == m.Cell.SAND, "and lands in the one below")

func _test_sand_slides_off_a_pile() -> void:
	print("piling up")
	var m := _make_empty()
	# A grain sitting directly on another has nowhere down to go, so it takes
	# the diagonal — that is what makes a heap instead of a tower.
	m._grid[m.GRID_H - 1][40] = m.Cell.SAND
	m._grid[m.GRID_H - 2][40] = m.Cell.SAND
	m._step()
	var slid: bool = m._grid[m.GRID_H - 1][39] == m.Cell.SAND \
		or m._grid[m.GRID_H - 1][41] == m.Cell.SAND
	expect(slid, "a grain landing on another slides off to one side")

	# With only one diagonal open, the grain has to take that one — both sides
	# are checked, not just whichever the code happens to test first.
	var leftward := _make()
	leftward._grid[leftward.GRID_H - 1][40] = leftward.Cell.SAND
	leftward._grid[leftward.GRID_H - 1][41] = leftward.Cell.SAND
	leftward._grid[leftward.GRID_H - 2][40] = leftward.Cell.SAND
	leftward._step()
	expect(leftward._grid[leftward.GRID_H - 1][39] == leftward.Cell.SAND,
		"with only the left diagonal open, the grain slides left")

	var rightward := _make()
	rightward._grid[rightward.GRID_H - 1][40] = rightward.Cell.SAND
	rightward._grid[rightward.GRID_H - 1][39] = rightward.Cell.SAND
	rightward._grid[rightward.GRID_H - 2][40] = rightward.Cell.SAND
	rightward._step()
	expect(rightward._grid[rightward.GRID_H - 1][41] == rightward.Cell.SAND,
		"and with only the right one open, it slides right")

	var boxed := _make()
	boxed._grid[boxed.GRID_H - 1][40] = boxed.Cell.SAND
	boxed._grid[boxed.GRID_H - 1][39] = boxed.Cell.SAND
	boxed._grid[boxed.GRID_H - 1][41] = boxed.Cell.SAND
	boxed._grid[boxed.GRID_H - 2][40] = boxed.Cell.SAND
	boxed._step()
	expect(boxed._grid[boxed.GRID_H - 2][40] == boxed.Cell.SAND,
		"but with both diagonals blocked it stays where it is")

func _test_sand_rests_on_stone() -> void:
	print("sand on stone")
	var m := _make_empty()
	for x in m.GRID_W:
		m._grid[30][x] = m.Cell.STONE
	m._grid[29][40] = m.Cell.SAND
	for i in 5:
		m._step()
	expect(m._grid[29][40] == m.Cell.SAND, "sand does not fall through a stone floor")

func _test_stone_never_moves() -> void:
	print("stone")
	var m := _make_empty()
	m._grid[10][40] = m.Cell.STONE
	for i in 10:
		m._step()
	expect(m._grid[10][40] == m.Cell.STONE, "stone stays put in mid-air — it is scenery")

func _test_water_spreads_out_flat() -> void:
	print("water")
	var m := _make_empty()
	var floor_y: int = m.GRID_H - 1
	m._grid[floor_y][40] = m.Cell.WATER
	m._grid[floor_y - 1][40] = m.Cell.WATER
	m._step()
	# It flows into whichever neighbour the coin-flip picks, in its own row —
	# the drop below it is already occupied.
	var moved_off: bool = m._grid[floor_y - 1][40] != m.Cell.WATER
	var sideways: bool = m._grid[floor_y - 1][39] == m.Cell.WATER \
		or m._grid[floor_y - 1][41] == m.Cell.WATER \
		or m._grid[floor_y][39] == m.Cell.WATER \
		or m._grid[floor_y][41] == m.Cell.WATER
	expect(moved_off and sideways, "water blocked below flows sideways instead of stacking")

	var tower := _make()
	for y in range(tower.GRID_H - 6, tower.GRID_H):
		tower._grid[y][40] = tower.Cell.WATER
	for i in 30:
		tower._step()
	var column := 0
	for y in tower.GRID_H:
		if tower._grid[y][40] == tower.Cell.WATER:
			column += 1
	expect(column < 6, "and a column of water collapses into a puddle")

func _test_nothing_is_created_or_destroyed() -> void:
	print("conservation")
	var m := _make_empty()
	m._paint(Vector2(30 * m.CELL, 10 * m.CELL), m.Cell.SAND)
	m._paint(Vector2(50 * m.CELL, 10 * m.CELL), m.Cell.WATER)
	var sand := _count(m, m.Cell.SAND)
	var water := _count(m, m.Cell.WATER)
	for i in 60:
		m._step()
	# A cell-swapping rule is easy to get wrong in a way that duplicates or eats
	# material; the totals are the cheapest guard against it.
	expect(_count(m, m.Cell.SAND) == sand, "every grain of sand is still there")
	expect(_count(m, m.Cell.WATER) == water, "and every drop of water")

func _test_the_scan_direction_alternates() -> void:
	print("scan order")
	var m := _make_empty()
	var first: bool = m._scan_right
	m._step()
	expect(m._scan_right != first, "each step scans the opposite way from the last")
	m._step()
	expect(m._scan_right == first, "alternating, so neither direction biases the pile")
	# And it starts on a known foot, so two worlds stepped the same number of
	# times resolve their ties the same way — which is what makes seed_world
	# reproducible at all.
	expect(first, "a fresh world starts scanning rightward")

## Water levels out in both directions.
##
## Each side is guarded by its own edge check, and a guard that can never be
## true simply stops water going that way — which looks like water with a lean
## rather than water that is broken.
func _test_water_spreads_to_both_sides() -> void:
	print("water spreads both ways")
	var m := _make_empty()
	var floor_y: int = m.GRID_H - 1
	var middle: int = m.GRID_W / 2
	# A column of water on a floor, with open ground either side of it.
	for y in range(floor_y - 6, floor_y + 1):
		m._grid[y][middle] = m.Cell.WATER

	for _i in 40:
		m._step()

	var leftmost: int = m.GRID_W
	var rightmost := -1
	for y in m.GRID_H:
		for x in m.GRID_W:
			if m._grid[y][x] == m.Cell.WATER:
				leftmost = mini(leftmost, x)
				rightmost = maxi(rightmost, x)
	expect(leftmost < middle,
		"water runs left of where it was poured (%d < %d)" % [leftmost, middle])
	expect(rightmost > middle,
		"and right of it (%d > %d)" % [rightmost, middle])
	expect(middle - leftmost > 1 and rightmost - middle > 1,
		"a real puddle either side, not one cell (%d .. %d)" % [leftmost, rightmost])

	# Poured against the left wall it still spreads, which is the case the edge
	# guard exists for — and it must not fall off the grid doing it.
	var edge := _make_empty()
	for y in range(floor_y - 6, floor_y + 1):
		edge._grid[y][0] = edge.Cell.WATER
	for _i in 40:
		edge._step()
	var counted := 0
	for y in edge.GRID_H:
		for x in edge.GRID_W:
			if edge._grid[y][x] == edge.Cell.WATER:
				counted += 1
	expect(counted == 7, "no water is lost off the left edge (%d of 7)" % counted)

	# And against the right wall, which is the other half of the same guard —
	# and the half that reads one cell past the end of the row if it is wrong.
	var right := _make_empty()
	var last: int = right.GRID_W - 1
	for y in range(floor_y - 6, floor_y + 1):
		right._grid[y][last] = right.Cell.WATER
	for _i in 40:
		right._step()
	var right_count := 0
	for y in right.GRID_H:
		for x in right.GRID_W:
			if right._grid[y][x] == right.Cell.WATER:
				right_count += 1
	expect(right_count == 7, "nor off the right edge (%d of 7)" % right_count)

	# Sand piled against the right wall is the same guard on the diagonal.
	var corner := _make_empty()
	for y in range(floor_y - 6, floor_y + 1):
		corner._grid[y][last] = corner.Cell.SAND
	for _i in 40:
		corner._step()
	var grains := 0
	for y in corner.GRID_H:
		for x in corner.GRID_W:
			if corner._grid[y][x] == corner.Cell.SAND:
				grains += 1
	expect(grains == 7, "and no sand either (%d of 7)" % grains)

## A key coming back up does not pick a material.
func _test_a_key_release_selects_nothing() -> void:
	print("key releases")
	var m := _make_empty()
	m._selected = m.Cell.SAND

	var release := InputEventKey.new()
	release.keycode = KEY_2
	release.pressed = false
	m._input(release)
	expect(m._selected == m.Cell.SAND,
		"releasing a number key leaves the material alone (%d)" % m._selected)

	var repeat := InputEventKey.new()
	repeat.keycode = KEY_2
	repeat.pressed = true
	repeat.echo = true
	m._input(repeat)
	expect(m._selected == m.Cell.SAND, "and neither does an auto-repeat")

	var mouse := InputEventMouseMotion.new()
	m._input(mouse)
	expect(m._selected == m.Cell.SAND, "nor a mouse event")

	var press := InputEventKey.new()
	press.keycode = KEY_2
	press.pressed = true
	m._input(press)
	expect(m._selected == m.Cell.WATER, "while a fresh press does (%d)" % m._selected)

## The opening arrangement keeps the sand and the water apart.
##
## The bowl has a divider down the middle so both behaviours are visible side by
## side from the first frame. Put it anywhere else and the two run together,
## which is one pile of mixed material rather than two demonstrations.
func _test_the_divider_stands_between_the_two_materials() -> void:
	print("the divider")
	var m := _make()

	var sand_x: Array[int] = []
	var water_x: Array[int] = []
	# Stone above the bowl's floor only. The floor itself runs the whole width,
	# so counting every stone cell between the two materials averages in a
	# dozen floor cells and the divider barely moves the answer — which is a
	# measurement of the floor wearing the divider's name.
	var divider_x: Array[int] = []
	var floor_row: int = m.GRID_H - 6
	for y in m.GRID_H:
		for x in m.GRID_W:
			match m._grid[y][x]:
				m.Cell.SAND: sand_x.append(x)
				m.Cell.WATER: water_x.append(x)
				m.Cell.STONE:
					if y < floor_row:
						divider_x.append(x)
	expect(sand_x.size() > 0 and water_x.size() > 0, "the world opens with both materials")

	var sand_right: int = sand_x.max()
	var water_left: int = water_x.min()
	expect(sand_right < water_left,
		"the sand is entirely left of the water (%d < %d)" % [sand_right, water_left])

	# A stone divider stands in the gap between them.
	var between := 0
	for x in divider_x:
		if x > sand_right and x < water_left:
			between += 1
	expect(between > 0,
		"with stone standing between the two (%d cells in %d..%d)"
		% [between, sand_right, water_left])

	# It stands in the middle of the bowl, so the two halves are the same size.
	# Off to one side and one material has visibly more room than the other.
	var divider_sum := 0
	for x in divider_x:
		if x > sand_right and x < water_left:
			divider_sum += x
	var divider_centre := float(divider_sum) / float(between)
	expect(absf(divider_centre - m.GRID_W * 0.5) <= 1.0,
		"centred in the bowl (%.1f of %d)" % [divider_centre, m.GRID_W])

	# And after settling they are still apart, which is what the divider is for.
	for _i in 120:
		m._step()
	var settled_sand := -1
	var settled_water: int = m.GRID_W
	for y in m.GRID_H:
		for x in m.GRID_W:
			if m._grid[y][x] == m.Cell.SAND:
				settled_sand = maxi(settled_sand, x)
			elif m._grid[y][x] == m.Cell.WATER:
				settled_water = mini(settled_water, x)
	expect(settled_sand < settled_water,
		"and they stay apart once everything has fallen (%d < %d)"
		% [settled_sand, settled_water])
