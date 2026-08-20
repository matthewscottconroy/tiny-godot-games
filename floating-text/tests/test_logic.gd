extends Node

# Drives the real FloatingText.spawn() from scripts/floating_text.gd and the
# real Target nodes from the demo scene.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_spawn_adds_a_label()
	test_spawn_carries_position_and_colour()
	test_spawn_starts_the_rise_and_fade()
	test_multiple_spawns_are_independent()
	test_target_click_spawns_damage_text()
	test_target_revives_at_zero_hp()
	await test_the_text_rises_and_fades_together()
	test_the_target_is_clickable_and_only_by_a_click()
	test_the_damage_number_is_coloured_by_how_big_it_is()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _host() -> Node2D:
	var host := Node2D.new()
	add_child(host)
	return host

func test_spawn_adds_a_label() -> void:
	print("spawn adds a Label child")
	var host := _host()
	FloatingText.spawn(host, Vector2(100, 100), "-25")
	expect(host.get_child_count() == 1, "one node is added to the parent")
	var ft := host.get_child(0) as FloatingText
	expect(ft != null, "the spawned node is a FloatingText")
	expect(ft.text == "-25", "it carries the message")

func test_spawn_carries_position_and_colour() -> void:
	print("spawn carries position and colour")
	var host := _host()
	FloatingText.spawn(host, Vector2(40, 60), "CRIT", Color.CYAN)
	var ft := host.get_child(0) as FloatingText
	expect(ft.position == Vector2(40, 60), "it spawns at the requested position")
	expect(ft.modulate == Color.CYAN, "it uses the requested colour")
	expect(ft.z_index > 0, "it draws above the scene it annotates")

func test_spawn_starts_the_rise_and_fade() -> void:
	print("spawn starts the rise-and-fade tween")
	var host := _host()
	FloatingText.spawn(host, Vector2(0, 200), "+1")
	var ft := host.get_child(0) as FloatingText
	expect(ft.get_tree().get_processed_tweens().size() > 0, "a tween is running to animate it")

func test_multiple_spawns_are_independent() -> void:
	print("multiple spawns are independent")
	var host := _host()
	FloatingText.spawn(host, Vector2(0, 0), "a", Color.RED)
	FloatingText.spawn(host, Vector2(50, 0), "b", Color.GREEN)
	expect(host.get_child_count() == 2, "each call adds its own label")
	expect((host.get_child(0) as FloatingText).text == "a", "the first keeps its own text")
	expect((host.get_child(1) as FloatingText).text == "b", "the second keeps its own text")

# The demo's Target spawns the floating text on click. Driving the real click
# handler covers the damage roll, the clamp at zero, and the revive.
func _click_event() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event

func _make_target() -> Area2D:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene.get_node("Target1")

func test_target_click_spawns_damage_text() -> void:
	print("clicking a target spawns damage text")
	var target := _make_target()
	var parent := target.get_parent()
	var before := parent.get_child_count()
	var hp_before: int = target._hp
	target._on_click(null, _click_event(), 0)
	expect(target._hp < hp_before, "the click deals damage")
	expect(parent.get_child_count() > before, "a floating label is added to the target's parent")

func test_target_revives_at_zero_hp() -> void:
	print("a target revives when its hp hits zero")
	var target := _make_target()
	# Click until it dies; max_dmg is bounded, so this terminates quickly.
	var guard := 0
	while target._hp == target._max_hp and guard == 0:
		guard += 1
	var deaths := 0
	for i in 200:
		var before: int = target._hp
		target._on_click(null, _click_event(), 0)
		if target._hp > before:
			deaths += 1
			break
	expect(deaths == 1, "hp reaching 0 revives the target to full")
	expect(target._hp == target._max_hp, "hp resets to max_hp after death")

