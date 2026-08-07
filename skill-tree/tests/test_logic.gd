extends Node

var _pass := 0
var _fail := 0

var _skill_points: int = 3
var _skills: Array = []

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
	_test_multi_prereq()
	_report()

func _make_skills() -> Array:
	return [
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
	]

func _can_unlock(skills: Array, points: int, skill_idx: int) -> bool:
	if skill_idx < 0 or skill_idx >= skills.size():
		return false
	var skill = skills[skill_idx]
	if skill.unlocked:
		return false
	if points < skill.cost:
		return false
	for prereq_id in skill.prereqs:
		if not skills[prereq_id].unlocked:
			return false
	return true

func _test_can_unlock_no_prereqs() -> void:
	print("Test: can_unlock_no_prereqs")
	var skills := _make_skills()
	# Skill 0 has no prereqs, cost=1, points=3
	expect(_can_unlock(skills, 3, 0), "Skill 0 (no prereqs, points=3) can be unlocked")

func _test_cannot_unlock_prereq_locked() -> void:
	print("Test: cannot_unlock_prereq_locked")
	var skills := _make_skills()
	# Skill 1 requires skill 0 (unlocked=false)
	expect(not _can_unlock(skills, 3, 1), "Skill 1 (prereq 0 locked) cannot be unlocked")

func _test_cannot_unlock_no_points() -> void:
	print("Test: cannot_unlock_no_points")
	var skills := _make_skills()
	skills[0].unlocked = true   # meet prereq for skill 1
	# 0 skill points
	expect(not _can_unlock(skills, 0, 1), "Skill 1 (valid prereqs but 0 points) cannot be unlocked")

func _test_unlock_deducts_points() -> void:
	print("Test: unlock_deducts_points")
	var skills := _make_skills()
	var points := 3
	# Unlock skill 0 (cost=1)
	expect(_can_unlock(skills, points, 0), "Skill 0 can be unlocked before deduction")
	skills[0].unlocked = true
	points -= skills[0].cost
	expect(points == 2, "After unlocking cost=1 skill, points decreased from 3 to 2")

func _test_multi_prereq() -> void:
	print("Test: multi_prereq")
	var skills := _make_skills()
	# Skill 7 (Combo) requires both skill 1 AND skill 3
	skills[0].unlocked = true

	# Only skill 1 unlocked, not 3
	skills[1].unlocked = true
	expect(not _can_unlock(skills, 5, 7), "Combo: only prereq 1 met (not 3) -> cannot unlock")

	# Now also unlock skill 3
	skills[3].unlocked = true
	expect(_can_unlock(skills, 5, 7), "Combo: both prereqs 1 and 3 met -> can unlock")

	# Not enough points (cost=2, points=1)
	expect(not _can_unlock(skills, 1, 7), "Combo: prereqs met but cost=2, points=1 -> cannot unlock")
