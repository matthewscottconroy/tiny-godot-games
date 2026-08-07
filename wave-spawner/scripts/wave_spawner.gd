## Drives a horde/wave loop: an intermission countdown, then a wave, repeating
## until `max_waves` is cleared. It owns only the phase machine and per-wave
## scaling — the game listens to the signals to actually spawn and count
## enemies, and calls wave_cleared() when the current wave is defeated.
class_name WaveSpawner
extends RefCounted

signal intermission_started(wave: int, duration: float)
signal wave_started(wave: int, enemy_count: int)
signal all_waves_cleared

enum Phase { IDLE, INTERMISSION, WAVE }

var max_waves := 5
var intermission_duration := 3.0
var base_count := 3          ## enemies in wave 1
var count_per_wave := 2      ## extra enemies each subsequent wave

var wave := 0
var phase := Phase.IDLE
var timer := 0.0

## Number of enemies a given wave spawns.
func enemy_count_for(w: int) -> int:
	return base_count + (w - 1) * count_per_wave

func start() -> void:
	if phase != Phase.IDLE:
		return
	wave = 0
	_begin_intermission()

func skip_intermission() -> void:
	if phase == Phase.INTERMISSION:
		timer = 0.0

## Call when every enemy in the current wave has been defeated.
func wave_cleared() -> void:
	if phase != Phase.WAVE:
		return
	if wave >= max_waves:
		phase = Phase.IDLE
		all_waves_cleared.emit()
	else:
		_begin_intermission()

## Advance the intermission timer; starts the wave when it expires. Call once
## per frame.
func update(delta: float) -> void:
	if phase == Phase.INTERMISSION:
		timer -= delta
		if timer <= 0.0:
			phase = Phase.WAVE
			wave_started.emit(wave, enemy_count_for(wave))

func _begin_intermission() -> void:
	phase = Phase.INTERMISSION
	timer = intermission_duration
	wave += 1
	intermission_started.emit(wave, timer)
