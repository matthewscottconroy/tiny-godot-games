extends Node

# Drives the real items and zones from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_board_is_set_up()
	_test_items_remember_where_they_started()
	_test_zones_announce_themselves()
	_test_pressing_an_item_picks_it_up()
	_test_a_picked_up_item_follows_the_mouse()
	_test_other_buttons_do_not_pick_items_up()
	_test_dropping_into_a_zone_parks_the_item()
	_test_a_parked_item_stays_when_dragged_and_dropped_in_place()
	_test_the_counter_follows_the_filled_zones()
	_test_filling_every_zone_finishes_the_puzzle()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[drag-drop] %d/%d passed" % [_pass, _pass + _fail]
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

func _item(m: Node2D, n: int) -> Area2D:
	return m.get_node("Items").get_child(n)

func _zone(m: Node2D, n: int) -> Area2D:
	return m.get_node("Zones").get_child(n)

func _press(item: Area2D, pressed: bool, button: int = MOUSE_BUTTON_LEFT) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	e.position = item.position
	item._on_input(null, e, 0)

func _test_the_board_is_set_up() -> void:
	print("the board")
	var m := _make()
	expect(m.get_node("Items").get_child_count() > 0, "there are items to drag")
	expect(m.get_node("Zones").get_child_count() > 0, "and zones to drop them into")
	expect(m.filled == 0, "with none of them filled yet")

	var colours := {}
	for item in m.get_node("Items").get_children():
		colours[item.item_color] = true
	expect(colours.size() > 1, "the items are told apart by colour")

func _test_items_remember_where_they_started() -> void:
	print("home positions")
	var m := _make()
	for item in m.get_node("Items").get_children():
		expect(item.start_pos == item.position, "an item remembers where it was laid out")
	expect(not _item(m, 0).dragging, "and none of them are being dragged")

func _test_zones_announce_themselves() -> void:
	print("finding the zones")
	var m := _make()
	# An item looks for the group rather than a node path, so any zone anywhere
	# in the scene can accept a drop.
	for zone in m.get_node("Zones").get_children():
		expect(zone.is_in_group("drop_zones"), "a zone joins the drop_zones group")
		expect(not zone.has_item, "and starts empty")
		# Without monitoring, a zone never registers as overlapping the item
		# being dropped on it, and nothing can ever be dropped anywhere.
		expect(zone.monitoring, "and is watching for overlaps")
	for item in m.get_node("Items").get_children():
		expect(item.monitoring, "each item watches for overlaps too")

func _test_pressing_an_item_picks_it_up() -> void:
	print("picking up")
	var m := _make()
	var item := _item(m, 0)
	_press(item, true)
	expect(item.dragging, "pressing on an item picks it up")

func _test_a_picked_up_item_follows_the_mouse() -> void:
	print("carrying")
	var m := _make()
	var item := _item(m, 0)
	var home: Vector2 = item.position
	_press(item, true)
	# The offset is what stops the item's centre snapping to the cursor the
	# moment it is grabbed: picking it up must not move it at all.
	item._process(0.0)
	expect(item.position == home, "picking an item up does not move it")

	_press(item, false)
	expect(not item.dragging, "and releasing puts it down")

func _test_other_buttons_do_not_pick_items_up() -> void:
	print("other buttons")
	var m := _make()
	var item := _item(m, 0)
	_press(item, true, MOUSE_BUTTON_RIGHT)
	expect(not item.dragging, "a right-click does not pick an item up")
	var home: Vector2 = item.position
	item._process(0.0)
	expect(item.position == home, "so it stays where it is")

func _test_dropping_into_a_zone_parks_the_item() -> void:
	print("dropping in")
	var m := _make()
	var item := _item(m, 0)
	var zone := _zone(m, 0)
	zone.accept_drop(item)
	expect(item.position == zone.position, "the item snaps into the zone")
	expect(zone.has_item, "the zone is marked full")
	expect(m.filled == 1, "and the board counts it")

func _test_a_parked_item_stays_when_dragged_and_dropped_in_place() -> void:
	print("re-homing")
	var m := _make()
	var item := _item(m, 0)
	var zone := _zone(m, 0)
	zone.accept_drop(item)
	# Dropping into a zone makes that the item's new home, so a later drop on
	# empty space returns it to the zone rather than to the shelf it came from.
	expect(item.start_pos == zone.position, "the zone becomes the item's home")

func _test_the_counter_follows_the_filled_zones() -> void:
	print("the readout")
	var m := _make()
	var label: Label = m.get_node("StatusLabel")
	_zone(m, 0).accept_drop(_item(m, 0))
	expect(label.text.contains("1"), "the readout counts a filled zone")
	expect(not label.text.contains("All slots"), "and does not call it finished yet")

func _test_filling_every_zone_finishes_the_puzzle() -> void:
	print("finishing")
	var m := _make()
	var zones := m.get_node("Zones").get_children()
	var items := m.get_node("Items").get_children()
	for i in zones.size():
		zones[i].accept_drop(items[i])
	expect(m.filled == zones.size(), "every zone filled")
	expect((m.get_node("StatusLabel") as Label).text.contains("All slots"),
		"and the readout says so")
