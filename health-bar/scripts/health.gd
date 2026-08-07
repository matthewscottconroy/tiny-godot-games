## A reusable hit-point model. Holds hp/max_hp and emits signals on change and
## death — it carries no UI. A view (progress bar, label, sprite tint) connects
## to `health_changed`; game logic connects to `died`.
class_name Health
extends Node

signal health_changed(hp: int, max_hp: int)
signal died

@export var max_hp := 100

var hp: int

func _ready() -> void:
	hp = max_hp

## Deal `amount` damage. Ignored once dead (hp == 0).
func damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	health_changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()

## Restore `amount` HP up to max. Can revive from 0.
func heal(amount: int) -> void:
	if hp >= max_hp:
		return
	hp = mini(max_hp, hp + amount)
	health_changed.emit(hp, max_hp)
