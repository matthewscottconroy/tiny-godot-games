extends Node

# Drives the real tone generator from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# One scene for the whole suite: the AudioServer is global and the demo adds a
# bus to it, so building several would stack up duplicates.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_sfx_bus_is_created_and_routed()
	_test_the_player_is_on_that_bus()
	_test_a_tone_is_generated_to_length()
	_test_the_tone_fades_out()
	_test_the_waveforms_differ()
	_test_a_square_wave_is_square()
	_test_a_sweep_changes_pitch()
	_test_the_buttons_play_different_notes()
	_test_the_volume_slider_moves_the_bus()
	_test_the_readout_reports_the_volume()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[audio-demo] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _cached: Control

func _make() -> Control:
	if not is_instance_valid(_cached):
		_cached = load("res://scenes/main.tscn").instantiate()
		add_child(_cached)
	return _cached

func _press(m: Control, name: String) -> void:
	(m.get_node("ButtonRow/" + name) as Button).pressed.emit()

## The signed 16-bit sample at index `i`.
func _sample(data: PackedByteArray, i: int) -> int:
	var value: int = data[i * 2] | (data[i * 2 + 1] << 8)
	return value - 65536 if value >= 32768 else value

## Loudest sample across a range, as a measure of level.
func _peak(data: PackedByteArray, from: int, to: int) -> int:
	var loudest := 0
	for i in range(from, mini(to, data.size() / 2)):
		loudest = maxi(loudest, absi(_sample(data, i)))
	return loudest

## How many times the signal crosses zero — a stand-in for pitch.
func _zero_crossings(data: PackedByteArray, from: int, to: int) -> int:
	var crossings := 0
	var previous := _sample(data, from)
	for i in range(from + 1, mini(to, data.size() / 2)):
		var current := _sample(data, i)
		if (previous < 0) != (current < 0):
			crossings += 1
		previous = current
	return crossings

func _test_the_sfx_bus_is_created_and_routed() -> void:
	print("the bus")
	_make()
	var index := AudioServer.get_bus_index("SFX")
	expect(index != -1, "the demo creates its own SFX bus")
	expect(index != 0, "separate from Master, so its volume can move on its own")
	expect(AudioServer.get_bus_send(index) == "Master", "and sends onwards to Master")

func _test_the_player_is_on_that_bus() -> void:
	print("routing")
	var m := _make()
	# Assigning a player to a bus that does not exist is silently ignored, so
	# this checks the assignment took rather than that it was attempted.
	expect(m.sfx_player.bus == "SFX", "the player really is routed through the SFX bus")

func _test_a_tone_is_generated_to_length() -> void:
	print("the tone")
	var m := _make()
	var tone := m._make_tone(440.0, 0.3) as AudioStreamWAV
	expect(tone != null, "the sound is generated in code, not loaded from a file")
	expect(tone.mix_rate == m.SAMPLE_RATE, "at the demo's sample rate")
	expect(tone.format == AudioStreamWAV.FORMAT_16_BITS, "as 16-bit samples")
	# Two bytes per sample, so a 0.3 second tone is 0.3 * rate * 2 bytes.
	expect(tone.data.size() == int(m.SAMPLE_RATE * 0.3) * 2, "and lasts the length it was asked for")

	var longer := m._make_tone(440.0, 0.6) as AudioStreamWAV
	expect(longer.data.size() > tone.data.size(), "a longer tone holds more samples")

func _test_the_tone_fades_out() -> void:
	print("the envelope")
	var m := _make()
	var tone := m._make_tone(440.0, 0.4) as AudioStreamWAV
	var samples: int = tone.data.size() / 2
	var early := _peak(tone.data, 0, 500)
	var late := _peak(tone.data, samples - 600, samples - 100)
	# Without the fade the tone ends on a hard edge, which clicks.
	expect(early > late, "the tone fades as it plays (%d then %d)" % [early, late])
	expect(early > 1000, "and starts loud enough to hear")

func _test_the_waveforms_differ() -> void:
	print("the waveforms")
	var m := _make()
	var shapes := {}
	for wave in ["sine", "square", "sweep"]:
		shapes[(m._make_tone(300.0, 0.2, wave) as AudioStreamWAV).data] = wave
	expect(shapes.size() == 3, "the three waveforms produce three different sounds")

func _test_a_square_wave_is_square() -> void:
	print("the square wave")
	var m := _make()
	var square := (m._make_tone(300.0, 0.2, "square") as AudioStreamWAV).data
	var sine := (m._make_tone(300.0, 0.2, "sine") as AudioStreamWAV).data
	# A square wave sits at its extremes; a sine spends most of its time
	# between them. Comparing the average level against the peak tells them
	# apart without looking at a single sample.
	var square_total := 0
	var sine_total := 0
	var count := 2000
	for i in count:
		square_total += absi(_sample(square, i))
		sine_total += absi(_sample(sine, i))
	expect(square_total > sine_total,
		"the square wave carries more energy than the sine at the same peak")

func _test_a_sweep_changes_pitch() -> void:
	print("the sweep")
	var m := _make()
	var sweep := (m._make_tone(300.0, 0.5, "sweep") as AudioStreamWAV).data
	var samples: int = sweep.size() / 2
	var early := _zero_crossings(sweep, 100, 2100)
	var late := _zero_crossings(sweep, samples - 2600, samples - 600)
	expect(late > early, "a sweep climbs in pitch as it plays (%d then %d)" % [early, late])

	var steady := (m._make_tone(300.0, 0.5) as AudioStreamWAV).data
	var steady_early := _zero_crossings(steady, 100, 2100)
	var steady_late := _zero_crossings(steady, samples - 2600, samples - 600)
	expect(absi(steady_late - steady_early) < early / 2,
		"while a plain tone holds its pitch")

func _test_the_buttons_play_different_notes() -> void:
	print("the buttons")
	var m := _make()
	var heard := {}
	for name in ["LowBtn", "MidBtn", "HighBtn", "SquareBtn", "SweepBtn"]:
		_press(m, name)
		expect_quiet(m.sfx_player.stream != null, "%s left the player with no sound" % name)
		heard[(m.sfx_player.stream as AudioStreamWAV).data] = name
	expect(_quiet_failures == 0, "every button loads a sound")
	expect(heard.size() == 5, "and each button plays a different one")

func _test_the_volume_slider_moves_the_bus() -> void:
	print("volume")
	var m := _make()
	m.vol_slider.value = -12.0
	expect(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")), -12.0),
		"the slider sets the bus volume, not just a number on screen")
	m.vol_slider.value = 0.0

func _test_the_readout_reports_the_volume() -> void:
	print("the readout")
	var m := _make()
	m.vol_slider.value = -6.0
	expect(m.bus_label.text.contains("-6"), "the readout follows the slider")
	expect(m.bus_label.text.contains("dB"), "in the units the bus uses")
	m.vol_slider.value = 0.0

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