## The text goes up, not down, and fades while it goes.
##
## "A tween is running" is satisfied by any tween at all. What the demo actually
## promises is a number that drifts upward off the thing it annotates and
## disappears — so both properties are watched while they animate, and both have
## to be moving at once, which is what `set_parallel(true)` is for. In series
## the number would rise fully at full opacity and only then begin to fade.
func test_the_text_rises_and_fades_together() -> void:
	print("the rise and fade")
	var host := _host()
	var start := Vector2(120, 300)
	FloatingText.spawn(host, start, "-42")
	var ft := host.get_child(0) as FloatingText

	expect(is_equal_approx(ft.position.y, start.y), "it starts where it was spawned")
	expect(is_equal_approx(ft.modulate.a, 1.0), "at full opacity (%.2f)" % ft.modulate.a)

	# Far enough in for both tweens to have moved, well short of the 0.9s end.
	var elapsed := 0.0
	while elapsed < 0.55 and is_instance_valid(ft):
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	expect(is_instance_valid(ft), "it is still on screen partway through")
	if is_instance_valid(ft):
		expect(ft.position.y < start.y,
			"it has drifted upward — Y is down (%.1f from %.1f)" % [ft.position.y, start.y])
		expect(ft.modulate.a < 1.0,
			"and is fading at the same time, not after (%.2f)" % ft.modulate.a)

	# It takes itself away, or every hit leaves a label behind for good.
	while is_instance_valid(ft) and elapsed < 3.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	expect(not is_instance_valid(ft), "and frees itself when the animation ends")
	expect(host.get_child_count() == 0, "leaving nothing behind (%d)" % host.get_child_count())

## The target can be clicked at all, and only a real click counts.
func test_the_target_is_clickable_and_only_by_a_click() -> void:
	print("the click")
	var target := _make_target()
	expect(target.input_pickable,
		"the target accepts input, or nothing in the demo can be hit")

	var before: int = target._hp
	target._on_click(null, InputEventMouseMotion.new(), 0)
	expect(target._hp == before, "moving the mouse over it does nothing")

	var release := _click_event()
	release.pressed = false
	target._on_click(null, release, 0)
	expect(target._hp == before, "nor does the button coming back up")

	var right := _click_event()
	right.button_index = MOUSE_BUTTON_RIGHT
	target._on_click(null, right, 0)
	expect(target._hp == before, "nor a right-click")

	target._on_click(null, _click_event(), 0)
	expect(target._hp < before, "a left-click does (%d -> %d)" % [before, target._hp])

## Bigger hits are drawn in a hotter colour.
func test_the_damage_number_is_coloured_by_how_big_it_is() -> void:
	print("the damage colour")
	var target := _make_target()
	target.min_dmg = 5
	target.max_dmg = 5
	target._hp = target._max_hp
	target._on_click(null, _click_event(), 0)
	var small := (target.get_parent().get_child(target.get_parent().get_child_count() - 1)
		as FloatingText)
	expect(small.modulate == Color.ORANGE_RED,
		"a small hit is the cooler of the two colours (%s)" % small.modulate)

	target.min_dmg = 60
	target.max_dmg = 60
	target._hp = target._max_hp
	target._on_click(null, _click_event(), 0)
	var big := (target.get_parent().get_child(target.get_parent().get_child_count() - 1)
		as FloatingText)
	expect(big.modulate == Color.RED,
		"a big one is the hotter (%s)" % big.modulate)
	expect(small.modulate != big.modulate, "and the two are told apart at all")

	# Both numbers appear above the thing they belong to. Below it they would be
	# drawn over the health bar and, since they drift upward, would spend the
	# animation crossing back over the target rather than away from it.
	expect(big.position.y < target.global_position.y,
		"the damage number spawns above the target (%.0f vs %.0f)"
		% [big.position.y, target.global_position.y])
	expect(absf(big.position.x - target.global_position.x) <= 20.0,
		"and within a jitter's width of it horizontally (%.0f)"
		% (big.position.x - target.global_position.x))

	# Same for the revive, which fires from a different call site.
	target.min_dmg = target._max_hp
	target.max_dmg = target._max_hp
	target._hp = target._max_hp
	target._on_click(null, _click_event(), 0)
	var parent := target.get_parent()
	var revived := parent.get_child(parent.get_child_count() - 1) as FloatingText
	expect(revived.text == "REVIVED!", "a killing blow revives the target (%s)" % revived.text)
	expect(revived.position.y < target.global_position.y,
		"and says so above it (%.0f vs %.0f)"
		% [revived.position.y, target.global_position.y])

func _report() -> void:
	var summary := "[floating-text] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
