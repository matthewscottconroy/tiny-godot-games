extends Node

# Drives the real menu from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_menu_starts_closed()
	_test_the_wedges_cover_the_circle()
	_test_pointing_at_a_wedge_hovers_it()
	_test_the_hit_test_matches_the_drawn_wedges()
	_test_the_centre_is_a_dead_zone()
	_test_distance_beyond_the_ring_still_counts()
	_test_letting_go_selects_the_hovered_item()
	_test_letting_go_over_the_centre_selects_nothing()
	_test_the_selection_clears_the_hover()
	_test_the_result_label_reports_the_choice()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[radial-menu] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _menu(m: Node2D) -> Control:
	return m.get_node("RadialMenu")

## A point out along the angle at the centre of wedge `i`.
func _at_wedge(menu: Control, i: int, radius: float = 70.0) -> Vector2:
	var slice: float = TAU / float(menu.ITEMS.size())
	return menu.CENTER + Vector2.from_angle(float(i) * slice) * radius

func _test_the_menu_starts_closed() -> void:
	print("closed")
	var menu := _menu(_make())
	expect(not menu._open, "the menu is closed until the key is held")
	expect(menu._hovered == -1, "with nothing hovered")
	expect(menu.ITEMS.size() > 2, "and several items to choose between")

func _test_the_wedges_cover_the_circle() -> void:
	print("the ring")
	var menu := _menu(_make())
	expect(menu.INNER_R < menu.OUTER_R, "the ring has an inside and an outside")
	var seen := {}
	# Every direction should land on some wedge, and all of them should be
	# reachable — a gap would be a direction that selects nothing.
	for i in 360:
		var angle := TAU * float(i) / 360.0
		seen[menu.hovered_for(menu.CENTER + Vector2.from_angle(angle) * 70.0)] = true
	expect(seen.size() == menu.ITEMS.size(), "every wedge is reachable and no direction misses")
	expect(not seen.has(-1), "no direction outside the dead zone is unassigned")

func _test_pointing_at_a_wedge_hovers_it() -> void:
	print("hovering")
	var menu := _menu(_make())
	for i in menu.ITEMS.size():
		expect(menu.hovered_for(_at_wedge(menu, i)) == i,
			"pointing at the middle of wedge %d hovers item %d" % [i, i])

func _test_the_hit_test_matches_the_drawn_wedges() -> void:
	print("boundaries")
	var menu := _menu(_make())
	var slice: float = TAU / float(menu.ITEMS.size())
	# Wedges are drawn from half a slice before each item's angle to half a
	# slice after it, so the hit test has to agree at the edges.
	for i in menu.ITEMS.size():
		var just_inside_start: float = float(i) * slice - slice * 0.45
		var just_inside_end: float = float(i) * slice + slice * 0.45
		expect(menu.hovered_for(menu.CENTER + Vector2.from_angle(just_inside_start) * 70.0) == i,
			"the near edge of wedge %d belongs to it" % i)
		expect(menu.hovered_for(menu.CENTER + Vector2.from_angle(just_inside_end) * 70.0) == i,
			"and so does the far edge")

func _test_the_centre_is_a_dead_zone() -> void:
	print("the dead zone")
	var menu := _menu(_make())
	expect(menu.hovered_for(menu.CENTER) == -1, "the exact centre hovers nothing")
	expect(menu.hovered_for(menu.CENTER + Vector2(menu.INNER_R * 0.5, 0.0)) == -1,
		"and so does anywhere inside the inner radius — that is how you cancel")

func _test_distance_beyond_the_ring_still_counts() -> void:
	print("beyond the ring")
	var menu := _menu(_make())
	# Flicking the mouse well past the wedge is the natural gesture; it should
	# still pick the item in that direction.
	expect(menu.hovered_for(_at_wedge(menu, 1, 400.0)) == 1,
		"a long flick in a wedge's direction still picks that wedge")

func _test_letting_go_selects_the_hovered_item() -> void:
	print("selecting")
	var m := _make()
	var menu := _menu(m)
	var caught := {"index": -99, "label": ""}
	menu.item_selected.connect(func(i: int, l: String) -> void:
		caught["index"] = i
		caught["label"] = l)

	menu._hovered = 2
	menu._select()
	expect(caught["index"] == 2, "releasing selects whatever was hovered")
	expect(caught["label"] == menu.ITEMS[2]["label"], "and reports its label")

func _test_letting_go_over_the_centre_selects_nothing() -> void:
	print("cancelling")
	var m := _make()
	var menu := _menu(m)
	var fired := {"count": 0}
	menu.item_selected.connect(func(_i: int, _l: String) -> void: fired["count"] += 1)

	menu._hovered = -1
	menu._select()
	expect(fired["count"] == 0, "releasing with nothing hovered chooses nothing")

func _test_the_selection_clears_the_hover() -> void:
	print("after a choice")
	var menu := _menu(_make())
	menu._hovered = 3
	menu._select()
	expect(menu._hovered == -1, "the hover is cleared, so the next open starts fresh")

func _test_the_result_label_reports_the_choice() -> void:
	print("the readout")
	var m := _make()
	var menu := _menu(m)
	var label: Label = m.get_node("ResultLabel")
	menu._hovered = 1
	menu._select()
	expect(label.text.contains(menu.ITEMS[1]["label"]), "the label names the chosen item")
	expect(label.text.contains("1"), "and its index")
