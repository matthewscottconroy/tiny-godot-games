extends Node

# Instantiates the demo scene and drives the real Checkpoint nodes from
# scripts/checkpoint.gd, plus the real player from scripts/player.gd.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_initial_spawn()
	_test_set_checkpoint()
	_test_ordering()
	_test_activation_emits_id()
	_test_already_activated()
	_test_checkpoint_ids_are_distinct()
	await _test_the_spawn_lands_above_the_flag()
	await _test_only_R_respawns()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# The demo wires everything up in main.tscn, so the scene is the fixture.
func _make_scene() -> Node:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

# Checkpoint only reacts to bodies in the "player" group.
func _make_player_body() -> Node2D:
	var body := Node2D.new()
	body.add_to_group("player")
	add_child(body)
	return body

func _test_initial_spawn() -> void:
	print("initial spawn point")
	var scene := _make_scene()
	var player: CharacterBody2D = scene.get_node("Player")
	var start: Vector2 = player.global_position
	player.global_position = start + Vector2(200, -50)
	player.respawn()
	expect(player.global_position == start, "respawn returns to the starting position")

func _test_set_checkpoint() -> void:
	print("set_checkpoint moves the spawn point")
	var scene := _make_scene()
	var player: CharacterBody2D = scene.get_node("Player")
	player.set_checkpoint(Vector2(400, 120))
	player.global_position = Vector2(10, 10)
	player.respawn()
	expect(player.global_position == Vector2(400, 120), "respawn lands at the new checkpoint")
	expect(player.velocity == Vector2.ZERO, "respawn also clears velocity")

func _test_ordering() -> void:
	print("last activated checkpoint wins")
	var scene := _make_scene()
	var player: CharacterBody2D = scene.get_node("Player")
	player.set_checkpoint(Vector2(100, 0))
	player.set_checkpoint(Vector2(200, 0))
	player.set_checkpoint(Vector2(300, 0))
	player.respawn()
	expect(player.global_position == Vector2(300, 0), "the most recent checkpoint is the spawn point")

func _test_activation_emits_id() -> void:
	print("activation emits the checkpoint id")
	var scene := _make_scene()
	var checkpoint: Checkpoint = scene.get_node("Checkpoint2")
	var ids: Array[int] = []
	checkpoint.activated.connect(func(id: int) -> void: ids.append(id))
	checkpoint._on_body_entered(_make_player_body())
	expect(ids == [checkpoint.checkpoint_id], "activated carries the checkpoint's own id")

func _test_already_activated() -> void:
	print("already-activated guard")
	var scene := _make_scene()
	var checkpoint: Checkpoint = scene.get_node("Checkpoint1")
	var ids: Array[int] = []
	checkpoint.activated.connect(func(id: int) -> void: ids.append(id))
	checkpoint._on_body_entered(_make_player_body())
	checkpoint._on_body_entered(_make_player_body())
	expect(ids.size() == 1, "signal fires only once per checkpoint")

	# A non-player body must never arm a checkpoint.
	var fresh: Checkpoint = scene.get_node("Checkpoint3")
	var fresh_ids: Array[int] = []
	fresh.activated.connect(func(id: int) -> void: fresh_ids.append(id))
	var debris := Node2D.new()
	add_child(debris)
	fresh._on_body_entered(debris)
	expect(fresh_ids.is_empty(), "a body outside the player group does not activate it")

func _test_checkpoint_ids_are_distinct() -> void:
	print("checkpoint ids")
	var scene := _make_scene()
	var ids: Array[int] = []
	for name in ["Checkpoint1", "Checkpoint2", "Checkpoint3"]:
		var cp: Checkpoint = scene.get_node(name)
		ids.append(cp.checkpoint_id)
	expect(ids.size() == 3, "the demo places three checkpoints")
	var unique := {}
	for id in ids:
		unique[id] = true
	expect(unique.size() == 3, "each checkpoint carries a distinct id")

