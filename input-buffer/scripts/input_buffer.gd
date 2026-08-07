## A press queue for cooldown-gated actions. Call press() when the button is hit
## (even mid-cooldown); each frame call update(delta) then consume() — which
## returns true once, the moment a queued press is allowed to fire. This is the
## classic "the attack still comes out even if you pressed slightly early" trick.
class_name InputBuffer
extends RefCounted

var buffer_window := 0.18   ## how long an early press stays queued (s)
var cooldown_time := 0.5    ## action cooldown after firing (s)

var _buffer := 0.0
var _cooldown := 0.0

## Queue a press. Fires next frame if ready; otherwise remembered for up to
## `buffer_window` seconds.
func press() -> void:
	_buffer = buffer_window

## Age the buffer and cooldown timers. Call once per frame.
func update(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_buffer = maxf(_buffer - delta, 0.0)

## True exactly once when a queued press may fire (cooldown clear); starts the
## cooldown as a side effect.
func consume() -> bool:
	if _buffer > 0.0 and _cooldown == 0.0:
		_buffer = 0.0
		_cooldown = cooldown_time
		return true
	return false

func cooldown_left() -> float:
	return _cooldown

func buffer_left() -> float:
	return _buffer

func cooldown_ratio() -> float:   ## 0..1, for a cooldown bar
	return _cooldown / cooldown_time

func buffer_ratio() -> float:     ## 0..1, for a buffer-window bar
	return _buffer / buffer_window
