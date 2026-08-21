extends Node

# Drives the real crossfade from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_both_layers_are_playing()
	_test_only_the_calm_layer_is_audible_at_first()
	_test_the_layers_are_generated_streams()
	_test_switching_to_combat_swaps_the_volumes()
	_test_switching_back_swaps_them_again()
	await _test_the_swap_is_a_fade_not_a_cut()
	_test_both_layers_keep_playing_throughout()
	_test_the_two_layers_are_different_music()
	_test_the_phases_run_forward()
	_test_the_combat_layer_is_a_sum_of_two_tones()
	_test_a_switch_to_the_current_state_does_nothing()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[dynamic-music] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _cached: Node2D

# One scene for the suite: each holds two playing AudioStreamPlayers, and
# building several would stack up audio that never gets stopped.
func _make() -> Node2D:
	if not is_instance_valid(_cached):
		_cached = load("res://scenes/main.tscn").instantiate()
		add_child(_cached)
	return _cached

func _calm(m: Node2D) -> AudioStreamPlayer:
	return m._calm_player

func _combat(m: Node2D) -> AudioStreamPlayer:
	return m._combat_player

func _test_both_layers_are_playing() -> void:
	print("the layers")
	var m := _make()
	# Both run from the start: a layer started only when needed comes in from
	# the beginning of its bar rather than in time with the other.
	expect(_calm(m).playing, "the calm layer is playing")
	expect(_combat(m).playing, "and so is the combat layer")

func _test_only_the_calm_layer_is_audible_at_first() -> void:
	print("on open")
	var m := _make()
	m._state = "calm"
	_calm(m).volume_db = 0.0
	_combat(m).volume_db = -80.0
	expect(_calm(m).volume_db > _combat(m).volume_db, "the calm layer is the one you hear")
	expect(_combat(m).volume_db < -60.0, "with the combat layer silent rather than quiet")

func _test_the_layers_are_generated_streams() -> void:
	print("the streams")
	var m := _make()
	expect(_calm(m).stream is AudioStreamGenerator, "the calm layer is generated in code")
	expect(_combat(m).stream is AudioStreamGenerator, "and so is the combat layer")
	expect((_calm(m).stream as AudioStreamGenerator).mix_rate == m.MIX_RATE, "at the demo's mix rate")

func _test_switching_to_combat_swaps_the_volumes() -> void:
	print("into combat")
	var m := _make()
	m._transition("combat")
	expect(m._state == "combat", "the state changes")

func _test_switching_back_swaps_them_again() -> void:
	print("back to calm")
	var m := _make()
	m._transition("calm")
	expect(m._state == "calm", "and changes back")

func _test_the_swap_is_a_fade_not_a_cut() -> void:
	print("the crossfade")
	var m := _make()
	m._state = "calm"
	_calm(m).volume_db = 0.0
	_combat(m).volume_db = -80.0

	m._transition("combat")
	await get_tree().process_frame
	await get_tree().process_frame
	# Part-way, not swapped: a cut is audible as a click, and the point of two
	# layers is that one slides under the other.
	expect(_combat(m).volume_db > -80.0, "the combat layer starts coming up")
	expect(_combat(m).volume_db < 0.0, "but is not there yet")
	expect(_calm(m).volume_db < 0.0, "while the calm layer starts going down")

	for i in 200:
		await get_tree().process_frame
		if _combat(m).volume_db >= -0.1:
			break
	expect(_combat(m).volume_db >= -0.1, "the combat layer arrives at full volume")
	expect(_calm(m).volume_db < -60.0, "and the calm layer is gone")

	m._transition("calm")
	for i in 200:
		await get_tree().process_frame
		if _calm(m).volume_db >= -0.1:
			break
	expect(_calm(m).volume_db >= -0.1, "and it fades back the other way")

func _test_both_layers_keep_playing_throughout() -> void:
	print("staying in time")
	var m := _make()
	# Faded down rather than stopped, so the two stay in step with each other.
	expect(_calm(m).playing and _combat(m).playing,
		"both layers are still playing after the fades, only one is audible")

