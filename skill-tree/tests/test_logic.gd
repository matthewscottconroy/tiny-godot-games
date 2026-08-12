extends Node

# Drives the real SkillTree from scripts/skill_tree.gd rather than a copy of its
# unlock rules, so point spending and the signal are covered too.

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
	var summary := "[skill-tree] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _ready() -> void:
	print("=== Skill Tree Tests ===")
	_test_can_unlock_no_prereqs()
	_test_cannot_unlock_prereq_locked()
	_test_cannot_unlock_no_points()
	_test_unlock_deducts_points()
	_test_cannot_unlock_twice()
	_test_out_of_range_index()
	_test_multi_prereq()
	_test_reset()
	_test_signal()
	_report()

func _make(points := 3) -> SkillTree:
	return SkillTree.new([
		{"id": 0, "name": "Strength I",  "prereqs": [],     "unlocked": false, "cost": 1},
		{"id": 1, "name": "Strength II", "prereqs": [0],    "unlocked": false, "cost": 1},
		{"id": 2, "name": "Str. III",    "prereqs": [1],    "unlocked": false, "cost": 1},
		{"id": 3, "name": "Speed I",     "prereqs": [0],    "unlocked": false, "cost": 1},
		{"id": 4, "name": "Speed II",    "prereqs": [3],    "unlocked": false, "cost": 1},
		{"id": 5, "name": "Magic I",     "prereqs": [0],    "unlocked": false, "cost": 1},
		{"id": 6, "name": "Magic II",    "prereqs": [5],    "unlocked": false, "cost": 1},
		{"id": 7, "name": "Combo",       "prereqs": [1, 3], "unlocked": false, "cost": 2},
		{"id": 8, "name": "Ultimate",    "prereqs": [7],    "unlocked": false, "cost": 2},
		{"id": 9, "name": "Passive",     "prereqs": [0],    "unlocked": false, "cost": 1},
	], points)

func _test_can_unlock_no_prereqs() -> void:
	print("Test: can_unlock_no_prereqs")
	expect(_make(3).can_unlock(0), "Skill 0 (no prereqs, points=3) can be unlocked")

func _test_cannot_unlock_prereq_locked() -> void:
	print("Test: cannot_unlock_prereq_locked")
	expect(not _make(3).can_unlock(1), "Skill 1 (prereq 0 locked) cannot be unlocked")

func _test_cannot_unlock_no_points() -> void:
	print("Test: cannot_unlock_no_points")
	var tree := _make(1)
	tree.unlock(0)   # spends the only point
	expect(tree.points == 0, "the starting point was spent")
	expect(not tree.can_unlock(1), "Skill 1 (valid prereqs but 0 points) cannot be unlocked")

func _test_unlock_deducts_points() -> void:
	print("Test: unlock_deducts_points")
	var tree := _make(3)
	expect(tree.unlock(0), "unlock succeeds and returns true")
	expect(tree.skills[0].unlocked, "the skill is marked unlocked")
	expect(tree.points == 2, "after unlocking a cost=1 skill, points went from 3 to 2")

func _test_cannot_unlock_twice() -> void:
	print("Test: cannot_unlock_twice")
	var tree := _make(3)
	tree.unlock(0)
	expect(not tree.can_unlock(0), "an unlocked skill cannot be unlocked again")
	expect(not tree.unlock(0), "a repeat unlock returns false")
	expect(tree.points == 2, "and does not spend more points")

func _test_out_of_range_index() -> void:
	print("Test: out_of_range_index")
	var tree := _make(3)
	expect(not tree.can_unlock(-1), "a negative index cannot be unlocked")
	expect(not tree.can_unlock(999), "an index past the end cannot be unlocked")

func _test_multi_prereq() -> void:
	print("Test: multi_prereq")
	var tree := _make(5)
	tree.unlock(0)
	tree.unlock(1)
	expect(not tree.can_unlock(7), "Combo: only prereq 1 met (not 3) -> cannot unlock")
	tree.unlock(3)
	expect(tree.can_unlock(7), "Combo: both prereqs 1 and 3 met -> can unlock")

	var poor := _make(5)
	poor.unlock(0)
	poor.unlock(1)
	poor.unlock(3)
	poor.points = 1
	expect(not poor.can_unlock(7), "Combo: prereqs met but cost=2, points=1 -> cannot unlock")

func _test_reset() -> void:
	print("Test: reset")
	var tree := _make(3)
	tree.unlock(0)
	tree.unlock(1)
	tree.reset(4)
	expect(not tree.skills[0].unlocked and not tree.skills[1].unlocked, "reset relocks every skill")
	expect(tree.points == 4, "reset restores the point pool")

func _test_signal() -> void:
	print("Test: skill_unlocked signal")
	var tree := _make(3)
	var unlocked: Array[int] = []
	tree.skill_unlocked.connect(func(index: int) -> void: unlocked.append(index))
	tree.unlock(0)
	tree.unlock(99)    # rejected
	expect(unlocked == [0], "skill_unlocked fires only for successful unlocks")
