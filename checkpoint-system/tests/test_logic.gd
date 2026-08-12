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
