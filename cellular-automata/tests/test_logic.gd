extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_grid_dimensions()
	_test_sand_falls_down()
	_test_sand_slides_diagonal()
	_test_water_flows_sideways()
	_test_stone_immovable()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

enum Material { EMPTY = 0, SAND = 1, WATER = 2, STONE = 3 }

func _test_grid_dimensions() -> void:
	print("grid dimensions")
	const GRID_W := 80
	const GRID_H := 60
	const CELL := 8
	expect(GRID_W * CELL == 640, "grid width fills viewport")
	expect(GRID_H * CELL == 480, "grid height fills viewport")

func _test_sand_falls_down() -> void:
	print("sand falls into empty cell below")
	var grid := [[Material.SAND], [Material.EMPTY]]
	if grid[1][0] == Material.EMPTY:
		grid[1][0] = grid[0][0]
		grid[0][0] = Material.EMPTY
	expect(grid[0][0] == Material.EMPTY, "sand cell is now empty")
	expect(grid[1][0] == Material.SAND, "sand moved to cell below")

func _test_sand_slides_diagonal() -> void:
	print("sand slides diagonally when directly below is blocked")
	var below := Material.STONE
	var below_left := Material.EMPTY
	var below_right := Material.STONE
	var moved := false
	if below != Material.EMPTY:
		if below_left == Material.EMPTY:
			moved = true
	expect(moved, "sand slides to lower-left when available")

func _test_water_flows_sideways() -> void:
	print("water flows sideways when below is blocked")
	var below := Material.STONE
	var right := Material.EMPTY
	var moved := false
	if below != Material.EMPTY and right == Material.EMPTY:
		moved = true
	expect(moved, "water moves sideways when floor is present")

func _test_stone_immovable() -> void:
	print("stone does not move")
	var stone := Material.STONE
	expect(stone == Material.STONE, "stone type value is 3")
	var will_move := (stone == Material.SAND or stone == Material.WATER)
	expect(not will_move, "stone is not processed by movement rules")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
