extends Node

# Drives the real player and grid from scripts/, including the demo's own wall
# layout — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_open_move_succeeds()
	_test_wall_blocks_the_move()
	_test_blocked_move_leaves_position_untouched()
	_test_every_direction_moves_one_cell()
	_test_cell_to_world_centres_the_sprite()
	_test_walls_exist_in_the_demo_grid()
	_test_repeated_moves_accumulate()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[grid-movement] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# The player reads its grid from its parent, so the demo scene is the fixture.
func _scene() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _player(scene: Node2D) -> Node2D:
	for child in scene.get_children():
		if child.has_method("try_move"):
			return child
	return null

func _open_cell(scene: Node2D, from: Vector2i) -> Vector2i:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if not scene.is_wall(from + d):
			return d
	return Vector2i.ZERO

func _test_open_move_succeeds() -> void:
	print("moving into open space")
	var scene := _scene()
	var p := _player(scene)
	var start: Vector2i = p.grid_pos
	var d := _open_cell(scene, start)
	expect(d != Vector2i.ZERO, "the starting cell has at least one open neighbour")
	expect(p.try_move(d), "the move is allowed")
	expect(p.grid_pos == start + d, "and the grid position advances by exactly one cell")

func _test_wall_blocks_the_move() -> void:
	print("walls block")
	var scene := _scene()
	var p := _player(scene)
	# Find a wall adjacent to somewhere the player can stand, and try to enter it.
	var blocked := false
	for y in range(1, scene.ROWS - 1):
		for x in range(1, scene.COLS - 1):
			var cell := Vector2i(x, y)
			if scene.is_wall(cell) or blocked:
				continue
			for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				if scene.is_wall(cell + d):
					p.grid_pos = cell
					expect(not p.try_move(d), "moving into a wall is refused")
					blocked = true
					break
	expect(blocked, "the demo grid contains a wall to test against")

func _test_blocked_move_leaves_position_untouched() -> void:
	print("a refused move changes nothing")
	var scene := _scene()
	var p := _player(scene)
	for y in range(1, scene.ROWS - 1):
		for x in range(1, scene.COLS - 1):
			var cell := Vector2i(x, y)
			if scene.is_wall(cell):
				continue
			for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				if scene.is_wall(cell + d):
					p.grid_pos = cell
					p.try_move(d)
					expect(p.grid_pos == cell, "the player stays where it was")
					return

func _test_every_direction_moves_one_cell() -> void:
	print("one cell per press")
	var scene := _scene()
	var p := _player(scene)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		# Park somewhere with room in this direction.
		var placed := false
		for y in range(2, scene.ROWS - 2):
			for x in range(2, scene.COLS - 2):
				var cell := Vector2i(x, y)
				if not scene.is_wall(cell) and not scene.is_wall(cell + d):
					p.grid_pos = cell
					p.try_move(d)
					expect(p.grid_pos == cell + d, "step %s moves exactly one cell" % d)
					placed = true
					break
			if placed:
				break

func _test_cell_to_world_centres_the_sprite() -> void:
	print("cell to world")
	var scene := _scene()
	var world: Vector2 = scene.cell_to_world(Vector2i(0, 0))
	expect(is_equal_approx(world.x, scene.CELL * 0.5), "cell 0 maps to half a cell in")
	var next: Vector2 = scene.cell_to_world(Vector2i(1, 0))
	expect(is_equal_approx(next.x - world.x, scene.CELL), "adjacent cells are one CELL apart")

func _test_walls_exist_in_the_demo_grid() -> void:
	print("the grid has walls")
	var scene := _scene()
	var walls := 0
	for y in scene.ROWS:
		for x in scene.COLS:
			if scene.is_wall(Vector2i(x, y)):
				walls += 1
	expect(walls > 0, "the demo builds a maze rather than an empty field")

func _test_repeated_moves_accumulate() -> void:
	print("successive moves")
	var scene := _scene()
	var p := _player(scene)
	var start: Vector2i = p.grid_pos
	var d := _open_cell(scene, start)
	# try_move has a side effect, so it must not sit in a loop condition that can
	# short-circuit after it has already moved the player.
	var steps := 0
	for i in 3:
		if not p.try_move(d):
			break
		steps += 1
	expect(p.grid_pos == start + d * steps, "each accepted move advances one more cell")
