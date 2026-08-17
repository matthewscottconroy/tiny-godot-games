extends Node

# Drives the real flash from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_screen_starts_clear()
	_test_a_flash_tints_the_screen()
	await _test_a_flash_fades_out()
	_test_the_number_keys_flash_different_colours()
	_test_the_keys_choose_different_lengths()
	_test_other_keys_do_not_flash()
	_test_a_held_key_does_not_flash_again()
	_test_walking_into_the_hazard_flashes()
	_test_only_the_player_sets_the_hazard_off()
	_test_the_player_jumps_only_from_the_floor()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[screen-flash] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _rect(m: Node2D) -> ColorRect:
	return m.get_node("CanvasLayer/FlashRect")

func _press(m: Node2D, code: Key, echo: bool = false) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	e.echo = echo
	m._unhandled_key_input(e)

func _hazard(m: Node2D) -> Area2D:
	for node in m.get_tree().get_nodes_in_group("hazard"):
		if m.is_ancestor_of(node):
			return node
	return null

func _test_the_screen_starts_clear() -> void:
	print("no flash")
	var m := _make()
	expect(is_zero_approx(_rect(m).color.a), "the overlay starts fully transparent")

func _test_a_flash_tints_the_screen() -> void:
	print("flashing")
	var m := _make()
	m.flash(Color(1.0, 0.0, 0.0, 0.5), 0.3)
	expect(_rect(m).color.a > 0.0, "a flash tints the overlay")
	expect(_rect(m).color.r > _rect(m).color.b, "in the colour it was given")

func _test_a_flash_fades_out() -> void:
	print("fading")
	var m := _make()
	m.flash(Color(1.0, 0.0, 0.0, 0.6), 0.2)
	var start: float = _rect(m).color.a
	await get_tree().process_frame
	await get_tree().process_frame
	expect(_rect(m).color.a < start, "the flash starts fading immediately")
	for i in 120:
		await get_tree().process_frame
		if is_zero_approx(_rect(m).color.a):
			break
	expect(is_zero_approx(_rect(m).color.a), "and clears entirely rather than leaving a tint")

func _test_the_number_keys_flash_different_colours() -> void:
	print("the keys")
	var seen := {}
	for code in [KEY_1, KEY_2, KEY_3, KEY_4]:
		var m := _make()
		_press(m, code)
		expect(_rect(m).color.a > 0.0, "the key flashes the screen")
		seen[_rect(m).color] = true
	expect(seen.size() == 4, "each key has its own colour")

func _test_the_keys_choose_different_lengths() -> void:
	print("lengths")
	# A pickup should blink and a respawn should linger; equal durations would
	# make the four events feel the same.
	var quick := _make()
	_press(quick, KEY_2)
	var slow := _make()
	_press(slow, KEY_4)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	# Both started at a similar alpha; the shorter flash has dropped further.
	var quick_left: float = _rect(quick).color.a / 0.70
	var slow_left: float = _rect(slow).color.a / 0.90
	expect(quick_left < slow_left, "the short flash fades faster than the long one")

func _test_other_keys_do_not_flash() -> void:
	print("other keys")
	var m := _make()
	_press(m, KEY_9)
	expect(is_zero_approx(_rect(m).color.a), "a key with nothing bound to it does nothing")

func _test_a_held_key_does_not_flash_again() -> void:
	print("held keys")
	var m := _make()
	_press(m, KEY_1, true)
	expect(is_zero_approx(_rect(m).color.a), "an auto-repeat echo does not re-flash the screen")

func _test_walking_into_the_hazard_flashes() -> void:
	print("the hazard")
	var m := _make()
	var hazard := _hazard(m)
	expect(hazard != null, "the hazard zone is in the group main.gd looks for")
	hazard.body_entered.emit(m.get_node("Player"))
	expect(_rect(m).color.a > 0.0, "walking into it flashes the screen")
	expect(_rect(m).color.r > _rect(m).color.g, "in damage red")

func _test_only_the_player_sets_the_hazard_off() -> void:
	print("who trips it")
	var m := _make()
	var passer_by := CharacterBody2D.new()
	add_child(passer_by)
	_hazard(m).body_entered.emit(passer_by)
	expect(is_zero_approx(_rect(m).color.a), "something that is not the player does not flash it")

func _test_the_player_jumps_only_from_the_floor() -> void:
	print("the player")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	expect(player.is_in_group("player"), "the player is in the group the hazard looks for")
	expect(player.can_jump(true, true), "pressing jump on the floor jumps")
	expect(not player.can_jump(true, false), "pressing it in mid-air does not")
	expect(not player.can_jump(false, true), "and standing on the floor is not enough by itself")
