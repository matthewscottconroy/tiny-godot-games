extends Node

# Drives the real generator from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_generates_rooms()
	_test_rooms_stay_inside_the_map()
	_test_rooms_are_the_size_they_were_asked_for()
	_test_rooms_do_not_touch_each_other()
	_test_rooms_are_carved_out_of_the_wall()
	_test_every_room_can_be_walked_to()
	_test_space_makes_a_different_dungeon()
	_test_regenerating_does_not_accumulate()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[dungeon-generator] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _centre(r: Rect2i) -> Vector2i:
	return Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)

## Every open cell reachable on foot from `from`, walking the four directions.
func _flood(m: Node2D, from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = cur + d
			if nb.x < 0 or nb.x >= m.MAP_W or nb.y < 0 or nb.y >= m.MAP_H:
				continue
			if seen.has(nb) or m._grid[nb.y][nb.x] == m.Tile.WALL:
				continue
			seen[nb] = true
			queue.append(nb)
	return seen

func _test_it_generates_rooms() -> void:
	print("placing rooms")
	var m := _make()
	expect(m._rooms.size() > 1, "the generator places several rooms (%d)" % m._rooms.size())
	expect(m._rooms.size() <= m.NUM_ROOMS, "and never more than it was asked for")
	expect(m._grid.size() == m.MAP_H and m._grid[0].size() == m.MAP_W, "on a map of the stated size")

func _test_rooms_stay_inside_the_map() -> void:
	print("bounds")
	var inside := true
	for attempt in 5:
		var m := _make()
		for r: Rect2i in m._rooms:
			if r.position.x < 1 or r.position.y < 1 \
					or r.position.x + r.size.x >= m.MAP_W \
					or r.position.y + r.size.y >= m.MAP_H:
				inside = false
	expect(inside, "every room fits on the map with a wall left around the edge")

func _test_rooms_are_the_size_they_were_asked_for() -> void:
	print("room sizes")
	var m := _make()
	var sized := true
	for r: Rect2i in m._rooms:
		if r.size.x < m.MIN_W or r.size.x > m.MAX_W or r.size.y < m.MIN_H or r.size.y > m.MAX_H:
			sized = false
	expect(sized, "every room is within the configured size range")

func _test_rooms_do_not_touch_each_other() -> void:
	print("spacing")
	# Rooms are rejected against a grown rectangle, so two rooms should not even
	# share a wall — otherwise they read as one lumpy room.
	var separated := true
	for attempt in 5:
		var m := _make()
		for i in m._rooms.size():
			for j in range(i + 1, m._rooms.size()):
				if (m._rooms[i] as Rect2i).grow(1).intersects(m._rooms[j]):
					separated = false
	expect(separated, "no two rooms overlap or share a wall")

func _test_rooms_are_carved_out_of_the_wall() -> void:
	print("carving")
	var m := _make()
	# Corridors are drawn after the rooms and run straight through them, so a
	# room's cells are floor or corridor — walkable either way, never wall.
	var carved := true
	for r: Rect2i in m._rooms:
		for y in range(r.position.y, r.position.y + r.size.y):
			for x in range(r.position.x, r.position.x + r.size.x):
				if m._grid[y][x] == m.Tile.WALL:
					carved = false
	expect(carved, "every cell inside a room is walkable, not wall")

	var walls := 0
	for row in m._grid:
		for tile in row:
			if tile == m.Tile.WALL:
				walls += 1
	expect(walls > 0, "and the map is not carved away entirely")

func _test_every_room_can_be_walked_to() -> void:
	print("connectivity")
	# The point of the corridor pass: a dungeon with an unreachable room is a
	# broken dungeon, and it is the kind of bug that only shows up sometimes.
	var connected := true
	var worst := ""
	for attempt in 8:
		var m := _make()
		if m._rooms.size() < 2:
			continue
		var reachable := _flood(m, _centre(m._rooms[0]))
		for r: Rect2i in m._rooms:
			if not reachable.has(_centre(r)):
				connected = false
				worst = "room at %s" % r.position
	expect(connected, "every room is reachable from every other one%s" %
		("" if connected else " — %s was not" % worst))

func _test_space_makes_a_different_dungeon() -> void:
	print("regenerating")
	var m := _make()
	var before: Array[Rect2i] = m._rooms.duplicate()
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.pressed = true
	m._input(e)
	expect(m._rooms != before, "space lays out a new dungeon rather than the same one")

func _test_regenerating_does_not_accumulate() -> void:
	print("starting over")
	var m := _make()
	for i in 4:
		m.generate()
	expect(m._rooms.size() <= m.NUM_ROOMS, "rooms from the last dungeon are cleared out")
	var stale := false
	for r: Rect2i in m._rooms:
		for y in range(r.position.y, r.position.y + r.size.y):
			for x in range(r.position.x, r.position.x + r.size.x):
				if m._grid[y][x] == m.Tile.WALL:
					stale = true
	expect(not stale, "and the map is rebuilt from scratch each time")