func _report() -> void:
	var summary := "[checkpoint-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# --- the wiring, and the key that uses it ------------------------------------

## Touching a checkpoint sets the spawn *above* it, not on it.
##
## `cp.global_position + Vector2(0, -30)` is the whole difference between
## respawning standing on the platform and respawning inside it — Y is down, so
## the sign here is the thing to get wrong.
func _test_the_spawn_lands_above_the_flag() -> void:
	print("where a checkpoint puts you")
	var scene: Node = _make_scene()
	await get_tree().physics_frame
	var player: CharacterBody2D = scene.get_node("Player")
	var flags := get_tree().get_nodes_in_group("checkpoint")
	expect(flags.size() > 1, "the level has several checkpoints (%d)" % flags.size())

	var flag: Area2D = flags[1]
	scene._on_checkpoint(flag)
	expect(player._spawn_point.y < flag.global_position.y,
		"the spawn is above the flag, not below it (%.0f vs %.0f)"
		% [player._spawn_point.y, flag.global_position.y])
	expect(is_equal_approx(player._spawn_point.x, flag.global_position.x),
		"and directly over it (%.0f vs %.0f)"
		% [player._spawn_point.x, flag.global_position.x])
	expect(flag.global_position.y - player._spawn_point.y < 60.0,
		"a body's height up, not a screen (%.0f)"
		% (flag.global_position.y - player._spawn_point.y))

	# Respawning from there puts the player back at that point, and standing:
	# a respawn that keeps the fall speed drops straight through the platform.
	player.global_position = Vector2(50, 50)
	player.velocity = Vector2(120, 900)
	player.respawn()
	expect(player.global_position == player._spawn_point,
		"respawning returns to the saved point (%s)" % player.global_position)
	expect(player.velocity == Vector2.ZERO,
		"with no speed carried over (%s)" % player.velocity)

	# The wiring itself: every flag in the group reaches the player, so a later
	# checkpoint overwrites an earlier one.
	scene._on_checkpoint(flags[0])
	var first: Vector2 = player._spawn_point
	scene._on_checkpoint(flags[flags.size() - 1])
	expect(player._spawn_point != first,
		"a different flag moves the spawn (%s -> %s)" % [first, player._spawn_point])

	scene.queue_free()

## R respawns; nothing else does.
##
## The handler tests three things at once — pressed, not an auto-repeat, and the
## right key — and any one of them dropping turns "press R" into "press
## anything", or into a respawn on the key coming back up as well as going down.
func _test_only_R_respawns() -> void:
	print("the respawn key")
	var scene: Node = _make_scene()
	await get_tree().physics_frame
	var player: CharacterBody2D = scene.get_node("Player")

	player.set_checkpoint(Vector2(400, 100))
	var away := Vector2(50, 300)

	player.global_position = away
	player._unhandled_key_input(_key(KEY_R, true, false))
	expect(player.global_position == Vector2(400, 100), "R respawns")

	player.global_position = away
	player._unhandled_key_input(_key(KEY_T, true, false))
	expect(player.global_position == away, "another key does not")

	player.global_position = away
	player._unhandled_key_input(_key(KEY_R, false, false))
	expect(player.global_position == away, "nor does R coming back up")

	player.global_position = away
	player._unhandled_key_input(_key(KEY_R, true, true))
	expect(player.global_position == away,
		"nor an auto-repeat, which would respawn every frame R is held")

	# And with nothing pressed at all the player stays put. The jump reads
	# Input, which cannot be pressed headless — but its other half is
	# is_on_floor(), and loosening the `and` to an `or` launches the player on
	# every grounded frame.
	player.set_checkpoint(Vector2(80, 400))
	player.respawn()
	for _i in 60:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player settles on the ground")
	var resting: float = player.global_position.y
	var highest := resting
	for _i in 40:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"and stays there with no key pressed (rose %.1f px)" % (resting - highest))

	scene.queue_free()

func _key(code: Key, pressed: bool, echo: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	return event
