extends Node

var _pass := 0
var _fail := 0

func expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("  PASS: ", label)
	else:
		_fail += 1
		print("  FAIL: ", label)

func _report() -> void:
	print("--- Results: %d passed, %d failed ---" % [_pass, _fail])

func _ready() -> void:
	print("=== BT Node Tests ===")
	_test_sequence_success()
	_test_sequence_fails_on_first_failure()
	_test_selector_success_on_first()
	_test_selector_failure()
	_test_leaf_runs_callable()
	_report()

func _test_sequence_success() -> void:
	print("Test: sequence_success")
	var seq := BTNode.Sequence.new()
	seq.children.append(BTNode.Leaf.new("A", func(_c): return BTNode.Status.SUCCESS))
	seq.children.append(BTNode.Leaf.new("B", func(_c): return BTNode.Status.SUCCESS))
	seq.children.append(BTNode.Leaf.new("C", func(_c): return BTNode.Status.SUCCESS))
	var result := seq.tick({})
	expect(result == BTNode.Status.SUCCESS, "all SUCCESS -> Sequence SUCCESS")

func _test_sequence_fails_on_first_failure() -> void:
	print("Test: sequence_fails_on_first_failure")
	var call_count := 0
	var seq := BTNode.Sequence.new()
	seq.children.append(BTNode.Leaf.new("A", func(_c): return BTNode.Status.FAILURE))
	seq.children.append(BTNode.Leaf.new("B", func(_c):
		call_count += 1
		return BTNode.Status.SUCCESS))
	var result := seq.tick({})
	expect(result == BTNode.Status.FAILURE, "first FAILURE -> Sequence FAILURE")
	expect(call_count == 0, "second child not ticked after first fails")

func _test_selector_success_on_first() -> void:
	print("Test: selector_success_on_first")
	var call_count := 0
	var sel := BTNode.Selector.new()
	sel.children.append(BTNode.Leaf.new("A", func(_c): return BTNode.Status.SUCCESS))
	sel.children.append(BTNode.Leaf.new("B", func(_c):
		call_count += 1
		return BTNode.Status.SUCCESS))
	var result := sel.tick({})
	expect(result == BTNode.Status.SUCCESS, "first SUCCESS -> Selector SUCCESS")
	expect(call_count == 0, "second child not ticked after first succeeds")

func _test_selector_failure() -> void:
	print("Test: selector_failure")
	var sel := BTNode.Selector.new()
	sel.children.append(BTNode.Leaf.new("A", func(_c): return BTNode.Status.FAILURE))
	sel.children.append(BTNode.Leaf.new("B", func(_c): return BTNode.Status.FAILURE))
	sel.children.append(BTNode.Leaf.new("C", func(_c): return BTNode.Status.FAILURE))
	var result := sel.tick({})
	expect(result == BTNode.Status.FAILURE, "all FAILURE -> Selector FAILURE")

func _test_leaf_runs_callable() -> void:
	print("Test: leaf_runs_callable")
	var leaf := BTNode.Leaf.new("TestLeaf", func(_c): return BTNode.Status.SUCCESS)
	var result := leaf.tick({})
	expect(result == BTNode.Status.SUCCESS, "Leaf returns callable result SUCCESS")
	var leaf2 := BTNode.Leaf.new("TestLeaf2", func(_c): return BTNode.Status.RUNNING)
	var result2 := leaf2.tick({})
	expect(result2 == BTNode.Status.RUNNING, "Leaf returns callable result RUNNING")
