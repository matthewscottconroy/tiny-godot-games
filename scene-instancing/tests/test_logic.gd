extends Node

# Drives the real spawner from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_one_coin_appears_immediately()
	_test_each_spawn_is_a_separate_instance()
	_test_coins_land_inside_the_window()
	_test_the_coins_are_scattered()
	_test_the_counter_follows_the_spawns()
	_test_a_timer_keeps_spawning()
	await _test_the_timer_fires_on_its_own()
	_test_a_coin_is_a_scene_not_a_hand_built_node()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[scene-instancing] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _spawner(_scene)

## The node that does the spawning, wherever it sits in the scene.
func _spawner(root: Node) -> Node2D:
	if root.get("count") != null and root.has_method("_spawn"):
		return root
	for child in root.get_children():
		var found := _spawner(child)
		if found:
			return found
	return null

func _coins(spawner: Node2D) -> Array[Area2D]:
	var found: Array[Area2D] = []
	for child in spawner.get_children():
		if child is Area2D:
			found.append(child)
	return found

func _label(spawner: Node2D) -> Label:
	return spawner.get_node("CountLabel")

func _test_one_coin_appears_immediately() -> void:
	print("the first coin")
	var m := _make()
	# Spawned in _ready as well as on the timer, so the demo is not empty for
	# its first second.
	expect(_coins(m).size() == 1, "a coin is there straight away")
	expect(m.count == 1, "and counted")

func _test_each_spawn_is_a_separate_instance() -> void:
	print("separate instances")
	var m := _make()
	m._spawn()
	m._spawn()
	var coins := _coins(m)
	expect(coins.size() == 3, "each spawn adds another coin")
	expect(coins[0] != coins[1] and coins[1] != coins[2], "each a node of its own")
	expect(coins[0].get_script() == coins[1].get_script(), "all built from the same scene")

func _test_coins_land_inside_the_window() -> void:
	print("placement")
	var m := _make()
	for i in 40:
		m._spawn()
	var inside := true
	for coin in _coins(m):
		if coin.position.x < 30.0 or coin.position.x > 610.0 \
				or coin.position.y < 50.0 or coin.position.y > 440.0:
			inside = false
	expect(inside, "every coin lands within the play area")

func _test_the_coins_are_scattered() -> void:
	print("scatter")
	var m := _make()
	for i in 20:
		m._spawn()
	var places := {}
	for coin in _coins(m):
		places[coin.position] = true
	expect(places.size() > 1, "coins appear in different places rather than stacking up")

func _test_the_counter_follows_the_spawns() -> void:
	print("the readout")
	var m := _make()
	m._spawn()
	m._spawn()
	expect(m.count == 3, "the count keeps up")
	expect(_label(m).text.contains("3"), "and the label shows it")

func _test_a_timer_keeps_spawning() -> void:
	print("the timer")
	var m := _make()
	var timer: Timer = null
	for child in m.get_children():
		if child is Timer:
			timer = child
	expect(timer != null, "the spawner runs on a timer")
	expect(timer != null and timer.wait_time > 0.0, "with an interval")
	expect(timer != null and not timer.is_stopped(), "and it is running")

func _test_the_timer_fires_on_its_own() -> void:
	print("waiting for a spawn")
	var m := _make()
	var before: int = m.count
	# The timer is a second, and the run has the frames for it.
	for i in 400:
		await get_tree().process_frame
		if m.count > before:
			break
	expect(m.count > before, "the timer spawns another coin without being asked")

func _test_a_coin_is_a_scene_not_a_hand_built_node() -> void:
	print("the coin scene")
	var m := _make()
	expect(ResourceLoader.exists("res://scenes/coin.tscn"), "the coin lives in its own scene file")
	var coin := _coins(m)[0]
	expect(coin.get_child_count() > 0, "and brings its own children with it")
	expect(coin.get_script() != null, "and its own script")
