extends Node

# Drives the real button from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_button_scales_about_its_middle()
	_test_it_starts_unsquished()
	await _test_pressing_squishes_and_springs_back()
	_test_pressing_pops_a_score_label()
	_test_the_pops_are_scattered()
	_test_each_press_pops_again()
	await _test_a_pop_rises_and_fades()
	await _test_a_pop_cleans_itself_up()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[tween-juice] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node

func _make() -> Node:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

## The juiced button, wherever it sits in the scene.
func _button(m: Node) -> Button:
	for node in m.find_children("*", "Button", true, false):
		if node.get_script() != null:
			return node
	return null

func _pops(m: Node) -> Array[Label]:
	var found: Array[Label] = []
	for node in _button(m).get_parent().get_children():
		# Exact text: the demo's own hint label mentions "+10 labels", so a
		# contains() check would count the instructions as a score pop.
		if node is Label and (node as Label).text == "+10":
			found.append(node)
	return found

func _test_the_button_scales_about_its_middle() -> void:
	print("the pivot")
	var m := _make()
	var button := _button(m)
	# Without a centred pivot the squish would swing the button off its corner
	# rather than squashing it in place.
	expect(button.pivot_offset.is_equal_approx(button.size / 2.0),
		"the button scales about its own centre")

func _test_it_starts_unsquished() -> void:
	print("at rest")
	var m := _make()
	expect(_button(m).scale.is_equal_approx(Vector2.ONE), "the button starts at its normal size")
	expect(_pops(m).is_empty(), "with nothing popped yet")

func _test_pressing_squishes_and_springs_back() -> void:
	print("the squish")
	var m := _make()
	var button := _button(m)
	button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	expect(not button.scale.is_equal_approx(Vector2.ONE), "pressing squashes the button")
	expect(button.scale.x > button.scale.y, "wider than it is tall, as a squash should be")

	for i in 200:
		await get_tree().process_frame
		if button.scale.is_equal_approx(Vector2.ONE):
			break
	expect(button.scale.is_equal_approx(Vector2.ONE), "and it springs back to its normal size")

func _test_pressing_pops_a_score_label() -> void:
	print("the pop")
	var m := _make()
	_button(m).pressed.emit()
	expect(_pops(m).size() == 1, "a press pops one score label")
	expect(_pops(m)[0].text.contains("10"), "showing what was scored")

func _test_the_pops_are_scattered() -> void:
	print("scatter")
	var m := _make()
	var xs := {}
	for i in 12:
		_button(m).pressed.emit()
	for pop in _pops(m):
		xs[roundi(pop.position.x)] = true
	# Popping every label at the same spot would read as one label flickering.
	expect(xs.size() > 1, "consecutive pops are jittered apart")

func _test_each_press_pops_again() -> void:
	print("repeat presses")
	var m := _make()
	for i in 3:
		_button(m).pressed.emit()
	expect(_pops(m).size() == 3, "three presses pop three labels")

func _test_a_pop_rises_and_fades() -> void:
	print("rising")
	var m := _make()
	_button(m).pressed.emit()
	var pop: Label = _pops(m)[0]
	var start_y: float = pop.position.y
	for i in 20:
		await get_tree().process_frame
	expect(pop.position.y < start_y, "the label drifts upwards")
	expect(pop.modulate.a < 1.0, "and fades as it goes")

func _test_a_pop_cleans_itself_up() -> void:
	print("cleaning up")
	var m := _make()
	_button(m).pressed.emit()
	var pop: Label = _pops(m)[0]
	# Left behind, every press would add a permanent invisible label to the
	# scene — the sort of leak that only shows up after a long session.
	for i in 300:
		await get_tree().process_frame
		if not is_instance_valid(pop):
			break
	expect(not is_instance_valid(pop), "the label frees itself once it has faded")
