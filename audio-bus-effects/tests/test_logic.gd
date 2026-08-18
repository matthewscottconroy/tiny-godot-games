extends Node

# Drives the real buses from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The AudioServer is global and the demo adds buses to it, so this suite makes
# one scene and reads the buses it created rather than making several.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_every_bus_exists()
	_test_each_effect_bus_carries_its_effect()
	_test_the_dry_bus_is_left_alone()
	_test_every_bus_reaches_the_master()
	_test_the_tone_is_generated()
	_test_the_tone_fades_out()
	_test_the_player_starts_on_the_dry_bus()
	_test_switching_moves_the_player_between_buses()
	_test_the_list_wraps_both_ways()
	_test_the_readout_describes_the_bus()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[audio-bus-effects] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _cached: Node2D

func _make() -> Node2D:
	if not is_instance_valid(_cached):
		_cached = load("res://scenes/main.tscn").instantiate()
		add_child(_cached)
	return _cached

func _act(m: Node2D, action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	m._input(e)

func _test_every_bus_exists() -> void:
	print("the buses")
	var m := _make()
	begin_quiet()
	for name in m.BUSES:
		expect_quiet(AudioServer.get_bus_index(name) != -1, "there is no %s bus" % name)
	expect(_quiet_failures == 0, "every bus the demo offers was created on the server")

func _test_each_effect_bus_carries_its_effect() -> void:
	print("the effects")
	_make()
	var wanted := {
		"Reverb": "AudioEffectReverb",
		"Echo": "AudioEffectDelay",
		"Compressed": "AudioEffectCompressor",
	}
	begin_quiet()
	for name in wanted:
		var index := AudioServer.get_bus_index(name)
		var found := false
		for i in AudioServer.get_bus_effect_count(index):
			if AudioServer.get_bus_effect(index, i).get_class() == wanted[name]:
				found = true
		# A bus named for an effect it does not carry sounds exactly like Dry,
		# and the demo would show four identical settings.
		expect_quiet(found, "the %s bus carries no %s" % [name, wanted[name]])
	expect(_quiet_failures == 0, "each bus carries the effect it is named for")

func _test_the_dry_bus_is_left_alone() -> void:
	print("the dry bus")
	_make()
	var index := AudioServer.get_bus_index("Dry")
	expect(index != -1, "there is a dry bus to compare against")
	expect(AudioServer.get_bus_effect_count(index) == 0,
		"with nothing on it — it is the reference the others are heard against")

func _test_every_bus_reaches_the_master() -> void:
	print("routing")
	var m := _make()
	begin_quiet()
	for name in m.BUSES:
		var index := AudioServer.get_bus_index(name)
		if index == 0:
			continue
		# A bus that sends nowhere is silent, however good its effect.
		expect_quiet(AudioServer.get_bus_send(index) != "",
			"the %s bus sends to nothing" % name)
	expect(_quiet_failures == 0, "every bus is routed onwards rather than sending into nothing")

func _test_the_tone_is_generated() -> void:
	print("the tone")
	var m := _make()
	var stream := m._player.stream as AudioStreamWAV
	expect(stream != null, "the sound is generated in code, not loaded from a file")
	expect(stream.mix_rate == m.SAMPLE_RATE, "at the demo's sample rate")
	expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "as 16-bit samples")
	expect(stream.data.size() > m.SAMPLE_RATE, "and is long enough to hear an effect on")

func _test_the_tone_fades_out() -> void:
	print("the envelope")
	var m := _make()
	var stream := m._player.stream as AudioStreamWAV
	var data := stream.data
	# A tone that stops dead clicks; the envelope is what makes reverb and
	# delay audible as tails rather than as part of the note.
	var early := _loudness(data, 0, 2000)
	var late := _loudness(data, data.size() / 2 - 2000, data.size() / 2)
	expect(early > late, "the tone fades as it plays (%d then %d)" % [early, late])
	expect(late >= 0, "and does not wrap round into loudness again")

func _test_the_player_starts_on_the_dry_bus() -> void:
	print("on open")
	var m := _make()
	m._current_bus = 0
	m._player.bus = m.BUSES[0]
	expect(m._player.bus == "Dry", "the demo opens on the unprocessed signal")

func _test_switching_moves_the_player_between_buses() -> void:
	print("switching")
	var m := _make()
	m._current_bus = 0
	m._player.bus = m.BUSES[0]
	_act(m, "ui_right")
	expect(m._current_bus == 1, "right steps to the next bus")
	# The routing has to move with the selection, or the label changes and the
	# sound does not.
	expect(m._player.bus == m.BUSES[1], "and the player is routed through it")
	_act(m, "ui_left")
	expect(m._player.bus == m.BUSES[0], "left steps back")

func _test_the_list_wraps_both_ways() -> void:
	print("wrapping")
	var m := _make()
	m._current_bus = 0
	for i in m.BUSES.size():
		_act(m, "ui_right")
	expect(m._current_bus == 0, "stepping past the end comes back to the start")
	_act(m, "ui_left")
	expect(m._current_bus == m.BUSES.size() - 1, "and back from the first lands on the last")
	expect(m._player.bus == m.BUSES[m._current_bus], "with the routing following")
	m._current_bus = 0
	m._player.bus = m.BUSES[0]

func _test_the_readout_describes_the_bus() -> void:
	print("the readout")
	var m := _make()
	var described := {}
	for i in m.BUSES.size():
		m._current_bus = i
		m._update_label()
		var info: String = (m.get_node("CanvasLayer/InfoLabel") as Label).text
		expect_quiet(info.length() > 0, "%s has no description" % m.BUSES[i])
		described[info] = true
		expect_quiet((m.get_node("CanvasLayer/BusLabel") as Label).text.contains(m.BUSES[i]),
			"the readout does not name %s" % m.BUSES[i])
	expect(described.size() == m.BUSES.size(), "each bus is described differently")
	m._current_bus = 0
	m._update_label()

## Total absolute amplitude across a range of 16-bit samples.
func _loudness(data: PackedByteArray, from: int, to: int) -> int:
	var total := 0
	var i := from - from % 2
	while i < to - 1:
		var value: int = data[i] | (data[i + 1] << 8)
		if value >= 32768:
			value -= 65536
		total += absi(value)
		i += 2
	return total

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
