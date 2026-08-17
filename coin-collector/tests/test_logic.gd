extends Node

# Drives the real scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The lesson is the signal wiring: each coin is an Area2D that emits `collected`
# and frees itself, and main.gd counts those signals. So the suite emits from
# the real coins rather than counting in a variable of its own.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_score_starts_empty()
	_test_the_total_counts_the_coins_in_the_scene()
	_test_collecting_a_coin_scores_it()
	_test_a_partial_collection_is_not_a_win()
	_test_collecting_every_coin_wins()
	await _test_touching_a_coin_collects_and_removes_it()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[coin-collector] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _label(scene: Node2D) -> String:
	return (scene.get_node("ScoreLabel") as Label).text

func _test_the_score_starts_empty() -> void:
	print("initial state")
	var m := _make()
	expect(m.score == 0, "no coins collected yet")
	expect(_label(m).contains("0 /"), "and the label says so")

func _test_the_total_counts_the_coins_in_the_scene() -> void:
	print("the total")
	var m := _make()
	var placed: int = m.get_node("Coins").get_child_count()
	expect(m.total == placed, "the total is however many coins the scene holds (%d)" % placed)
	expect(placed > 1, "and the scene actually holds some")

func _test_collecting_a_coin_scores_it() -> void:
	print("collecting")
	var m := _make()
	var coin: Area2D = m.get_node("Coins").get_child(0)
	coin.collected.emit()
	expect(m.score == 1, "the score follows the signal")
	expect(_label(m).contains("1 /"), "and the label updates with it")

func _test_a_partial_collection_is_not_a_win() -> void:
	print("part-way")
	var m := _make()
	var coins := m.get_node("Coins").get_children()
	for i in coins.size() - 1:
		coins[i].collected.emit()
	expect(m.score == m.total - 1, "one coin short")
	expect(not _label(m).contains("All collected"), "which is not a win yet")

func _test_collecting_every_coin_wins() -> void:
	print("the win")
	var m := _make()
	for coin in m.get_node("Coins").get_children():
		coin.collected.emit()
	expect(m.score == m.total, "every coin counted")
	expect(_label(m).contains("All collected"), "and the label announces it")

func _test_touching_a_coin_collects_and_removes_it() -> void:
	print("the coin itself")
	var m := _make()
	var coin: Area2D = m.get_node("Coins").get_child(0)
	var player: CharacterBody2D = m.get_node("Player")
	# What the physics engine would do on overlap.
	coin.body_entered.emit(player)
	expect(m.score == 1, "walking into a coin collects it")
	expect(coin.is_queued_for_deletion(), "and the coin removes itself")

	# queue_free() takes effect at the end of the frame, so the coin is still
	# there right now — it is gone by the next one, and cannot be collected twice.
	await get_tree().process_frame
	expect(not is_instance_valid(coin), "by the next frame the coin is gone")
	expect(m.get_node("Coins").get_child_count() == m.total - 1,
		"leaving one fewer coin in the scene")
	expect(m.score == 1, "and the score is unchanged by the removal")
