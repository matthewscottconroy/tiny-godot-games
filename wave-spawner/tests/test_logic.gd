extends Node

# Drives the real WaveSpawner from scripts/wave_spawner.gd rather than restating
# its scaling formulas, so the phase machine and signals are covered too.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_starts_in_idle()
	_test_start_begins_intermission()
	_test_enemy_count_per_wave()
	_test_intermission_expires_into_wave()
	_test_skip_intermission()
	_test_wave_cleared_advances()
	_test_all_waves_cleared()
	_test_wave_cleared_ignored_outside_wave_phase()
	_test_signals()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _make() -> WaveSpawner:
	var spawner := WaveSpawner.new()
	spawner.max_waves = 5
	spawner.intermission_duration = 3.0
	spawner.base_count = 3
	spawner.count_per_wave = 2
	return spawner

# Run the intermission down until the wave starts.
func _advance_to_wave(spawner: WaveSpawner) -> void:
	var guard := 0
	while spawner.phase == WaveSpawner.Phase.INTERMISSION and guard < 1000:
		spawner.update(0.1)
		guard += 1

func _test_starts_in_idle() -> void:
	print("spawner starts idle")
	var s := _make()
	expect(s.phase == WaveSpawner.Phase.IDLE, "phase is IDLE before start()")
	expect(s.wave == 0, "no wave has begun yet")

func _test_start_begins_intermission() -> void:
	print("start() begins the first intermission")
	var s := _make()
	s.start()
	expect(s.phase == WaveSpawner.Phase.INTERMISSION, "phase is INTERMISSION after start()")
	expect(s.wave == 1, "wave counter moves to 1")
	expect_near(s.timer, 3.0, "intermission is 3.0s")
	s.start()   # a second start() must not restart the run
	expect(s.wave == 1, "start() is ignored unless the spawner is idle")

func _test_enemy_count_per_wave() -> void:
	print("enemy count formula: base_count + (wave-1) * count_per_wave")
	var s := _make()
	for w in range(1, 6):
		var expected: int = [3, 5, 7, 9, 11][w - 1]
		expect(s.enemy_count_for(w) == expected, "wave %d has %d enemies" % [w, expected])

func _test_intermission_expires_into_wave() -> void:
	print("the intermission timer starts the wave")
	var s := _make()
	s.start()
	s.update(2.9)
	expect(s.phase == WaveSpawner.Phase.INTERMISSION, "still in intermission just before the timer ends")
	s.update(0.2)
	expect(s.phase == WaveSpawner.Phase.WAVE, "phase flips to WAVE when the timer expires")

func _test_skip_intermission() -> void:
	print("skip_intermission()")
	var s := _make()
	s.start()
	s.skip_intermission()
	expect_near(s.timer, 0.0, "skipping zeroes the timer")
	s.update(0.016)
	expect(s.phase == WaveSpawner.Phase.WAVE, "the wave starts on the next update")
	s.skip_intermission()   # no-op mid-wave
	expect(s.phase == WaveSpawner.Phase.WAVE, "skip_intermission does nothing outside an intermission")

func _test_wave_cleared_advances() -> void:
	print("wave_cleared() advances to the next intermission")
	var s := _make()
	s.start()
	_advance_to_wave(s)
	s.wave_cleared()
	expect(s.phase == WaveSpawner.Phase.INTERMISSION, "clearing a wave returns to intermission")
	expect(s.wave == 2, "the wave counter advances")

func _test_all_waves_cleared() -> void:
	print("clearing the last wave ends the run")
	var s := _make()
	s.start()
	for i in s.max_waves:
		_advance_to_wave(s)
		s.wave_cleared()
	expect(s.wave == 5, "the run stops at max_waves")
	expect(s.phase == WaveSpawner.Phase.IDLE, "the spawner returns to IDLE when everything is cleared")

func _test_wave_cleared_ignored_outside_wave_phase() -> void:
	print("wave_cleared() outside a wave is ignored")
	var s := _make()
	s.start()   # INTERMISSION
	s.wave_cleared()
	expect(s.phase == WaveSpawner.Phase.INTERMISSION, "phase is unchanged")
	expect(s.wave == 1, "the wave counter does not skip ahead")

func _test_signals() -> void:
	print("signals")
	var s := _make()
	var events: Array[String] = []
	s.intermission_started.connect(func(wave: int, _d: float) -> void:
		events.append("intermission:%d" % wave))
	s.wave_started.connect(func(wave: int, count: int) -> void:
		events.append("wave:%d:%d" % [wave, count]))
	s.all_waves_cleared.connect(func() -> void: events.append("done"))

	s.start()
	_advance_to_wave(s)
	expect(events == ["intermission:1", "wave:1:3"],
		"intermission_started then wave_started, carrying the wave and its enemy count")

	for i in s.max_waves:
		s.wave_cleared()
		_advance_to_wave(s)
	expect(events.back() == "done", "all_waves_cleared fires after the final wave")

func _report() -> void:
	var summary := "[wave-spawner] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
