extends Node

# Drives the real DialogueTree from scripts/dialogue_tree.gd rather than a copy
# of its node lookup and choice filtering.

var _pass := 0
var _fail := 0

var _game_state: Dictionary = {
	"has_sword": false,
	"gold": 10,
	"talked_before": false,
}

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[dialogue-tree] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _ready() -> void:
	print("=== Dialogue Tree Tests ===")
	_test_start_node()
	_test_unknown_node()
	_test_condition_pass()
	_test_condition_fail()
	_test_no_condition()
	_test_traversal()
	_test_terminal_node_has_no_choices()
	_test_custom_start_node()
	_report()

func _nodes() -> Dictionary:
	return {
		"start": {
			"speaker": "Old Merchant",
			"text": "Ah, a traveler!",
			"choices": [
				{"text": "Tell me about the sword.", "condition": "", "target": "sword_intro"},
				{"text": "Show sword (requires has_sword).", "condition": "has_sword", "target": "show_sword"},
				{"text": "Buy info (requires gold >= 5).", "condition": "gold_gte_5", "target": "buy_info"},
				{"text": "Goodbye.", "condition": "", "target": "goodbye"},
			]
		},
		"sword_intro": {"speaker": "Old Merchant", "text": "The Blade of Embers!", "choices": []},
		"show_sword": {"speaker": "Old Merchant", "text": "Magnificent!", "choices": []},
		"buy_info":   {"speaker": "Old Merchant", "text": "Five gold for the location.", "choices": []},
		"goodbye":    {"speaker": "Old Merchant", "text": "Farewell.", "choices": []},
	}

func _make(start := "start") -> DialogueTree:
	return DialogueTree.new(_nodes(), start)

# DialogueTree delegates the condition check, so the game keeps its own rules.
func _is_met(condition: String) -> bool:
	match condition:
		"has_sword":  return _game_state["has_sword"]
		"gold_gte_5": return _game_state["gold"] >= 5
		_:            return false

func _test_start_node() -> void:
	print("Test: start node")
	var tree := _make()
	expect(tree.current == "start", "the tree starts on the requested node")
	expect(tree.node()["speaker"] == "Old Merchant", "node() returns the current node's data")

func _test_unknown_node() -> void:
	print("Test: unknown node")
	var tree := _make()
	tree.goto("nowhere")
	expect(tree.node().is_empty(), "an unknown id yields an empty node")
	expect(tree.available_choices(_is_met).is_empty(), "an empty node offers no choices")

func _test_condition_pass() -> void:
	print("Test: condition met")
	_game_state["gold"] = 10
	var choices := _make().available_choices(_is_met)
	var texts := choices.map(func(c: Dictionary) -> String: return c["text"])
	expect(texts.any(func(t: String) -> bool: return t.begins_with("Buy info")),
		"gold >= 5 makes the 'Buy info' choice available")

func _test_condition_fail() -> void:
	print("Test: condition not met")
	_game_state["has_sword"] = false
	_game_state["gold"] = 2
	var choices := _make().available_choices(_is_met)
	var texts := choices.map(func(c: Dictionary) -> String: return c["text"])
	expect(not texts.any(func(t: String) -> bool: return t.begins_with("Show sword")),
		"has_sword = false hides the 'Show sword' choice")
	expect(not texts.any(func(t: String) -> bool: return t.begins_with("Buy info")),
		"gold < 5 hides the 'Buy info' choice")
	expect(choices.size() == 2, "only the two unconditional choices remain")
	_game_state["gold"] = 10

func _test_no_condition() -> void:
	print("Test: unconditional choices")
	_game_state["has_sword"] = false
	_game_state["gold"] = 0
	var choices := _make().available_choices(_is_met)
	expect(choices.size() == 2, "choices with an empty condition are always shown")

func _test_traversal() -> void:
	print("Test: traversal")
	_game_state["has_sword"] = true
	_game_state["gold"] = 10
	var tree := _make()
	var choices := tree.available_choices(_is_met)
	expect(choices.size() == 4, "every choice is available once both conditions hold")
	tree.goto(choices[1]["target"])
	expect(tree.current == "show_sword", "goto follows the chosen target")
	expect(tree.node()["text"] == "Magnificent!", "the new node's text is current")

func _test_terminal_node_has_no_choices() -> void:
	print("Test: terminal node")
	var tree := _make()
	tree.goto("goodbye")
	expect(tree.available_choices(_is_met).is_empty(), "a terminal node offers no choices")

func _test_custom_start_node() -> void:
	print("Test: custom start node")
	var tree := _make("sword_intro")
	expect(tree.current == "sword_intro", "the start node is configurable")
	expect(tree.node()["text"] == "The Blade of Embers!", "and its data is loaded")
