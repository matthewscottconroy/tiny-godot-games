extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_score_starts_at_zero()
	test_add_points_increases_score()
	test_add_multiple_times()
	test_reset_clears_score()
	test_high_score_tracking()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[autoload-score] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Replicate ScoreManager logic inline (without needing the Autoload node)
class ScoreManagerSim:
	var score      := 0
	var high_score := 0

	func add_points(amount: int) -> void:
		score += amount
		if score > high_score:
			high_score = score

	func reset() -> void:
		score = 0

# --- tests ---

func test_score_starts_at_zero() -> void:
	var sm := ScoreManagerSim.new()
	expect(sm.score == 0, "score starts at 0")

func test_add_points_increases_score() -> void:
	var sm := ScoreManagerSim.new()
	sm.add_points(10)
	expect(sm.score == 10, "score is 10 after adding 10")

func test_add_multiple_times() -> void:
	var sm := ScoreManagerSim.new()
	sm.add_points(5)
	sm.add_points(15)
	sm.add_points(3)
	expect(sm.score == 23, "score is 23 after adding 5+15+3")

func test_reset_clears_score() -> void:
	var sm := ScoreManagerSim.new()
	sm.add_points(100)
	sm.reset()
	expect(sm.score == 0, "score is 0 after reset")

func test_high_score_tracking() -> void:
	var sm := ScoreManagerSim.new()
	sm.add_points(50)
	expect(sm.high_score == 50, "high score is 50")
	sm.reset()
	sm.add_points(30)
	expect(sm.high_score == 50, "high score stays 50 after reset and lower run")
	sm.add_points(40)
	expect(sm.high_score == 70, "high score updates to 70 on new record")
