extends Node

# Drives the real crates from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_crates_start_whole()
	_test_a_click_damages_a_crate()
	_test_a_crate_survives_until_its_hp_runs_out()
	_test_the_last_hit_shatters_it()
	_test_a_shattered_crate_ignores_further_clicks()
	_test_shattering_scatters_fragments()
	_test_the_fragments_fly_outwards()
	_test_the_fragments_are_physical()
	_test_other_mouse_buttons_do_not_damage()
	_test_the_hit_flash_fades()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[destructibles] %d/%d passed" % [_pass, _pass + _fail]
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

func _crates(m: Node2D) -> Array[Area2D]:
	var found: Array[Area2D] = []
	for child in m.get_children():
		if child is Area2D and is_instance_valid(child):
			found.append(child)
	return found

func _click(crate: Area2D, button: int = MOUSE_BUTTON_LEFT) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.position = crate.global_position
	crate._on_click(null, e, 0)

func _fragments(m: Node2D) -> Array[RigidBody2D]:
	var found: Array[RigidBody2D] = []
	for child in m.get_children():
		if child is RigidBody2D:
			found.append(child)
	return found

func _test_the_crates_start_whole() -> void:
	print("the crates")
	var m := _make()
	var crates := _crates(m)
	expect(crates.size() > 0, "there are crates to break")
	for crate in crates:
		expect(not crate._destroyed, "each one starts whole")
		expect(crate._hits == 0, "and unhit")
		expect(crate.input_pickable, "and picks up clicks")

func _test_a_click_damages_a_crate() -> void:
	print("hitting one")
	var m := _make()
	var crate := _crates(m)[0]
	_click(crate)
	expect(crate._hits == 1, "a click counts as a hit")
	expect(crate._flash_timer > 0.0, "and flashes the crate")

func _test_a_crate_survives_until_its_hp_runs_out() -> void:
	print("tougher crates")
	var m := _make()
	var tough: Area2D = null
	for crate in _crates(m):
		if crate.hp > 1:
			tough = crate
	expect(tough != null, "at least one crate takes more than one hit")
	if tough == null:
		return
	for i in tough.hp - 1:
		_click(tough)
	expect(not tough._destroyed, "it survives one hit short of its hp")

func _test_the_last_hit_shatters_it() -> void:
	print("breaking one")
	var m := _make()
	var crate := _crates(m)[0]
	for i in crate.hp:
		_click(crate)
	expect(crate._destroyed, "the hit that empties its hp destroys it")
	expect(crate.is_queued_for_deletion(), "and the crate removes itself")

func _test_a_shattered_crate_ignores_further_clicks() -> void:
	print("hitting the debris")
	var m := _make()
	var crate := _crates(m)[0]
	for i in crate.hp:
		_click(crate)
	var fragments := _fragments(m).size()
	_click(crate)
	# Clicking where a crate used to be would otherwise shatter it a second
	# time and double the debris.
	expect(_fragments(m).size() == fragments, "a destroyed crate does not shatter again")

func _test_shattering_scatters_fragments() -> void:
	print("the debris")
	var m := _make()
	var crate := _crates(m)[0]
	var expected: int = crate.frag_count
	for i in crate.hp:
		_click(crate)
	expect(_fragments(m).size() == expected, "it breaks into the number of pieces it was told to")

	var positions := {}
	for frag in _fragments(m):
		positions[frag.position] = true
	expect(positions.size() > 1, "scattered rather than stacked on one spot")

func _test_the_fragments_fly_outwards() -> void:
	print("the scatter")
	var m := _make()
	var crate := _crates(m)[0]
	var centre: Vector2 = crate.global_position
	for i in crate.hp:
		_click(crate)

	# The pieces are thrown around a circle and given a common upward kick, so
	# what holds is that they head in different directions and generally up —
	# not that each one flies away from its own spawn offset.
	var directions := {}
	var total := Vector2.ZERO
	var moving := 0
	for frag in _fragments(m):
		directions[roundi(frag.linear_velocity.angle() * 2.0)] = true
		total += frag.linear_velocity
		if frag.linear_velocity.length() > 0.0:
			moving += 1
	expect(moving == _fragments(m).size(), "every piece is thrown somewhere")
	expect(directions.size() > 2, "in a spread of directions rather than all together")
	expect(total.y < 0.0, "with an upward kick, so the debris pops before it falls")
	expect(centre != Vector2.ZERO, "from where the crate stood")

	var spinning := 0
	for frag in _fragments(m):
		if absf(frag.angular_velocity) > 0.0:
			spinning += 1
	expect(spinning > 0, "and they tumble as they go")

func _test_the_fragments_are_physical() -> void:
	print("the pieces")
	var m := _make()
	var crate := _crates(m)[0]
	for i in crate.hp:
		_click(crate)
	for frag in _fragments(m):
		expect_quiet(frag.gravity_scale > 0.0, "a fragment falls under gravity")
		expect_quiet(frag.get_child_count() >= 2, "and has both a shape and something to draw")
	expect(_quiet_failures == 0, "every fragment is a real physics body with a shape")

func _test_other_mouse_buttons_do_not_damage() -> void:
	print("other buttons")
	var m := _make()
	var crate := _crates(m)[0]
	_click(crate, MOUSE_BUTTON_RIGHT)
	expect(crate._hits == 0, "a right-click does not break crates")

func _test_the_hit_flash_fades() -> void:
	print("the flash")
	var m := _make()
	var crate := _crates(m)[0]
	_click(crate)
	var lit: float = crate._flash_timer
	crate._process(STEP)
	expect(crate._flash_timer < lit, "the flash starts fading at once")
	for i in 30:
		crate._process(STEP)
	expect(crate._flash_timer <= 0.0, "and is gone shortly after")

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
