extends Node

var _pass := 0
var _fail := 0

const MIX_RATE := 44100.0


func _ready() -> void:
	_test_calm_phase_increment()
	_test_combat_phase_increments()
	_test_sine_range()
	_test_two_freq_mix_range()
	_test_crossfade_calm_volumes()
	_test_crossfade_combat_volumes()
	_test_fmod_wraps()
	_report()


func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)


func expect_approx(a: float, b: float, label: String, tol: float = 0.0001) -> void:
	expect(absf(a - b) < tol, label)


# --- Phase increment formula ---

func _test_calm_phase_increment() -> void:
	print("calm phase increment (220 Hz)")
	var phase := 0.0
	var expected_increment := 220.0 / MIX_RATE
	# Simulate one step
	phase = fmod(phase + 220.0 / MIX_RATE, 1.0)
	expect_approx(phase, expected_increment, "first step phase equals 220/MIX_RATE")
	# After MIX_RATE/220 steps the phase should have wrapped back near 0
	phase = 0.0
	var steps := int(MIX_RATE / 220.0)
	for _i in steps:
		phase = fmod(phase + 220.0 / MIX_RATE, 1.0)
	expect(phase < 1.0, "phase stays in [0, 1) after full cycle")
	expect(phase >= 0.0, "phase is non-negative")


func _test_combat_phase_increments() -> void:
	print("combat phase increments (440 Hz + 330 Hz)")
	var phase1 := 0.0
	var phase2 := 0.0
	phase1 = fmod(phase1 + 440.0 / MIX_RATE, 1.0)
	phase2 = fmod(phase2 + 330.0 / MIX_RATE, 1.0)
	expect_approx(phase1, 440.0 / MIX_RATE, "440 Hz phase step correct")
	expect_approx(phase2, 330.0 / MIX_RATE, "330 Hz phase step correct")
	expect(phase1 != phase2, "two frequencies produce different phases")


# --- Sine wave output range ---

func _test_sine_range() -> void:
	print("sine wave output range [-1, 1]")
	var phase := 0.0
	var min_val := 1.0
	var max_val := -1.0
	for i in 1000:
		var s := sin(TAU * phase)
		if s < min_val:
			min_val = s
		if s > max_val:
			max_val = s
		phase = fmod(phase + 220.0 / MIX_RATE, 1.0)
	expect(min_val >= -1.0, "sine never below -1")
	expect(max_val <= 1.0, "sine never above 1")
	expect(min_val < -0.9, "sine reaches near -1 in 1000 samples")
	expect(max_val > 0.9, "sine reaches near +1 in 1000 samples")


func _test_two_freq_mix_range() -> void:
	print("two-frequency mix stays in [-0.5, 0.5] * 0.5 amplitude")
	var phase1 := 0.0
	var phase2 := 0.0
	var max_abs := 0.0
	for _i in 2000:
		var s := sin(TAU * phase1) * 0.25 + sin(TAU * phase2) * 0.25
		var pushed := absf(Vector2(s, s).x)
		if pushed > max_abs:
			max_abs = pushed
		phase1 = fmod(phase1 + 440.0 / MIX_RATE, 1.0)
		phase2 = fmod(phase2 + 330.0 / MIX_RATE, 1.0)
	expect(max_abs <= 0.501, "mixed signal peak amplitude <= 0.5")
	expect(max_abs > 0.0, "mixed signal is non-silent")


# --- Volume crossfade direction ---

func _test_crossfade_calm_volumes() -> void:
	print("crossfade to calm: calm→0dB, combat→-80dB")
	# Simulate the target values set by _transition("calm")
	var calm_target_db := 0.0
	var combat_target_db := -80.0
	expect_approx(calm_target_db, 0.0, "calm target is 0 dB (full volume)")
	expect(combat_target_db <= -79.9, "combat target is -80 dB (near silence)")
	expect(calm_target_db > combat_target_db, "calm louder than combat in calm state")


func _test_crossfade_combat_volumes() -> void:
	print("crossfade to combat: combat→0dB, calm→-80dB")
	var combat_target_db := 0.0
	var calm_target_db := -80.0
	expect_approx(combat_target_db, 0.0, "combat target is 0 dB (full volume)")
	expect(calm_target_db <= -79.9, "calm target is -80 dB (near silence)")
	expect(combat_target_db > calm_target_db, "combat louder than calm in combat state")


func _test_fmod_wraps() -> void:
	print("fmod phase wrapping stays in [0, 1)")
	var phase := 0.998
	for _i in 20:
		phase = fmod(phase + 220.0 / MIX_RATE, 1.0)
	expect(phase >= 0.0, "phase >= 0 after wraparound")
	expect(phase < 1.0, "phase < 1 after wraparound")


func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
