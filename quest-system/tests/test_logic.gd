extends Node

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
	_test_all_complete()
	_test_no_complete_partial()
	_report()

func _make_quests() -> Array:
	return [
		{"id": "kill",    "type": "kill",    "target_count": 5, "current_count": 0, "completed": false, "reward_xp": 100},
		{"id": "collect", "type": "collect", "target_count": 3, "current_count": 0, "completed": false, "reward_xp": 75},
		{"id": "reach",   "type": "reach",   "target_count": 1, "current_count": 0, "completed": false, "reward_xp": 50},
	]

func _make_enemies(alive_count: int, dead_count: int) -> Array:
	var result: Array = []
	for i in range(alive_count):
		result.append({"pos": Vector2(i * 30, 100), "alive": true})
	for i in range(dead_count):
		result.append({"pos": Vector2(i * 30, 200), "alive": false})
	return result

func _make_coins(collected_count: int, uncollected_count: int) -> Array:
	var result: Array = []
	for i in range(collected_count):
		result.append({"pos": Vector2(i * 40, 100), "collected": true})
	for i in range(uncollected_count):
		result.append({"pos": Vector2(i * 40, 200), "collected": false})
	return result

func _update_quest_progress(quests: Array, enemies: Array, coins: Array, player_pos: Vector2, beacon_pos: Vector2) -> void:
	# Kill quest
	var kill_quest = quests[0]
	var dead_count := 0
	for e in enemies:
		if not e.alive:
			dead_count += 1
	kill_quest.current_count = dead_count
	if kill_quest.current_count >= kill_quest.target_count:
		kill_quest.completed = true

	# Collect quest
	var collect_quest = quests[1]
	var collected := 0
	for c in coins:
		if c.collected:
			collected += 1
	collect_quest.current_count = collected
	if collect_quest.current_count >= collect_quest.target_count:
		collect_quest.completed = true

	# Reach quest
	var reach_quest = quests[2]
	if player_pos.distance_to(beacon_pos) <= 30.0:
		reach_quest.current_count = 1
		reach_quest.completed = true

func _test_kill_progress() -> void:
	print("Test: kill_progress")
	var quests := _make_quests()
	var enemies := _make_enemies(2, 3)
	var coins := _make_coins(0, 3)
	_update_quest_progress(quests, enemies, coins, Vector2(0, 0), Vector2(9999, 9999))
	expect(quests[0].current_count == 3, "3 of 5 enemies dead -> kill quest current_count=3")
	expect(not quests[0].completed, "kill quest not yet completed (3 < 5)")

func _test_collect_progress() -> void:
	print("Test: collect_progress")
	var quests := _make_quests()
	var enemies := _make_enemies(5, 0)
	var coins := _make_coins(2, 1)
	_update_quest_progress(quests, enemies, coins, Vector2(0, 0), Vector2(9999, 9999))
	expect(quests[1].current_count == 2, "2 of 3 coins collected -> collect quest current_count=2")
	expect(not quests[1].completed, "collect quest not yet completed (2 < 3)")

func _test_quest_completes() -> void:
	print("Test: quest_completes")
	var quests := _make_quests()
	var enemies := _make_enemies(0, 5)
	var coins := _make_coins(3, 0)
	_update_quest_progress(quests, enemies, coins, Vector2(0, 0), Vector2(9999, 9999))
	expect(quests[0].completed, "5 dead -> kill quest completed")
	expect(quests[1].completed, "3 collected -> collect quest completed")

func _test_all_complete() -> void:
	print("Test: all_complete")
	var quests := _make_quests()
	var enemies := _make_enemies(0, 5)
	var coins := _make_coins(3, 0)
	var beacon_pos := Vector2(100, 100)
	var player_pos := Vector2(100, 100)
	_update_quest_progress(quests, enemies, coins, player_pos, beacon_pos)
	var all_done := true
	for q in quests:
		if not q.completed:
			all_done = false
			break
	expect(all_done, "all 3 quests completed -> all_complete=true")

func _test_no_complete_partial() -> void:
	print("Test: no_complete_partial")
	var quests := _make_quests()
	var enemies := _make_enemies(0, 5)
	var coins := _make_coins(3, 0)
	# Don't reach beacon
	_update_quest_progress(quests, enemies, coins, Vector2(0, 0), Vector2(9999, 9999))
	var all_done := true
	for q in quests:
		if not q.completed:
			all_done = false
			break
	expect(not all_done, "only 2 quests done (reach incomplete) -> all_complete=false")
