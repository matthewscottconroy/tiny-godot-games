extends Node

# Drives the real pause menu from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_menu_starts_hidden()
	_test_escape_pauses_the_game()
	_test_escape_again_resumes_it()
	_test_the_resume_button_resumes()
	_test_the_menu_keeps_running_while_paused()
	_test_the_world_does_not()
	_test_other_keys_do_not_pause()
	await _test_the_player_stays_down_untouched()
	_report()
	# Leave the tree running for anything after this suite.
	get_tree().paused = false

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

## Nothing pressed, nothing happens.
##
## The jump reads Input, which a headless test cannot press. Its other half is
## is_on_floor(), and loosening the `and` to an `or` launches the player on
## every grounded frame — which is visible from the outside without pressing
## anything at all.
func _test_the_player_stays_down_untouched() -> void:
	print("standing still")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	var player: CharacterBody2D = scene.find_child("Player", true, false)
	expect(player != null, "the scene has a player")
	for _i in 60:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player settles on the ground")
	var resting: float = player.global_position.y
	var highest := resting
	for _i in 40:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"and stays there with no key pressed (rose %.1f px)" % (resting - highest))
	scene.queue_free()

func _report() -> void:
	var summary := "[pause-menu] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

# The pause state is global, so each test starts from a known one.
func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	get_tree().paused = false
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _menu(m: Node2D) -> CanvasLayer:
	return m.get_node("PauseMenu")

func _press_escape(m: Node2D) -> void:
	var e := InputEventAction.new()
	e.action = "ui_cancel"
	e.pressed = true
	_menu(m)._unhandled_input(e)

func _test_the_menu_starts_hidden() -> void:
	print("unpaused")
	var m := _make()
	expect(not _menu(m).visible, "the menu is out of the way until it is asked for")
	expect(not get_tree().paused, "and the game is running")

func _test_escape_pauses_the_game() -> void:
	print("pausing")
	var m := _make()
	_press_escape(m)
	expect(get_tree().paused, "escape pauses the tree")
	expect(_menu(m).visible, "and shows the menu")

func _test_escape_again_resumes_it() -> void:
	print("unpausing")
	var m := _make()
	_press_escape(m)
	_press_escape(m)
	expect(not get_tree().paused, "escape again unpauses")
	expect(not _menu(m).visible, "and hides the menu")

func _test_the_resume_button_resumes() -> void:
	print("the resume button")
	var m := _make()
	_press_escape(m)
	expect(get_tree().paused, "paused")
	(m.get_node("PauseMenu/Panel/VBox/ResumeBtn") as Button).pressed.emit()
	expect(not get_tree().paused, "the resume button unpauses")
	expect(not _menu(m).visible, "and puts the menu away")

func _test_the_menu_keeps_running_while_paused() -> void:
	print("process modes")
	var m := _make()
	# The menu has to keep processing while the tree is paused, or nothing
	# could ever unpause it — this is the whole trick of a pause menu.
	expect(_menu(m).process_mode == Node.PROCESS_MODE_ALWAYS,
		"the menu processes even while the tree is paused")

func _test_the_world_does_not() -> void:
	print("the world")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	expect(player.process_mode != Node.PROCESS_MODE_ALWAYS,
		"the player is not exempt from the pause")
	expect(m.process_mode != Node.PROCESS_MODE_ALWAYS, "and neither is the world around them")

func _test_other_keys_do_not_pause() -> void:
	print("other keys")
	var m := _make()
	var key := InputEventKey.new()
	key.keycode = KEY_Q
	key.pressed = true
	_menu(m)._unhandled_input(key)
	expect(not get_tree().paused, "an unrelated key does not pause the game")
	expect(not _menu(m).visible, "nor open the menu")
