extends Node

# Drives the real chase from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_enemy_chases_the_player()
	_test_it_chases_in_every_direction()
	_test_it_moves_at_its_own_speed()
	await _test_it_closes_the_distance()
	_test_it_stops_when_the_player_is_gone()
	_test_the_sight_line_joins_the_two()
	_test_the_readout_measures_the_gap()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[simple-ai] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _enemy(m: Node2D) -> CharacterBody2D:
	return m.get_node("Enemy")

func _player(m: Node2D) -> CharacterBody2D:
	return m.get_node("Player")

func _test_the_enemy_chases_the_player() -> void:
	print("the chase")
	var m := _make()
	var enemy := _enemy(m)
	var player := _player(m)
	# Player placed to the enemy's right: the enemy has to move right, and
	# every coordinate here is positive, so adding the two positions would
	# also point right — hence the check on the other axis too.
	enemy.global_position = Vector2(200.0, 240.0)
	player.global_position = Vector2(400.0, 240.0)
	enemy._physics_process(STEP)
	expect(enemy.velocity.x > 0.0, "the enemy moves towards the player")
	expect(is_zero_approx(enemy.velocity.y), "and straight at them, with nothing sideways")

func _test_it_chases_in_every_direction() -> void:
	print("every direction")
	for offset in [Vector2(-150.0, 0.0), Vector2(0.0, -150.0), Vector2(0.0, 150.0)]:
		var m := _make()
		var enemy := _enemy(m)
		enemy.global_position = Vector2(320.0, 240.0)
		_player(m).global_position = enemy.global_position + offset
		enemy._physics_process(STEP)
		expect(enemy.velocity.normalized().dot(offset.normalized()) > 0.99,
			"a player at %s is chased that way" % offset)

func _test_it_moves_at_its_own_speed() -> void:
	print("speed")
	var m := _make()
	var enemy := _enemy(m)
	enemy.global_position = Vector2(200.0, 240.0)
	_player(m).global_position = Vector2(400.0, 300.0)
	enemy._physics_process(STEP)
	expect(is_equal_approx(enemy.velocity.length(), enemy.speed),
		"the enemy moves at its export speed however far away the player is")
	expect(enemy.speed < _player(m).SPEED, "slower than the player, so it can be outrun")

func _test_it_closes_the_distance() -> void:
	print("closing in")
	var m := _make()
	var enemy := _enemy(m)
	var player := _player(m)
	enemy.global_position = Vector2(100.0, 100.0)
	player.global_position = Vector2(500.0, 400.0)
	var before: float = enemy.global_position.distance_to(player.global_position)
	# Real physics frames, not hand-called ones: move_and_slide() hands the
	# movement to the physics server, which only applies it on its own step.
	# tests/frames buys the time.
	for i in 40:
		await get_tree().physics_frame
	var after: float = enemy.global_position.distance_to(player.global_position)
	expect(after < before, "chasing brings the enemy closer (%.0f px, from %.0f)" % [after, before])
	expect(after > 0.0, "without arriving on top of them in the time given")

func _test_it_stops_when_the_player_is_gone() -> void:
	print("no player")
	var m := _make()
	var enemy := _enemy(m)
	var player := _player(m)
	enemy.global_position = Vector2(200.0, 240.0)
	player.global_position = Vector2(400.0, 240.0)
	enemy._physics_process(STEP)
	var moving: Vector2 = enemy.velocity

	m.remove_child(player)
	player.free()
	enemy._physics_process(STEP)
	# Chasing a freed node would be a crash, not a bug you can walk past.
	expect(enemy.velocity == moving, "with the player gone the enemy stops rather than erroring")

func _test_the_sight_line_joins_the_two() -> void:
	print("the sight line")
	var m := _make()
	_enemy(m).global_position = Vector2(150.0, 300.0)
	_player(m).global_position = Vector2(450.0, 120.0)
	m._process(STEP)
	var line: Line2D = m.get_node("SightLine")
	expect(line.get_point_position(0) == _enemy(m).global_position, "the line starts at the enemy")
	expect(line.get_point_position(1) == _player(m).global_position, "and ends at the player")

func _test_the_readout_measures_the_gap() -> void:
	print("the readout")
	var m := _make()
	_enemy(m).global_position = Vector2(100.0, 240.0)
	_player(m).global_position = Vector2(400.0, 240.0)
	m._process(STEP)
	expect((m.get_node("DistanceLabel") as Label).text.contains("300"),
		"the label reports the distance between them")
