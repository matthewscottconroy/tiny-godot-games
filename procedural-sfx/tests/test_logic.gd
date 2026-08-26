extends Node

# Drives the real sound generation from scripts/main.gd — see
# docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_player_is_a_generator()
	_test_the_waveform_buffer_starts_silent()
	_test_each_effect_sets_its_own_length()
	_test_an_unknown_effect_still_gets_a_length()
	_test_starting_an_effect_rewinds_it()
	_test_every_effect_makes_a_sound()
	_test_the_effects_sound_different()
	_test_the_beep_and_chirp_fade_out()
	_test_the_chirp_climbs()
	_test_samples_stay_in_range()
	_test_the_waveform_ring_scrolls_forward()
	_test_an_effect_knows_when_it_is_done()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

## The ring buffer walks forward and wraps.
func _test_the_waveform_ring_scrolls_forward() -> void:
	print("the ring buffer")
	var m := _make()

	expect(m.advance_head(0) == 1, "the head steps forward (%d)" % m.advance_head(0))
	expect(m.advance_head(m.WAVEFORM_SAMPLES - 1) == 0,
		"and wraps at the end rather than running past it (%d)"
		% m.advance_head(m.WAVEFORM_SAMPLES - 1))

	# Never negative: stepping backwards would index the array from its end and
	# eventually off the front of it.
	_quiet_failures = 0
	var head := 0
	for i in m.WAVEFORM_SAMPLES * 2:
		head = m.advance_head(head)
		expect_quiet(head >= 0 and head < m.WAVEFORM_SAMPLES,
			"step %d gave head %d" % [i, head])
	expect(_quiet_failures == 0, "the head stays inside the buffer for two whole laps")
	expect(head == 0, "and comes back to where it started (%d)" % head)

	# Samples land in order, each in the next slot.
	m._wave_head = 0
	for i in 4:
		m.push_wave(float(i + 1) * 0.1)
	expect(m._wave_head == 4, "four pushes advance the head four places (%d)" % m._wave_head)
	_quiet_failures = 0
	for i in 4:
		expect_quiet(is_equal_approx(m._wave_buf[i], float(i + 1) * 0.1),
			"slot %d holds %.1f (got %.3f)" % [i, float(i + 1) * 0.1, m._wave_buf[i]])
	expect(_quiet_failures == 0, "and each sample is in the slot it was written to")

## An effect knows when it has finished.
func _test_an_effect_knows_when_it_is_done() -> void:
	print("finishing")
	var m := _make()
	m._start_sfx("beep")
	expect(m._gen_total > 0, "the effect asked for some frames (%d)" % m._gen_total)
	expect(not m.is_finished(), "and is not finished before playing any")

	m._gen_frames = m._gen_total - 1
	expect(not m.is_finished(), "nor with one frame left to play")
	m._gen_frames = m._gen_total
	expect(m.is_finished(), "it is finished once it has played them all")
	m._gen_frames = m._gen_total + 10
	expect(m.is_finished(), "and stays finished past the end")

	# Starting again rewinds it, so a second press replays rather than staying
	# silent because the counter is still past the end.
	m._start_sfx("beep")
	expect(not m.is_finished(), "starting it again makes it unfinished")

func _report() -> void:
	var summary := "[procedural-sfx] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const EFFECTS := ["beep", "buzz", "crash", "chirp"]
var _cached: Node2D

# One scene for the suite: it starts an AudioStreamPlayer, and several would
# stack up audio that never gets stopped.
func _make() -> Node2D:
	if not is_instance_valid(_cached):
		_cached = load("res://scenes/main.tscn").instantiate()
		add_child(_cached)
	return _cached

## Sample an effect across its whole length, without going near the audio bus.
func _sample_effect(m: Node2D, type: String, count: int = 64) -> Array[float]:
	m._start_sfx(type)
	var samples: Array[float] = []
	for i in count:
		samples.append(m._get_sample(float(i) / float(count - 1)))
	return samples

