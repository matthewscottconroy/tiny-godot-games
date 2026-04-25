extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_score_starts_at_zero()
	test_score_increments_on_collect()
	test_all_collected_detection()
	test_partial_collection_not_complete()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[coin-collector] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

# Replicate the scoring logic from main.gd
class ScoreSim:
	var score := 0
	var total := 0

	func init(coin_count: int) -> void:
		score = 0
		total = coin_count

	func collect_one() -> void:
		score += 1

	func is_complete() -> bool:
		return score == total

	func label_text() -> String:
		var base := "Coins: %d / %d" % [score, total]
		return base + "  — All collected!" if is_complete() else base

# --- tests ---

func test_score_starts_at_zero() -> void:
	var sim := ScoreSim.new()
	sim.init(7)
	expect(sim.score == 0, "score starts at 0")
	expect(sim.total == 7, "total is 7")

func test_score_increments_on_collect() -> void:
	var sim := ScoreSim.new()
	sim.init(5)
	sim.collect_one()
	expect(sim.score == 1, "score is 1 after one collection")
	sim.collect_one()
	expect(sim.score == 2, "score is 2 after two collections")

func test_all_collected_detection() -> void:
	var sim := ScoreSim.new()
	sim.init(3)
	sim.collect_one()
	sim.collect_one()
	expect(not sim.is_complete(), "not complete after 2/3")
	sim.collect_one()
	expect(sim.is_complete(), "complete after 3/3")

func test_partial_collection_not_complete() -> void:
	var sim := ScoreSim.new()
	sim.init(7)
	for _i in 6:
		sim.collect_one()
	expect(not sim.is_complete(), "6/7 is not complete")
	expect(sim.label_text().contains("6 / 7"), "label shows 6 / 7")
