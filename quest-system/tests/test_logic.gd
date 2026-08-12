extends Node

# Drives the real QuestSystem from scripts/quest_system.gd rather than a copy of
# its progress bookkeeping, so clamping and the signals are covered too.

var _pass := 0
var _fail := 0

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[quest-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _ready() -> void:
	print("=== Quest System Tests ===")
	_test_kill_progress()
	_test_collect_progress()
	_test_quest_completes()
	_test_progress_clamps_to_target()
	_test_completed_quest_ignores_further_progress()
	_test_unknown_id_is_ignored()
	_test_all_complete()
	_test_no_complete_partial()
	_test_signals()
	_report()

func _make() -> QuestSystem:
	return QuestSystem.new([
		{"id": "kill",    "type": "kill",    "target_count": 5, "current_count": 0, "completed": false, "reward_xp": 100},
		{"id": "collect", "type": "collect", "target_count": 3, "current_count": 0, "completed": false, "reward_xp": 75},
		{"id": "reach",   "type": "reach",   "target_count": 1, "current_count": 0, "completed": false, "reward_xp": 50},
	])

func _test_kill_progress() -> void:
	print("Test: kill_progress")
	var qs := _make()
	qs.set_progress("kill", 3)
	expect(qs.get_quest("kill").current_count == 3, "3 of 5 enemies dead -> current_count=3")
	expect(not qs.get_quest("kill").completed, "kill quest not yet completed (3 < 5)")

func _test_collect_progress() -> void:
	print("Test: collect_progress")
	var qs := _make()
	qs.set_progress("collect", 2)
	expect(qs.get_quest("collect").current_count == 2, "2 of 3 coins collected -> current_count=2")
	expect(not qs.get_quest("collect").completed, "collect quest not yet completed (2 < 3)")

func _test_quest_completes() -> void:
	print("Test: quest_completes")
	var qs := _make()
	qs.set_progress("kill", 5)
	qs.set_progress("collect", 3)
	expect(qs.get_quest("kill").completed, "5 dead -> kill quest completed")
	expect(qs.get_quest("collect").completed, "3 collected -> collect quest completed")

func _test_progress_clamps_to_target() -> void:
	print("Test: progress clamps to the target")
	var qs := _make()
	qs.set_progress("kill", 99)
	expect(qs.get_quest("kill").current_count == 5, "overshooting the target clamps to it")

func _test_completed_quest_ignores_further_progress() -> void:
	print("Test: a completed quest stops tracking")
	var qs := _make()
	qs.set_progress("collect", 3)
	qs.set_progress("collect", 1)
	expect(qs.get_quest("collect").current_count == 3, "progress cannot go backwards once complete")
	expect(qs.get_quest("collect").completed, "the quest stays completed")

func _test_unknown_id_is_ignored() -> void:
	print("Test: unknown quest ids")
	var qs := _make()
	expect(qs.get_quest("nope").is_empty(), "get_quest on an unknown id returns an empty dictionary")
	qs.set_progress("nope", 1)   # must not raise
	expect(not qs.is_all_completed(), "reporting progress for an unknown id changes nothing")

func _test_all_complete() -> void:
	print("Test: all_complete")
	var qs := _make()
	qs.set_progress("kill", 5)
	qs.set_progress("collect", 3)
	qs.set_progress("reach", 1)
	expect(qs.is_all_completed(), "all 3 quests completed -> is_all_completed()")

func _test_no_complete_partial() -> void:
	print("Test: no_complete_partial")
	var qs := _make()
	qs.set_progress("kill", 5)
	qs.set_progress("collect", 3)
	expect(not qs.is_all_completed(), "only 2 quests done (reach incomplete) -> not all complete")

func _test_signals() -> void:
	print("Test: signals")
	var qs := _make()
	var completed: Array[String] = []
	var all_done := {"fired": 0}
	qs.quest_completed.connect(func(id: String) -> void: completed.append(id))
	qs.all_completed.connect(func() -> void: all_done["fired"] += 1)

	qs.set_progress("kill", 4)
	expect(completed.is_empty(), "quest_completed does not fire on partial progress")
	qs.set_progress("kill", 5)
	expect(completed == ["kill"], "quest_completed fires with the quest id")
	expect(all_done["fired"] == 0, "all_completed waits for every quest")

	qs.set_progress("collect", 3)
	qs.set_progress("reach", 1)
	expect(all_done["fired"] == 1, "all_completed fires once when the last quest lands")
