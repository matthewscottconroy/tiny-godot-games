## Navigates a branching dialogue graph. Nodes are keyed by id; each has a
## speaker, text, and a list of choices ({text, condition, target, effect}).
## It answers "which node am I on?" and "which choices are available?",
## delegating the game-specific condition check to a Callable you pass in.
## Applying effects and mutating game state stay in your game.
class_name DialogueTree
extends RefCounted

var nodes: Dictionary = {}
var current: String = ""

func _init(dialogue_nodes: Dictionary = {}, start := "start") -> void:
	nodes = dialogue_nodes
	current = start

## The current node's data dictionary (or {} if the id is unknown).
func node() -> Dictionary:
	return nodes.get(current, {})

## Choices on the current node that are available. A choice with an empty
## condition is always shown; otherwise `is_met.call(condition)` decides.
func available_choices(is_met: Callable) -> Array:
	var out: Array = []
	for choice in node().get("choices", []):
		var cond: String = choice.get("condition", "")
		if cond == "" or is_met.call(cond):
			out.append(choice)
	return out

## Move to another node by id.
func goto(target: String) -> void:
	current = target
