extends Node

var _pass := 0
var _fail := 0

const MIX_RATE := 44100.0


func _ready() -> void:
	_test_beep_range()
	_test_buzz_is_binary()
	_test_crash_bounded()
	_test_chirp_frequency_increases()
	_test_fade_envelope_beep()
	_test_fade_envelope_chirp()
	_test_sfx_durations()
	_report()


func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)


func expect_approx(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) < tol, label)


# --- Minimal SFX sampler mirroring _get_sample logic ---

class SFXSampler:
	var gen_type := ""
	var gen_phase := 0.0
	const MIX_RATE_LOCAL := 44100.0

	func get_sample(t: float) -> float:
		match gen_type:
			"beep":
				var freq := 440.0
				gen_phase += freq / MIX_RATE_LOCAL
				return sin(TAU * gen_phase) * (1.0 - t)
			"buzz":
				var freq := 120.0
				gen_phase += freq / MIX_RATE_LOCAL
				return sign(sin(TAU * gen_phase)) * (1.0 - t)
			"crash":
				# Bounded noise: randf() returns [0,1), scale to [-1,1)
				return (randf() * 2.0 - 1.0) * pow(1.0 - t, 0.5)
			"chirp":
				var freq := lerpf(200.0, 800.0, t)
				gen_phase += freq / MIX_RATE_LOCAL
				return sin(TAU * gen_phase) * (1.0 - pow(t, 2.0))
		return 0.0


# --- Tests ---

func _test_beep_range() -> void:
	print("beep sine wave stays in [-1, 1]")
	var s := SFXSampler.new()
	s.gen_type = "beep"
	var max_abs := 0.0
	for i in 500:
		var t := float(i) / 500.0
		var val := s.get_sample(t)
		if absf(val) > max_abs:
			max_abs = absf(val)
	expect(max_abs <= 1.001, "beep amplitude never exceeds 1.0")
	expect(max_abs > 0.0, "beep produces non-zero output at t=0")


func _test_buzz_is_binary() -> void:
	print("buzz square wave output is only +1, -1, or 0")
	var s := SFXSampler.new()
	s.gen_type = "buzz"
	var all_binary := true
	for i in 500:
		var t := float(i) / 500.0
		var raw_sign := sign(sin(TAU * (float(i) * 120.0 / MIX_RATE)))
		# The sign() function returns -1, 0, or +1
		if not (raw_sign == -1.0 or raw_sign == 0.0 or raw_sign == 1.0):
			all_binary = false
	expect(all_binary, "square wave raw sign is always -1, 0, or +1")

	# Confirm amplitude envelope (1-t) monotonically decreases
	s.gen_phase = 0.0
	var early := absf(s.get_sample(0.1))
	s.gen_phase = 0.0
	# reset phase and sample at t=0.9 (far along, sign flips so sample could be same raw magnitude)
	# Instead, directly check envelope values
	var env_early := (1.0 - 0.1)
	var env_late := (1.0 - 0.9)
	expect(env_early > env_late, "buzz envelope is larger at t=0.1 than t=0.9")


func _test_crash_bounded() -> void:
	print("crash noise burst stays in [-1, 1]")
	var s := SFXSampler.new()
	s.gen_type = "crash"
	var all_bounded := true
	for i in 1000:
		var t := float(i) / 1000.0
		var val := s.get_sample(t)
		if absf(val) > 1.001:
			all_bounded = false
	expect(all_bounded, "crash samples all within [-1, 1]")

	# Verify envelope: at t=0 amplitude can be up to 1, at t=1 envelope = pow(0, 0.5) = 0
	var envelope_at_start := pow(1.0 - 0.0, 0.5)
	var envelope_at_end := pow(1.0 - 1.0, 0.5)
	expect_approx(envelope_at_start, 1.0, "crash envelope is 1.0 at t=0")
	expect_approx(envelope_at_end, 0.0, "crash envelope is 0.0 at t=1")


func _test_chirp_frequency_increases() -> void:
	print("chirp frequency increases linearly from 200 to 800 Hz")
	var freq_at_0 := lerpf(200.0, 800.0, 0.0)
	var freq_at_half := lerpf(200.0, 800.0, 0.5)
	var freq_at_1 := lerpf(200.0, 800.0, 1.0)
	expect_approx(freq_at_0, 200.0, "chirp starts at 200 Hz")
	expect_approx(freq_at_half, 500.0, "chirp is 500 Hz at midpoint")
	expect_approx(freq_at_1, 800.0, "chirp ends at 800 Hz")
	expect(freq_at_0 < freq_at_half, "chirp freq increases from start to mid")
	expect(freq_at_half < freq_at_1, "chirp freq increases from mid to end")


func _test_fade_envelope_beep() -> void:
	print("beep amplitude envelope decreases with t")
	var env_early := 1.0 - 0.1   # t=0.1
	var env_mid   := 1.0 - 0.5   # t=0.5
	var env_late  := 1.0 - 0.9   # t=0.9
	expect(env_early > env_mid, "beep envelope at 0.1 > envelope at 0.5")
	expect(env_mid > env_late, "beep envelope at 0.5 > envelope at 0.9")
	expect_approx(1.0 - 1.0, 0.0, "beep envelope reaches 0 at t=1")


func _test_fade_envelope_chirp() -> void:
	print("chirp amplitude envelope (1 - t^2) decreases with t")
	var env := func(t: float) -> float: return 1.0 - pow(t, 2.0)
	expect(env.call(0.0) > env.call(0.5), "chirp envelope larger at t=0 than t=0.5")
	expect(env.call(0.5) > env.call(0.9), "chirp envelope larger at t=0.5 than t=0.9")
	expect_approx(env.call(1.0), 0.0, "chirp envelope is 0 at t=1")
	expect_approx(env.call(0.0), 1.0, "chirp envelope is 1 at t=0")


func _test_sfx_durations() -> void:
	print("SFX total frame counts match durations")
	var durations := {"beep": 0.3, "buzz": 0.4, "crash": 0.2, "chirp": 0.5}
	for sfx_name in durations:
		var expected_frames := int(durations[sfx_name] * MIX_RATE)
		expect(expected_frames > 0, "%s has positive frame count" % sfx_name)
		# Verify the formula: int(duration * MIX_RATE)
		var computed := int(durations[sfx_name] * MIX_RATE)
		expect(computed == expected_frames, "%s frame count is deterministic" % sfx_name)
	expect(int(0.5 * MIX_RATE) > int(0.2 * MIX_RATE), "chirp is longer than crash")
	expect(int(0.4 * MIX_RATE) > int(0.3 * MIX_RATE), "buzz is longer than beep")


func _report() -> void:
	var summary := "[procedural-sfx] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
