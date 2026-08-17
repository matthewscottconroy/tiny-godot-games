extends Node

# Drives the real Transition autoload — see docs/TEST_INTEGRITY.md.
#
# Deliberately never completes a transition: fade_to() ends in
# change_scene_to_file(), which would replace the scene this suite is running
# in. So this covers the state either side of that call and the guard that
# stops a second transition starting.

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
