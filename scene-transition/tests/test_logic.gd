extends Node

# Drives the real Transition autoload — see docs/TEST_INTEGRITY.md.
#
# A transition ends in change_scene_to_file(), which would replace the scene
# this suite is running in — so the autoload keeps that call behind a
# replaceable `change_scene`, and the suite swaps it for one that records the
# path. That makes the whole cycle drivable: the guard going up, the fade out,
# the scene change, the fade back in, and the guard coming down again.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_transition_layer_is_available()
	_test_it_sits_above_everything()
	_test_the_fade_starts_invisible_and_click_through()
	_test_it_is_not_transitioning_to_start_with()
	_test_a_second_transition_is_refused_while_one_runs()
	_test_the_screens_point_at_each_other()
	_test_both_screens_exist()
	await _test_a_whole_transition_runs_and_releases_the_guard()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[scene-transition] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _test_the_transition_layer_is_available() -> void:
	print("the autoload")
	expect(Transition != null, "the transition is available from anywhere as an autoload")
	expect(Transition is CanvasLayer, "as a CanvasLayer, so it draws over the current scene")
	expect(Transition.has_method("fade_to"), "with one thing to call")

func _test_it_sits_above_everything() -> void:
	print("the layer")
	# A fade that draws underneath the game would fade nothing.
	expect(Transition.layer > 0, "the fade layer is above the default layer (%d)" % Transition.layer)

func _test_the_fade_starts_invisible_and_click_through() -> void:
	print("at rest")
	var rect: ColorRect = Transition.rect
	expect(is_zero_approx(rect.color.a), "the fade rect is transparent while nothing is happening")
	expect(rect.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"and lets clicks through, so it cannot block the game it covers")

func _test_it_is_not_transitioning_to_start_with() -> void:
	print("idle")
	expect(not Transition._transitioning, "no transition is in progress")

func _test_a_second_transition_is_refused_while_one_runs() -> void:
	print("the guard")
	# Double-clicking a menu button would otherwise start two fades and two
	# scene changes, and the second would land on a half-loaded scene.
	Transition._transitioning = true
	var alpha_before: float = Transition.rect.color.a
	Transition.fade_to("res://scenes/level.tscn")
	expect(is_equal_approx(Transition.rect.color.a, alpha_before),
		"a second call while one is running does nothing")
	expect(Transition._transitioning, "and leaves the first one to finish")
	Transition._transitioning = false

func _test_the_screens_point_at_each_other() -> void:
	print("the wiring")
	var title: String = (load("res://scripts/title.gd") as GDScript).source_code
	var level: String = (load("res://scripts/level.gd") as GDScript).source_code
	expect(title.contains("level.tscn"), "the title screen sends you to the level")
	expect(level.contains("title.tscn"), "and the level sends you back")
	expect(title.contains("Transition.fade_to") and level.contains("Transition.fade_to"),
		"both through the same autoload, rather than changing scenes themselves")

func _test_both_screens_exist() -> void:
	print("the destinations")
	for path in ["res://scenes/title.tscn", "res://scenes/level.tscn"]:
		expect(ResourceLoader.exists(path), "%s is a real scene to fade to" % path)

## The full cycle, with the scene change intercepted.
func _test_a_whole_transition_runs_and_releases_the_guard() -> void:
	print("a transition")
	var asked: Array[String] = []
	var real: Callable = Transition.change_scene
	Transition.change_scene = func(path: String) -> void: asked.append(path)

	expect(not Transition._transitioning, "nothing is running to start with")
	expect(is_equal_approx(Transition.rect.color.a, 0.0),
		"and the screen is clear (%.2f)" % Transition.rect.color.a)

	Transition.fade_to("res://scenes/level.tscn")

	# The guard goes up on the same frame the call is made, or a second click
	# in the same frame would start a second fade.
	expect(Transition._transitioning, "the guard goes up immediately")
	expect(Transition.rect.mouse_filter == Control.MOUSE_FILTER_STOP,
		"and the overlay starts swallowing clicks, so nothing behind it responds")

	# Partway through, the screen is darkening and the scene has not changed —
	# changing it first would show the new scene before the fade covered it.
	for _i in 12:
		await get_tree().process_frame
	expect(Transition.rect.color.a > 0.0,
		"the screen darkens as the fade runs (%.2f)" % Transition.rect.color.a)
	expect(asked.is_empty(), "and the scene has not changed yet")

	# The refusal, while a real transition is genuinely in flight.
	var midway: float = Transition.rect.color.a
	Transition.fade_to("res://scenes/title.tscn")
	expect(asked.is_empty(), "a second call during the fade starts nothing")
	expect(is_equal_approx(Transition.rect.color.a, midway),
		"and does not restart the fade (%.2f)" % Transition.rect.color.a)

	# Let it finish: the scene changes once, the screen clears, and the guard
	# comes down so the next transition can run at all.
	for _i in 120:
		await get_tree().process_frame
		if not Transition._transitioning:
			break
	expect(asked == ["res://scenes/level.tscn"],
		"the scene changes exactly once, to the path asked for (%s)" % [asked])
	expect(not Transition._transitioning,
		"the guard comes down when the transition ends")
	expect(is_equal_approx(Transition.rect.color.a, 0.0),
		"the screen fades back to clear (%.2f)" % Transition.rect.color.a)
	expect(Transition.rect.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"and stops swallowing clicks")

	# And a second transition is possible afterwards, which is the whole reason
	# the flag has to be cleared rather than merely set.
	Transition.fade_to("res://scenes/title.tscn")
	expect(Transition._transitioning, "another transition can start once the first is done")
	for _i in 120:
		await get_tree().process_frame
		if not Transition._transitioning:
			break
	expect(asked.size() == 2, "and it runs (%s)" % [asked])

	Transition.change_scene = real
