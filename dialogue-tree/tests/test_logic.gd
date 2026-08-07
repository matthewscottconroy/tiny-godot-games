extends Node

var _pass := 0
var _fail := 0

# Minimal duplicate of the dialogue and condition logic for isolated testing
var _game_state: Dictionary = {
	"has_sword": false,
	"gold": 10,
	"talked_before": false
}

var _dialogue: Dictionary = {}

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
	_build_dialogue()
	print("=== Dialogue Tree Tests ===")
	_test_node_exists()
	_test_condition_pass()
	_test_condition_fail()
	_test_no_condition()
	_test_traversal()
	_report()

func _build_dialogue() -> void:
	_dialogue = {
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
		"sword_intro": {
			"speaker": "Old Merchant",
			"text": "The Blade of Embers!",
			"choices": []
		},
		"show_sword": {
			"speaker": "Old Merchant",
			"text": "Magnificent!",
			"choices": []
		},
		"buy_info": {
			"speaker": "Old Merchant",
			"text": "Five gold for the location.",
			"choices": []
		},
		"goodbye": {
			"speaker": "Old Merchant",
			"text": "Farewell.",
			"choices": []
		},
	}

func _get_choices_for(node_id: String, state: Dictionary) -> Array:
	var node = _dialogue.get(node_id, {})
	var all_choices: Array = node.get("choices", [])
	var result: Array = []
	for choice in all_choices:
		var cond: String = choice.get("condition", "")
		if cond == "":
			result.append(choice)
		elif cond == "gold_gte_5":
			if state.get("gold", 0) >= 5:
				result.append(choice)
		elif state.get(cond, false):
			result.append(choice)
	return result

func _test_node_exists() -> void:
	print("Test: node_exists")
	expect(_dialogue.has("start"), "'start' node exists in dialogue dict")
	expect(_dialogue.has("sword_intro"), "'sword_intro' node exists in dialogue dict")

func _test_condition_pass() -> void:
	print("Test: condition_pass")
	var state := {"has_sword": true, "gold": 10}
	var choices := _get_choices_for("start", state)
	var targets: Array = []
	for c in choices:
		targets.append(c.get("target", ""))
	expect(targets.has("show_sword"), "has_sword=true -> show_sword choice available")

func _test_condition_fail() -> void:
	print("Test: condition_fail")
	var state := {"has_sword": false, "gold": 10}
	var choices := _get_choices_for("start", state)
	var targets: Array = []
	for c in choices:
		targets.append(c.get("target", ""))
	expect(not targets.has("show_sword"), "has_sword=false -> show_sword choice NOT available")

func _test_no_condition() -> void:
	print("Test: no_condition")
	var state := {"has_sword": false, "gold": 0}
	var choices := _get_choices_for("start", state)
	var targets: Array = []
	for c in choices:
		targets.append(c.get("target", ""))
	expect(targets.has("sword_intro"), "no-condition choice always available")
	expect(targets.has("goodbye"), "no-condition goodbye always available")

func _test_traversal() -> void:
	print("Test: traversal")
	var state := {"has_sword": false, "gold": 10}
	var choices := _get_choices_for("start", state)
	expect(choices.size() > 0, "start node has available choices")
	var first_target: String = choices[0].get("target", "")
	expect(first_target == "sword_intro", "first choice from start leads to sword_intro")
	expect(_dialogue.has(first_target), "target node exists in dialogue")
