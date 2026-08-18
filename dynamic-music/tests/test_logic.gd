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
