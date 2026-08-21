extends Node

# Drives the real attenuation from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0
var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")

func _ready() -> void:
	_test_the_source_plays_a_looping_tone()
	_test_the_tone_is_generated()
	_test_the_player_is_positional()
	_test_standing_on_the_source_is_full_volume()
	_test_volume_falls_with_distance()
	_test_beyond_the_range_is_silence()
	_test_the_falloff_is_not_a_straight_line()
	_test_the_listener_moves_and_stays_on_screen()
	_test_the_readout_reports_distance_and_volume()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[audio-positional] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _test_the_source_plays_a_looping_tone() -> void:
	print("the source")
	var m := _make()
	var stream := m.player.stream as AudioStreamWAV
	expect(stream != null, "the source has a sound to play")
	# A one-shot would fall silent a second in and the demo would have nothing
	# to demonstrate.
	expect(stream.loop_mode != AudioStreamWAV.LOOP_DISABLED, "which loops rather than playing once")
	expect(stream.loop_end > stream.loop_begin, "over a real span of the sound")

func _test_the_tone_is_generated() -> void:
	print("the tone")
	var m := _make()
	var stream := m.player.stream as AudioStreamWAV
	expect(stream.mix_rate == m.SAMPLE_RATE, "generated at the demo's sample rate")
	expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "as 16-bit samples")
	expect(stream.data.size() > m.SAMPLE_RATE, "and long enough to loop smoothly")

	# What is in the buffer, not just how much of it. Length, format and mix
	# rate are all satisfied by silence — and by a buffer whose two bytes per
	# sample are written to the wrong indices, because a smooth wave hides a
	# displaced high byte everywhere except where it changes.
	var loud := 0
	for i in 200:
		loud = maxi(loud, absi(_sample_at(stream.data, i)))
	expect(loud > 20000, "the tone is actually loud (%d)" % loud)

	# A low tone moves less than one high byte between neighbouring samples, so
	# any disturbance of the bytes shows up as a step the wave cannot make.
	var slow: AudioStreamWAV = m._make_tone(20.0, 0.2)
	var biggest := 0
	for i in range(1, 400):
		biggest = maxi(biggest, absi(_sample_at(slow.data, i) - _sample_at(slow.data, i - 1)))
	expect(biggest < 250,
		"a 20Hz tone steps smoothly, well under one high byte (%d)" % biggest)

	# And it is a sine: it crosses zero twice per cycle and starts there.
	expect(absi(_sample_at(slow.data, 0)) < 200,
		"the tone starts at silence (%d)" % _sample_at(slow.data, 0))
	var crossings := 0
	var cycle := int(m.SAMPLE_RATE / 20.0)
	for i in range(1, cycle + 1):
		if signi(_sample_at(slow.data, i)) != signi(_sample_at(slow.data, i - 1)):
			crossings += 1
	expect(crossings == 2, "and crosses zero twice per cycle (%d)" % crossings)

	# A higher tone fits more cycles into the same buffer, which is the only
	# thing the frequency argument does.
	var fast: AudioStreamWAV = m._make_tone(40.0, 0.2)
	var fast_crossings := 0
	for i in range(1, cycle + 1):
		if signi(_sample_at(fast.data, i)) != signi(_sample_at(fast.data, i - 1)):
			fast_crossings += 1
	expect(fast_crossings > crossings,
		"twice the frequency crosses zero twice as often (%d vs %d)"
		% [fast_crossings, crossings])

## The signed 16-bit sample at index `i`, read the way the engine reads it.
func _sample_at(data: PackedByteArray, i: int) -> int:
	var raw := data[i * 2] | (data[i * 2 + 1] << 8)
	return raw - 65536 if raw > 32767 else raw

func _test_the_player_is_positional() -> void:
	print("the player")
	var m := _make()
	expect(m.player is AudioStreamPlayer2D, "the sound is played from a positional player")
	expect(m.player.max_distance > 0.0, "with a range to fall off over")
	expect(m.player.get_parent() == m.source, "attached to the source it comes from")

func _test_standing_on_the_source_is_full_volume() -> void:
	print("up close")
	var m := _make()
	expect(is_equal_approx(m.volume_at(0.0), 1.0), "at no distance the sound is at full volume")

func _test_volume_falls_with_distance() -> void:
	print("falling off")
	var m := _make()
	var near: float = m.volume_at(m.player.max_distance * 0.25)
	var far: float = m.volume_at(m.player.max_distance * 0.75)
	expect(near > far, "further away is quieter")
	expect(far > 0.0, "but still audible inside the range")

func _test_beyond_the_range_is_silence() -> void:
	print("out of range")
	var m := _make()
	expect(is_zero_approx(m.volume_at(m.player.max_distance)), "at the edge of the range it is silent")
	# Without the clamp the volume would go negative and then rise again as a
	# power of a negative number.
	expect(is_zero_approx(m.volume_at(m.player.max_distance * 3.0)),
		"and stays silent well beyond it rather than coming back")

func _test_the_falloff_is_not_a_straight_line() -> void:
	print("the curve")
	var m := _make()
	var half: float = m.volume_at(m.player.max_distance * 0.5)
	expect(m.player.attenuation > 0.0, "the falloff has an exponent")
	expect(half > 0.0 and half < 1.0, "and halfway out sits between the two ends (%.2f)" % half)
	# Monotonic all the way down, whatever the exponent: a curve that turns
	# back up would make walking away get louder again.
	begin_quiet()
	var previous := 1.1
	for i in 21:
		var here: float = m.volume_at(m.player.max_distance * float(i) / 20.0)
		expect_quiet(here <= previous, "the volume rose again at %d/20 of the range" % i)
		previous = here
	expect(_quiet_failures == 0, "the volume only ever falls as you walk away")

func _test_the_listener_moves_and_stays_on_screen() -> void:
	print("the listener")
	var m := _make()
	var start: Vector2 = m.listener.position
	m.tick(0.5, Vector2.RIGHT)
	expect(m.listener.position.x > start.x, "the listener walks where it is pointed")

	for i in 200:
		m.tick(0.1, Vector2(1.0, 1.0))
	expect(m.listener.position.x <= 620.0 and m.listener.position.y <= 460.0,
		"and stops at the edges of the room")
	for i in 400:
		m.tick(0.1, Vector2(-1.0, -1.0))
	expect(m.listener.position.x >= 20.0 and m.listener.position.y >= 60.0,
		"on the other two sides as well")

func _test_the_readout_reports_distance_and_volume() -> void:
	print("the readout")
	var m := _make()
	m.listener.position = m.source.position
	m.tick(0.0, Vector2.ZERO)
	expect(m.info.text.contains("100"), "standing on the source reads full volume")

	# The listener is penned into the room, which is smaller than the sound's
	# range, so the far corner is the quietest it can actually get.
	m.listener.position = Vector2(620.0, 460.0)
	m.tick(0.0, Vector2.ZERO)
	var far: float = m.volume_at(m.listener.position.distance_to(m.source.position))
	expect(far < 1.0, "walking to the far corner is quieter than standing on it")
	# Rounded the same way the readout rounds it, rather than truncated.
	expect(m.info.text.contains("%.0f%%" % (far * 100.0)), "and the readout agrees with the falloff")
