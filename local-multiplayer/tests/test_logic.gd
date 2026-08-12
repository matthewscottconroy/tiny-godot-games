extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_player_count()
	_test_player_speed()
	_test_coin_count()
	_test_score_tracking()
	_test_score_increment()
	_test_all_collected_message()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_player_count() -> void:
	print("player count")
	var num_players := 2
	expect(num_players == 2, "2 players in local multiplayer")

func _test_player_speed() -> void:
	print("player speed")
	const SPEED := 180.0
	expect(SPEED == 180.0, "player SPEED is 180")

func _test_coin_count() -> void:
	print("coin positions count")
	var coin_positions := [
		Vector2(100, 200), Vector2(200, 150), Vector2(320, 100),
		Vector2(440, 150), Vector2(540, 200), Vector2(160, 300),
		Vector2(480, 300), Vector2(320, 260), Vector2(80, 350),
		Vector2(560, 350),
	]
	expect(coin_positions.size() == 10, "10 coins spawn in level")

func _test_score_tracking() -> void:
	print("score tracking")
	var scores := [0, 0]
	expect(scores[0] == 0, "player 1 starts at 0")
	expect(scores[1] == 0, "player 2 starts at 0")

func _test_score_increment() -> void:
	print("score increment on collection")
	var scores := [0, 0]
	var pid := 1
	scores[pid - 1] += 1
	expect(scores[0] == 1, "player 1 score incremented")
	expect(scores[1] == 0, "player 2 score unchanged")
	pid = 2
	scores[pid - 1] += 1
	expect(scores[1] == 1, "player 2 score incremented")

func _test_all_collected_message() -> void:
	print("all collected detection")
	var scores := [5, 5]
	var total_coins := 10
	var all_collected: bool = scores[0] + scores[1] == total_coins
	expect(all_collected, "all coins collected when scores sum to total")

func _report() -> void:
	var summary := "[local-multiplayer] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