func _test_the_two_layers_are_different_music() -> void:
	print("the two layers")
	var m := _make()
	var source: String = (m.get_script() as GDScript).source_code
	# The calm layer is one tone, the combat layer two mixed together.
	expect(source.contains("220.0"), "the calm layer has its own pitch")
	expect(source.contains("440.0") and source.contains("330.0"),
		"and the combat layer is a different, thicker chord")

## The phases advance, and wrap at a whole cycle rather than running away.
func _test_the_phases_run_forward() -> void:
	print("the phase")
	var m := _make()

	var p := 0.0
	var went_up := 0
	var wrapped := 0
	# One full cycle of the 220 Hz tone is MIX_RATE / 220 samples.
	for i in int(m.MIX_RATE / 220.0) + 4:
		var next: float = m.advance_phase(p, 220.0)
		if next > p:
			went_up += 1
		else:
			wrapped += 1
		p = next
	expect(went_up > 0, "the phase advances (%d steps forward)" % went_up)
	expect(wrapped >= 1, "and wraps once per cycle rather than climbing (%d)" % wrapped)
	expect(p >= 0.0 and p < 1.0, "staying inside one cycle (%.4f)" % p)

	# A higher frequency covers a cycle in fewer samples, which is the only
	# thing the frequency argument does.
	var slow := 0
	var fast := 0
	var a := 0.0
	var b := 0.0
	for i in int(m.MIX_RATE / 440.0) + 1:
		var na: float = m.advance_phase(a, 220.0)
		var nb: float = m.advance_phase(b, 440.0)
		if na < a: slow += 1
		if nb < b: fast += 1
		a = na
		b = nb
	expect(fast > slow, "the higher tone wraps more often (%d vs %d)" % [fast, slow])

## Combat is two tones added together, not subtracted.
func _test_the_combat_layer_is_a_sum_of_two_tones() -> void:
	print("the combat mix")
	var m := _make()

	# A quarter of the way through both cycles, each tone is at its peak: added
	# they reinforce, subtracted they cancel to silence.
	var both_up: float = m.combat_sample(0.25, 0.25)
	expect(is_equal_approx(both_up, 0.5),
		"two peaks together make the loudest sample (%.3f)" % both_up)

	# One peak up and one down: added they cancel, subtracted they reinforce.
	var opposed: float = m.combat_sample(0.25, 0.75)
	expect(absf(opposed) < 0.001,
		"a peak and a trough cancel (%.3f)" % opposed)

	# The two layers peak at the same level, so neither is obviously louder
	# than the other through the crossfade.
	var calm_peak: float = m.calm_sample(0.25)
	expect(is_equal_approx(calm_peak, 0.4),
		"the calm layer peaks at 0.4 (%.3f)" % calm_peak)
	expect(both_up > calm_peak,
		"and the combat layer is no quieter (%.3f vs %.3f)" % [both_up, calm_peak])

	# Both start and end a cycle at silence, so the buffer has no step in it
	# where the phase wraps.
	expect(absf(m.calm_sample(0.0)) < 0.001, "the calm tone starts at silence")
	expect(absf(m.combat_sample(0.0, 0.0)) < 0.001, "and so does the combat mix")

## Asking for the state you are already in changes nothing.
func _test_a_switch_to_the_current_state_does_nothing() -> void:
	print("the guard")
	# Its own scene: _make() hands out one shared instance, and the tests above
	# leave it in whatever state they finished in. "The demo opens calm" is only
	# a claim about a demo that has just opened.
	var m: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(m)
	expect(m._state == "calm", "the demo opens calm (%s)" % m._state)
	expect(not m.wants("calm"), "so it does not want to switch to calm")
	expect(m.wants("combat"), "but it does want to switch to combat")

	m._transition("combat")
	expect(m._state == "combat", "switching sets the state (%s)" % m._state)
	expect(not m.wants("combat"), "and now combat is the one it will not repeat")
	expect(m.wants("calm"), "while calm is the one it will")

	m.queue_free()
