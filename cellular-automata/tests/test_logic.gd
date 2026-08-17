extends Node

# Drives the real simulation from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_grid_starts_empty()
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

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _count(m: Node2D, mat: int) -> int:
	var total := 0
	for row in m._grid:
		for cell in row:
			if cell == mat:
				total += 1
	return total

func _test_the_grid_starts_empty() -> void:
	print("a clean slate")
	var m := _make()
	expect(m._grid.size() == m.GRID_H, "the grid is GRID_H rows")
	expect(m._grid[0].size() == m.GRID_W, "of GRID_W cells")
	expect(_count(m, m.Cell.EMPTY) == m.GRID_W * m.GRID_H, "and every one of them is empty")

func _test_painting_puts_material_down() -> void:
	print("the brush")
	var m := _make()
	m._paint(Vector2(40 * m.CELL, 20 * m.CELL), m.Cell.SAND)
	expect(m._grid[20][40] == m.Cell.SAND, "painting fills the cell under the cursor")
	var width: int = m._brush * 2 + 1
	expect(_count(m, m.Cell.SAND) == width * width, "and a square of cells around it")

	m._paint(Vector2(40 * m.CELL, 20 * m.CELL), m.Cell.EMPTY)
	expect(_count(m, m.Cell.SAND) == 0, "painting empty rubs it out again")

func _test_painting_at_the_edge_stays_on_the_grid() -> void:
	print("painting off the edge")
	var m := _make()
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
	var m := _make()
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
	var m := _make()
	m._grid[10][40] = m.Cell.SAND
	m._step()
	expect(m._grid[10][40] == m.Cell.EMPTY, "a grain leaves the cell it was in")
	expect(m._grid[11][40] == m.Cell.SAND, "and lands in the one below")

func _test_sand_slides_off_a_pile() -> void:
	print("piling up")
	var m := _make()
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
	var m := _make()
	for x in m.GRID_W:
		m._grid[30][x] = m.Cell.STONE
	m._grid[29][40] = m.Cell.SAND
	for i in 5:
		m._step()
	expect(m._grid[29][40] == m.Cell.SAND, "sand does not fall through a stone floor")

func _test_stone_never_moves() -> void:
	print("stone")
	var m := _make()
	m._grid[10][40] = m.Cell.STONE
	for i in 10:
		m._step()
	expect(m._grid[10][40] == m.Cell.STONE, "stone stays put in mid-air — it is scenery")

func _test_water_spreads_out_flat() -> void:
	print("water")
	var m := _make()
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
	var m := _make()
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
	var m := _make()
	var first: bool = m._scan_right
	m._step()
	expect(m._scan_right != first, "each step scans the opposite way from the last")
	m._step()
	expect(m._scan_right == first, "alternating, so neither direction biases the pile")
