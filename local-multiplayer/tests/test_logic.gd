extends Node

# Drives the real scoring from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_board_is_set_up()
	_test_the_two_players_are_told_apart()
	_test_a_coin_scores_for_whoever_took_it()
	_test_each_player_keeps_their_own_score()
	_test_a_coin_removes_itself()
	_test_something_without_a_player_id_scores_nothing()
	_test_the_readout_names_both_players()
	await _test_clearing_the_board_ends_the_game()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[local-multiplayer] %d/%d passed" % [_pass, _pass + _fail]
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
	return _scene

func _coins(m: Node2D) -> Array:
	return m.get_node("Coins").get_children()

func _players(m: Node2D) -> Array[CharacterBody2D]:
	var found: Array[CharacterBody2D] = []
	for child in m.get_children():
		if child is CharacterBody2D:
			found.append(child)
	return found

func _test_the_board_is_set_up() -> void:
	print("the board")
	var m := _make()
	expect(_coins(m).size() == m.coin_positions.size(), "a coin per listed position")
	expect(m.scores == [0, 0], "and both players on nothing")

func _test_the_two_players_are_told_apart() -> void:
	print("the players")
	var m := _make()
	var players := _players(m)
	expect(players.size() == 2, "there are two players")
	var ids := {}
	var colours := {}
	for player in players:
		ids[player.player_id] = true
		colours[player.player_color] = true
	expect(ids.size() == 2, "with different ids, so a coin knows who took it")
	expect(colours.size() == 2, "and different colours, so the humans do too")

	# Each player reads its own keys; sharing them would make one set of
	# controls move both.
	# Player one specifically, because the readout tells the humans so:
	# "P1 (WASD): 0   P2 (Arrows): 0".
	for player in players:
		if player.player_id == 1:
			expect(player.uses_wasd(), "player one is the one on WASD")
		else:
			expect(not player.uses_wasd(), "and everyone else is on the arrows")

	var one := players[0]
	expect(one.axis_from(true, false, false, false) == Vector2.RIGHT, "right on its own is right")
	expect(one.axis_from(false, true, false, false) == Vector2.LEFT, "left is left")
	expect(one.axis_from(false, false, true, false) == Vector2.DOWN, "down is down the screen")
	expect(one.axis_from(false, false, false, true) == Vector2.UP, "and up is up it")
	expect(one.axis_from(true, true, true, true) == Vector2.ZERO, "opposite keys cancel out")
	expect(one.axis_from(false, false, false, false) == Vector2.ZERO, "and nothing held is no direction")

func _test_a_coin_scores_for_whoever_took_it() -> void:
	print("scoring")
	var m := _make()
	var coin: Area2D = _coins(m)[0]
	coin.collected.emit(1)
	expect(m.scores[0] == 1, "player one's coin goes on player one's score")
	expect(m.scores[1] == 0, "and not on player two's")

func _test_each_player_keeps_their_own_score() -> void:
	print("two scores")
	var m := _make()
	var coins := _coins(m)
	coins[0].collected.emit(2)
	coins[1].collected.emit(2)
	coins[2].collected.emit(1)
	expect(m.scores[1] == 2, "player two banked two")
	expect(m.scores[0] == 1, "and player one banked one")

func _test_a_coin_removes_itself() -> void:
	print("taking a coin")
	var m := _make()
	var coin: Area2D = _coins(m)[0]
	var player := _players(m)[0]
	coin.body_entered.emit(player)
	expect(m.scores[player.player_id - 1] == 1, "walking into a coin scores it")
	expect(coin.is_queued_for_deletion(), "and the coin takes itself off the board")

func _test_something_without_a_player_id_scores_nothing() -> void:
	print("who can collect")
	var m := _make()
	var coin: Area2D = _coins(m)[0]
	var passer_by := CharacterBody2D.new()
	add_child(passer_by)
	coin.body_entered.emit(passer_by)
	expect(m.scores == [0, 0], "a body that is not a player scores for nobody")
	expect(not coin.is_queued_for_deletion(), "and the coin stays where it is")

func _test_the_readout_names_both_players() -> void:
	print("the readout")
	var m := _make()
	var label: Label = m.get_node("ScoreLabel")
	expect(label.text.contains("P1") and label.text.contains("P2"), "both players are on the board")
	_coins(m)[0].collected.emit(1)
	expect(label.text.contains("1"), "and the score follows a collection")

func _test_clearing_the_board_ends_the_game() -> void:
	print("the last coin")
	var m := _make()
	for coin in _coins(m):
		coin.collected.emit(1)
		coin.queue_free()
	# queue_free lands at the end of the frame, so the "all collected" check
	# only sees an empty board once the frame turns over.
	await get_tree().process_frame
	_coins(m)
	m._on_collected(1)
	expect((m.get_node("ScoreLabel") as Label).text.contains("All collected"),
		"an empty board is announced")
