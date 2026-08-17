extends Node

# Drives the real ScoreManager from scripts/score_manager.gd. The previous suite
# recomputed the arithmetic inline, so the component's own setter and signal
# could break without a single assertion noticing — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_starts_at_zero()
	_test_add_default_amount()
	_test_add_explicit_amount()
	_test_add_accumulates()
	_test_reset()
	_test_signal_fires_with_the_new_total()
	_test_signal_fires_on_reset()
	_test_negative_amounts()
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

# The demo registers this as an autoload; a test just instantiates it, which is
# the same object with none of the global wiring.
var _script: GDScript = load("res://scripts/score_manager.gd")

func _make() -> Node:
	var manager := Node.new()
	manager.set_script(_script)
	add_child(manager)
	return manager

func _test_starts_at_zero() -> void:
	print("initial state")
	expect(_make().score == 0, "a fresh score manager starts at zero")

func _test_add_default_amount() -> void:
	print("default award")
	var m := _make()
	m.add()
	expect(m.score == 10, "add() with no argument awards the default 10")

func _test_add_explicit_amount() -> void:
	print("explicit award")
	var m := _make()
	m.add(250)
	expect(m.score == 250, "add(250) awards exactly 250")

func _test_add_accumulates() -> void:
	print("accumulation")
	var m := _make()
	m.add(10)
	m.add(5)
	m.add(1)
	expect(m.score == 16, "awards add up rather than replacing")

func _test_reset() -> void:
	print("reset")
	var m := _make()
	m.add(999)
	m.reset()
	expect(m.score == 0, "reset returns the score to zero")

func _test_signal_fires_with_the_new_total() -> void:
	print("score_changed")
	var m := _make()
	var seen: Array[int] = []
	m.score_changed.connect(func(new_score: int) -> void: seen.append(new_score))
	m.add(10)
	m.add(15)
	# The signal must carry the running total, not the amount awarded — a UI
	# connected to it displays the score, not the delta.
	expect(seen == [10, 25], "score_changed reports the new total after each award")

func _test_signal_fires_on_reset() -> void:
	print("score_changed on reset")
	var m := _make()
	m.add(40)
	var seen: Array[int] = []
	m.score_changed.connect(func(new_score: int) -> void: seen.append(new_score))
	m.reset()
	expect(seen == [0], "reset notifies listeners so the display clears too")

func _test_negative_amounts() -> void:
	print("penalties")
	var m := _make()
	m.add(100)
	m.add(-30)
	expect(m.score == 70, "a negative award subtracts, so penalties need no extra API")
