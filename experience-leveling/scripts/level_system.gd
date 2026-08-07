## Tracks XP and levels on an exponential threshold curve. Feed it XP with
## gain(); it carries overflow across level-ups and emits signals when XP
## changes and when a level is reached. Stat rewards are the game's job —
## listen to `leveled_up` and apply them there.
class_name LevelSystem
extends RefCounted

signal xp_gained(current_xp: int, needed: int)
signal leveled_up(new_level: int)

var base_xp := 50      ## XP needed for level 1 → 2
var growth := 1.4      ## each level costs this factor more than the last
var max_level := 10

var level := 1
var xp := 0
var xp_for_next := 50

func _init() -> void:
	xp_for_next = threshold(level)

## XP required to advance FROM `lvl` to the next level.
func threshold(lvl: int) -> int:
	return int(base_xp * pow(growth, lvl - 1))

## Award XP, applying as many level-ups as the total allows (overflow carries).
func gain(amount: int) -> void:
	xp += amount
	while xp >= xp_for_next and level < max_level:
		xp -= xp_for_next
		level += 1
		xp_for_next = threshold(level)
		leveled_up.emit(level)
	xp_gained.emit(xp, xp_for_next)
