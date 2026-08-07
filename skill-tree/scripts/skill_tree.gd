## Manages a graph of prerequisite-gated skills and a pool of skill points.
## Each skill is a dictionary: {id, name, desc, pos, prereqs: Array[int],
## unlocked: bool, cost: int, ...}. It owns the unlock *rules* (enough points,
## all prerequisites unlocked, not already owned); rendering and hit-testing are
## the caller's job.
class_name SkillTree
extends RefCounted

signal skill_unlocked(index: int)

var skills: Array = []
var points := 0

func _init(skill_defs: Array = [], starting_points := 0) -> void:
	skills = skill_defs
	points = starting_points

## Can the skill at `index` be unlocked right now?
func can_unlock(index: int) -> bool:
	if index < 0 or index >= skills.size():
		return false
	var s = skills[index]
	if s.unlocked or points < s.cost:
		return false
	for prereq_id in s.prereqs:
		if not skills[prereq_id].unlocked:
			return false
	return true

## Unlock the skill at `index` if allowed, spending its cost. Returns success.
func unlock(index: int) -> bool:
	if not can_unlock(index):
		return false
	skills[index].unlocked = true
	points -= skills[index].cost
	skill_unlocked.emit(index)
	return true

## Relock everything and reset the point pool.
func reset(starting_points: int) -> void:
	for s in skills:
		s.unlocked = false
	points = starting_points
