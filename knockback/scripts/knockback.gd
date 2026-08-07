## Reusable hit-recoil with invincibility frames. Tracks a decaying knockback
## `velocity` plus an i-frame timer. The owning body adds `velocity` to its own
## movement each frame and calls `update(delta)` to age both — so knockback
## layers on top of normal control without replacing it.
class_name Knockback
extends RefCounted

var impulse := 480.0      ## horizontal launch speed on hit (px/s)
var up := -260.0          ## vertical launch speed on hit (px/s, negative = up)
var decay_rate := 7.0     ## how fast the knockback eases back to zero
var iframe_time := 0.8    ## invincibility duration after a hit (s)

var velocity := Vector2.ZERO
var iframes := 0.0

func is_invincible() -> bool:
	return iframes > 0.0

## Apply a hit pushing `target` away from `source`. Returns false (and does
## nothing) if still invincible from a previous hit.
func hit(source: Vector2, target: Vector2) -> bool:
	if iframes > 0.0:
		return false
	var dir := (target - source).normalized()
	velocity = Vector2(dir.x * impulse, up)
	iframes = iframe_time
	return true

## Age the i-frame timer and decay the horizontal knockback toward zero.
func update(delta: float) -> void:
	iframes = maxf(iframes - delta, 0.0)
	velocity = velocity.lerp(Vector2.ZERO, decay_rate * delta)
