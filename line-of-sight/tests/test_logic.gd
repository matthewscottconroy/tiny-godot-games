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
	await test_the_enemy_uses_all_of_it()
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

# --- the real enemy ----------------------------------------------------------

## Everything above tests the LineOfSight helper, which was never the weak half.
## enemy.gd is what decides whether a given enemy is alerted, and nothing drove
## it: every mutation to it survived.
func test_the_enemy_uses_all_of_it() -> void:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame

	var player: CharacterBody2D = scene.get_node("Player")
	var enemy: CharacterBody2D = scene.get_node("Enemy1")
	var label: Label = enemy.get_node("StateLabel")

	print("an enemy starts unalerted")
	# A fresh enemy has not looked at anything yet. Starting alerted would have
	# every enemy in the level shouting on the first frame.
	var fresh: CharacterBody2D = load("res://scripts/enemy.gd").new()
	expect(not fresh._can_see, "a newly made enemy is not alerted")
	fresh.free()

	print("no player, no alert")
	# The player is found by group at _ready. If it is missing — or has been
	# freed — the enemy has to fall back to unalerted rather than keep whatever
	# it last decided.
	enemy._can_see = true
	var kept: CharacterBody2D = enemy._player
	enemy._player = null
	enemy._check_los()
	expect(not enemy._can_see, "an enemy with no player to look at is not alerted")
	enemy._player = kept

	print("range gates the ray")
	# Far away with nothing in between: still not alerted, because the range
	# check happens before the ray is cast.
	player.global_position = enemy.global_position + Vector2(0, -400)
	await get_tree().physics_frame
	var far := enemy.global_position.distance_to(player.global_position)
	expect(far > VISION_RANGE, "the player is beyond vision range (%.0f)" % far)
	expect(not enemy._can_see, "and the enemy is not alerted, though the line is clear")
	expect(label.text == "patrol", "the label reads patrol (%s)" % label.text)

	print("close and clear")
	player.global_position = enemy.global_position + Vector2(0, -80)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var near := enemy.global_position.distance_to(player.global_position)
	expect(near < VISION_RANGE, "the player is inside vision range (%.0f)" % near)
	expect(enemy._can_see, "and with a clear line the enemy is alerted")
	expect(label.text == "ALERT!", "the label reads ALERT! (%s)" % label.text)
	expect(label.modulate != Color(1, 1, 1, 0.5), "and is coloured as an alert")

	print("a wall inside the range still blocks")
	# Same distance, but with a wall across the line — this is the case that
	# separates a range check from line of sight.
	var blocker := StaticBody2D.new()
	blocker.collision_layer = WALL_LAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(200, 20)
	shape.shape = rect
	blocker.add_child(shape)
	blocker.global_position = enemy.global_position + Vector2(0, -40)
	scene.add_child(blocker)
	await get_tree().physics_frame
	await get_tree().physics_frame
	expect(enemy.global_position.distance_to(player.global_position) < VISION_RANGE,
		"the player is still within range")
	expect(not enemy._can_see, "but a wall across the line un-alerts the enemy")
	expect(label.text == "patrol", "and the label goes back to patrol (%s)" % label.text)

	print("the player stays put when nothing is pressed")
	# Not a line-of-sight rule, but the one line in the demo nothing was
	# holding. The jump reads Input, which a headless test cannot press — what
	# it *can* assert is the other half of the condition: with no input at all,
	# a player standing on the floor must not leave it. Loosen that `and` to an
	# `or` and it launches on every frame it is grounded.
	blocker.queue_free()
	# The floor's top is at y=440 and the player is 28 tall, so it rests at 426.
	# Dropped from 380 that is 46px of fall, about twenty frames at this gravity.
	player.global_position = Vector2(80, 380)
	player.velocity = Vector2.ZERO
	for _i in 40:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player has settled on the floor")
	var resting := player.global_position.y
	var highest := resting
	for _i in 30:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"and never rises without a key being pressed (rose %.1f px)" % (resting - highest))
	expect(absf(player.velocity.y) < 60.0,
		"nor picks up upward speed (%.0f)" % player.velocity.y)

	scene.queue_free()

func _report() -> void:
	var summary := "[line-of-sight] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
