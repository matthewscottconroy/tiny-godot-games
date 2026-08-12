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

func _report() -> void:
	var summary := "[floating-text] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
