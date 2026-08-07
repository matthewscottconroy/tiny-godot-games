## Tracks a set of objective-based quests. The game reports progress with
## set_progress(id, count); the system clamps to the target, marks quests
## complete, and emits signals — including `all_completed` — that a HUD or game
## flow can react to. Quest definitions are plain dictionaries, so any objective
## type (kill / collect / reach / …) works without subclassing.
class_name QuestSystem
extends RefCounted

signal quest_completed(id: String)
signal all_completed

## Each quest: {id, title, description, target_count, current_count, completed, reward_xp, ...}
var quests: Array = []

func _init(quest_defs: Array = []) -> void:
	quests = quest_defs

func get_quest(id: String) -> Dictionary:
	for q in quests:
		if q.id == id:
			return q
	return {}

## Report progress toward a quest. Clamps to the target and fires the
## completion signals the first time the target is reached.
func set_progress(id: String, count: int) -> void:
	var q := get_quest(id)
	if q.is_empty() or q.completed:
		return
	q.current_count = mini(count, q.target_count)
	if q.current_count >= q.target_count:
		q.completed = true
		quest_completed.emit(id)
		if is_all_completed():
			all_completed.emit()

func is_all_completed() -> bool:
	for q in quests:
		if not q.completed:
			return false
	return true
