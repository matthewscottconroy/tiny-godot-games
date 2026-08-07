## Manages a set of timed, stacking status effects. You supply a `catalog` of
## effect definitions; `apply()` starts one, and `tick(delta)` ages them all and
## returns the combined per-frame result (damage to deal, movement multiplier).
## The stack is pure data — it never touches the scene — so it drops onto any
## character, enemy, or destructible.
class_name StatusEffectStack
extends RefCounted

signal effect_applied(effect: String)
signal effect_expired(effect: String)

## effect name -> definition, e.g. {"dps": 10.0, "slow": 1.0, "duration": 5.0}.
## Extra keys (colour, icon, …) are ignored here and read by the caller.
var catalog: Dictionary = {}

var _remaining: Dictionary = {}   # effect name -> seconds left

func _init(effect_catalog: Dictionary = {}) -> void:
	catalog = effect_catalog

## Start (or refresh) an effect, resetting its timer to the catalog duration.
func apply(effect: String) -> void:
	_remaining[effect] = catalog[effect]["duration"]
	effect_applied.emit(effect)

## Age every active effect. Returns {"damage": float, "slow": float}: total
## damage to apply this frame and the strongest (smallest) movement multiplier.
func tick(delta: float) -> Dictionary:
	var damage := 0.0
	var slow := 1.0
	var expired: Array = []
	for effect in _remaining:
		_remaining[effect] -= delta
		var cfg: Dictionary = catalog[effect]
		damage += cfg.get("dps", 0.0) * delta
		slow = minf(slow, cfg.get("slow", 1.0))
		if _remaining[effect] <= 0.0:
			expired.append(effect)
	for effect in expired:
		_remaining.erase(effect)
		effect_expired.emit(effect)
	return {"damage": damage, "slow": slow}

## Names of the currently-active effects.
func active() -> Array:
	return _remaining.keys()

## Seconds left on `effect`, or 0 if it isn't active.
func time_left(effect: String) -> float:
	return _remaining.get(effect, 0.0)