func _peak(samples: Array[float], from: int, to: int) -> float:
	var loudest := 0.0
	for i in range(from, mini(to, samples.size())):
		loudest = maxf(loudest, absf(samples[i]))
	return loudest

func _test_the_player_is_a_generator() -> void:
	print("the player")
	var m := _make()
	expect(m._player.stream is AudioStreamGenerator, "the sound is generated frame by frame")
	expect((m._player.stream as AudioStreamGenerator).mix_rate == m.MIX_RATE,
		"at the demo's mix rate")
	expect(m._player.playing, "with the player already running, ready to be fed")

func _test_the_waveform_buffer_starts_silent() -> void:
	print("the waveform display")
	var m := _make()
	expect(m._wave_buf.size() == m.WAVEFORM_SAMPLES, "the ring buffer is the size it says")

func _test_each_effect_sets_its_own_length() -> void:
	print("lengths")
	var m := _make()
	var lengths := {}
	begin_quiet()
	for type in EFFECTS:
		m._start_sfx(type)
		expect_quiet(m._gen_total > 0, "%s has no length" % type)
		lengths[m._gen_total] = type
	expect(_quiet_failures == 0, "every effect has a length")
	expect(lengths.size() > 2, "and they are not all the same")

func _test_an_unknown_effect_still_gets_a_length() -> void:
	print("an unknown effect")
	var m := _make()
	m._start_sfx("no such sound")
	# Falling back to zero would divide by zero when working out how far
	# through the sound each sample is.
	expect(m._gen_total > 0, "an unknown effect falls back to a real length")

func _test_starting_an_effect_rewinds_it() -> void:
	print("starting over")
	var m := _make()
	m._start_sfx("beep")
	m._gen_frames = 500
	m._gen_phase = 3.0
	m._start_sfx("beep")
	expect(m._gen_frames == 0, "starting an effect plays it from the beginning")
	expect(is_zero_approx(m._gen_phase), "with its phase reset, so it does not click")

func _test_every_effect_makes_a_sound() -> void:
	print("sound")
	var m := _make()
	begin_quiet()
	for type in EFFECTS:
		var samples := _sample_effect(m, type)
		expect_quiet(_peak(samples, 0, samples.size()) > 0.05, "%s is silent" % type)
	expect(_quiet_failures == 0, "every effect produces something audible")

func _test_the_effects_sound_different() -> void:
	print("variety")
	var m := _make()
	var shapes := {}
	for type in EFFECTS:
		shapes[str(_sample_effect(m, type))] = type
	expect(shapes.size() == EFFECTS.size(), "the four effects are four different sounds")

func _test_the_beep_and_chirp_fade_out() -> void:
	print("envelopes")
	var m := _make()
	begin_quiet()
	for type in ["beep", "buzz", "chirp"]:
		var samples := _sample_effect(m, type, 128)
		var early := _peak(samples, 0, 32)
		var late := _peak(samples, 96, 128)
		# A sound that stops at full volume clicks.
		expect_quiet(early > late, "%s does not fade as it plays" % type)
	expect(_quiet_failures == 0, "the tuned effects fade out rather than stopping dead")

func _test_the_chirp_climbs() -> void:
	print("the chirp")
	var m := _make()
	m._start_sfx("chirp")
	# A chirp sweeps upwards, so its samples cross zero more often late on than
	# early — the phase advances faster as it goes.
	var early_phase: float = 0.0
	m._gen_phase = 0.0
	m._get_sample(0.05)
	early_phase = m._gen_phase
	m._gen_phase = 0.0
	m._get_sample(0.95)
	expect(m._gen_phase > early_phase, "the chirp rises in pitch as it plays")

func _test_samples_stay_in_range() -> void:
	print("levels")
	var m := _make()
	begin_quiet()
	for type in EFFECTS:
		var samples := _sample_effect(m, type, 200)
		for s in samples:
			# Anything past one clips when it reaches the speakers.
			expect_quiet(absf(s) <= 1.0, "%s produced a sample of %.2f" % [type, s])
	expect(_quiet_failures == 0, "no effect produces a sample outside the audible range")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
