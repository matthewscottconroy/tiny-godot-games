extends Node

# Drives the real menu from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_menu_starts_hidden()
	_test_right_click_opens_it_under_the_cursor()
	_test_the_menu_is_kept_on_screen()
	_test_the_menu_maps_the_cursor_to_an_item()
	_test_clicking_an_item_runs_it()
	_test_clicking_away_closes_without_running_anything()
	_test_spawning_uses_the_right_click_position()
	_test_colours_cycle_through_the_palette()
	_test_clear_empties_the_canvas()
	_test_the_background_cycles_and_comes_back_round()
	_test_the_log_keeps_only_the_last_few_lines()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[context-menu] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _click(m: Node2D, at: Vector2, button: int) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.position = at
	m._input(e)

## The middle of menu row `row`, in screen coordinates.
func _row_centre(m: Node2D, row: int) -> Vector2:
	return m._menu_pos + Vector2(m.MENU_W * 0.5, (row + 0.5) * m.ITEM_H)

func _item_named(m: Node2D, label: String) -> int:
	for i in m._menu_items.size():
		if m._menu_items[i]["label"] == label:
			return i
	return -1

func _test_the_menu_starts_hidden() -> void:
	print("closed")
	var m := _make()
	expect(not m._menu_visible, "no menu until it is asked for")
	expect(m._menu_items.size() > 0, "but the items are ready")

func _test_right_click_opens_it_under_the_cursor() -> void:
	print("opening")
	var m := _make()
	_click(m, Vector2(200.0, 150.0), MOUSE_BUTTON_RIGHT)
	expect(m._menu_visible, "right-click opens the menu")
	expect(m._menu_pos == Vector2(200.0, 150.0), "at the cursor")
	expect(m._highlighted_item == -1, "with nothing highlighted yet")

func _test_the_menu_is_kept_on_screen() -> void:
	print("staying on screen")
	var m := _make()
	# Right-clicking in the bottom-right corner would put most of the menu off
	# the window; it has to slide back into view instead.
	_click(m, Vector2(630.0, 470.0), MOUSE_BUTTON_RIGHT)
	var menu_h: float = m._menu_items.size() * m.ITEM_H
	expect(m._menu_pos.x + m.MENU_W <= 636.0, "the right edge stays in the window")
	expect(m._menu_pos.y + menu_h <= 476.0, "and so does the bottom")

	var roomy := _make()
	_click(roomy, Vector2(100.0, 100.0), MOUSE_BUTTON_RIGHT)
	expect(roomy._menu_pos == Vector2(100.0, 100.0), "a menu with room around it is not moved")

func _test_the_menu_maps_the_cursor_to_an_item() -> void:
	print("hit testing")
	var m := _make()
	_click(m, Vector2(200.0, 150.0), MOUSE_BUTTON_RIGHT)
	expect(m._get_item_at_mouse(_row_centre(m, 0)) == 0, "the top row is item 0")
	expect(m._get_item_at_mouse(_row_centre(m, 2)) == 2, "and the third row item 2")
	expect(m._get_item_at_mouse(m._menu_pos - Vector2(20.0, 20.0)) == -1,
		"a point outside the menu is no item")

	var closed := _make()
	expect(closed._get_item_at_mouse(Vector2(200.0, 150.0)) == -1,
		"and a closed menu has no items under the cursor at all")

func _test_clicking_an_item_runs_it() -> void:
	print("choosing an item")
	var m := _make()
	_click(m, Vector2(200.0, 150.0), MOUSE_BUTTON_RIGHT)
	_click(m, _row_centre(m, _item_named(m, "Spawn Circle")), MOUSE_BUTTON_LEFT)
	expect(m._shapes.size() == 1, "the item's action runs")
	expect(m._shapes[0]["type"] == "circle", "the one that was clicked")
	expect(not m._menu_visible, "and the menu closes behind it")

func _test_clicking_away_closes_without_running_anything() -> void:
	print("dismissing")
	var m := _make()
	_click(m, Vector2(200.0, 150.0), MOUSE_BUTTON_RIGHT)
	_click(m, Vector2(600.0, 60.0), MOUSE_BUTTON_LEFT)
	expect(not m._menu_visible, "clicking off the menu closes it")
	expect(m._shapes.is_empty(), "without running anything")

func _test_spawning_uses_the_right_click_position() -> void:
	print("where shapes appear")
	var m := _make()
	# The menu opens at the cursor and then the pointer moves onto an item, so
	# the shape has to remember where the right-click was, not where the left
	# click landed.
	var opened_at := Vector2(120.0, 90.0)
	_click(m, opened_at, MOUSE_BUTTON_RIGHT)
	_click(m, _row_centre(m, _item_named(m, "Spawn Square")), MOUSE_BUTTON_LEFT)
	expect(m._shapes[0]["pos"] == opened_at, "the square appears where the menu was opened")
	expect(m._shapes[0]["type"] == "square", "and is the shape that was picked")

func _test_colours_cycle_through_the_palette() -> void:
	print("colours")
	var m := _make()
	for i in m.SHAPE_COLORS.size() + 1:
		_click(m, Vector2(200.0, 150.0), MOUSE_BUTTON_RIGHT)
		_click(m, _row_centre(m, _item_named(m, "Spawn Circle")), MOUSE_BUTTON_LEFT)
	var palette_size: int = m.SHAPE_COLORS.size()
	expect(m._shapes.size() == palette_size + 1, "one shape per pick")
	expect(m._shapes[0]["color"] != m._shapes[1]["color"], "consecutive shapes differ in colour")
	expect(m._shapes[palette_size]["color"] == m._shapes[0]["color"],
		"and the palette comes back round rather than running off the end")

func _test_clear_empties_the_canvas() -> void:
	print("clear all")
	var m := _make()
	_click(m, Vector2(200.0, 150.0), MOUSE_BUTTON_RIGHT)
	_click(m, _row_centre(m, _item_named(m, "Spawn Circle")), MOUSE_BUTTON_LEFT)
	_click(m, Vector2(200.0, 150.0), MOUSE_BUTTON_RIGHT)
	_click(m, _row_centre(m, _item_named(m, "Clear All")), MOUSE_BUTTON_LEFT)
	expect(m._shapes.is_empty(), "clear all removes the shapes")

func _test_the_background_cycles_and_comes_back_round() -> void:
	print("background")
	var m := _make()
	var first: Color = m._bg_color
	m._action_change_bg()
	expect(m._bg_color != first, "the background changes")
	var seen := {first: true, m._bg_color: true}
	for i in 8:
		m._action_change_bg()
		seen[m._bg_color] = true
	expect(seen.size() > 2, "through several colours")
	expect(m._bg_color == first or seen.has(first), "and returns to where it started")

func _test_the_log_keeps_only_the_last_few_lines() -> void:
	print("the log")
	var m := _make()
	for i in 12:
		m._action_show_info()
	expect(m._log.size() <= 5, "the log is trimmed rather than growing forever")
	expect(m._log.size() > 0, "and keeps the recent lines")
