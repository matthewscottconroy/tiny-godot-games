extends Node2D

# Drives the real LineOfSight helper from scripts/line_of_sight.gd against a
# real physics world built here, rather than asserting on stand-in booleans.
#
# The node extends Node2D so it has a World2D to query, and the ray casts happen
# in _physics_process — direct_space_state is only safe to use from there.

var _pass := 0
var _fail := 0
var _done := false

const VISION_RANGE := 320.0
const WALL_LAYER := 2          # matches the demo: walls live on layer 2
const WALL_MASK := 2           # so rays are cast with collision_mask = 2

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# A solid 40x400 wall centred at `x`, on the wall layer.
func _add_wall(x: float) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.position = Vector2(x, 0)
	wall.collision_layer = WALL_LAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 400)
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)
	return wall

func _physics_process(_delta: float) -> void:
	if _done:
		return
	_done = true

	var space := get_world_2d().direct_space_state

	test_clear_line(space)
	test_wall_blocks(space)
	test_exclude_ignores_a_body(space)
	test_mask_selects_what_blocks(space)
	test_range_checks()
	_report()

func test_clear_line(space: PhysicsDirectSpaceState2D) -> void:
	print("an unobstructed ray is clear")
	expect(LineOfSight.is_clear(space, Vector2(-200, 0), Vector2(200, 0), WALL_MASK),
		"nothing between the endpoints means clear line of sight")

func test_wall_blocks(space: PhysicsDirectSpaceState2D) -> void:
	print("a wall blocks the ray")
	_add_wall(0.0)
	expect(not LineOfSight.is_clear(space, Vector2(-200, 0), Vector2(200, 0), WALL_MASK),
		"a wall across the ray blocks line of sight")
	expect(LineOfSight.is_clear(space, Vector2(-200, 300), Vector2(200, 300), WALL_MASK),
		"a ray that passes clear of the wall is unobstructed")

func test_exclude_ignores_a_body(space: PhysicsDirectSpaceState2D) -> void:
	print("excluded bodies do not block")
	var wall := _add_wall(600.0)
	var from := Vector2(400, 0)
	var to := Vector2(800, 0)
	expect(not LineOfSight.is_clear(space, from, to, WALL_MASK), "the wall blocks by default")
	expect(LineOfSight.is_clear(space, from, to, WALL_MASK, [wall.get_rid()]),
		"excluding the body's RID makes the same ray clear — this is how the observer "
		+ "and target avoid blocking themselves")

func test_mask_selects_what_blocks(space: PhysicsDirectSpaceState2D) -> void:
	print("the collision mask selects what can block")
	# The walls above are on layer 2; a ray masked to layer 1 must ignore them.
	expect(LineOfSight.is_clear(space, Vector2(-200, 0), Vector2(200, 0), 1),
		"a mask that excludes the wall's layer sees straight through it")

func test_range_checks() -> void:
	print("callers gate on range before casting")
	expect(VISION_RANGE > 0.0, "vision range is positive")
	expect(Vector2.ZERO.distance_to(Vector2(200, 0)) < VISION_RANGE,
		"player 200 units away is within the 320 vision range")
	expect(Vector2.ZERO.distance_to(Vector2(400, 0)) > VISION_RANGE,
		"player 400 units away is beyond the 320 vision range")

func _report() -> void:
	var summary := "[line-of-sight] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
