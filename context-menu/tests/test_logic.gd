extends Node

# ---------------------------------------------------------------------------
# Minimal test harness
# ---------------------------------------------------------------------------
var _pass := 0
var _fail := 0


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


# ---------------------------------------------------------------------------
# Constants (mirror main.gd)
# ---------------------------------------------------------------------------
const MENU_W := 180.0
const ITEM_H := 34.0
const ITEM_COUNT := 5


func clamp_menu_pos(click_pos: Vector2) -> Vector2:
	var pos := click_pos
	var menu_h := ITEM_COUNT * ITEM_H
	if pos.x + MENU_W > 636.0:
		pos.x = 636.0 - MENU_W
	if pos.y + menu_h > 476.0:
		pos.y = 476.0 - menu_h
	return pos


func get_item_at(mouse_pos: Vector2, menu_pos: Vector2) -> int:
	var menu_h := ITEM_COUNT * ITEM_H
	var menu_rect := Rect2(menu_pos, Vector2(MENU_W, menu_h))
	if not menu_rect.has_point(mouse_pos):
		return -1
	var rel_y := mouse_pos.y - menu_pos.y
	return int(rel_y / ITEM_H)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
func _test_clamp_right() -> void:
	# click at x=550, menu_w=180 → 550+180=730 > 636 → clamped to 636-180=456
	var result := clamp_menu_pos(Vector2(550, 100))
	expect(result.x == 456.0, "_test_clamp_right: x clamped to 456")


func _test_clamp_bottom() -> void:
	# click at y=460, menu_h=5*34=170 → 460+170=630 > 476 → clamped to 476-170=306
	var result := clamp_menu_pos(Vector2(100, 460))
	expect(result.y == 306.0, "_test_clamp_bottom: y clamped to 306")


func _test_no_clamp_needed() -> void:
	# click at x=100, y=100 → no clamping needed
	var result := clamp_menu_pos(Vector2(100, 100))
	expect(result.x == 100.0, "_test_no_clamp_needed: x unchanged at 100")
	expect(result.y == 100.0, "_test_no_clamp_needed: y unchanged at 100")


func _test_item_click_detection() -> void:
	# menu at (200, 100); click at y = 100 + 34*1.5 = 151 → item index 1
	var menu_pos := Vector2(200.0, 100.0)
	var click := Vector2(210.0, 100.0 + ITEM_H * 1.5)
	var idx := get_item_at(click, menu_pos)
	expect(idx == 1, "_test_item_click_detection: hit item index 1 (got %d)" % idx)


func _test_outside_click_closes() -> void:
	# Simulate: click far outside menu rect → get_item_at returns -1
	var menu_pos := Vector2(200.0, 100.0)
	var outside_click := Vector2(50.0, 50.0)
	var idx := get_item_at(outside_click, menu_pos)
	# In main.gd, idx == -1 means close menu
	expect(idx == -1, "_test_outside_click_closes: outside click returns -1 (close)")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
func _ready() -> void:
	print("\n--- Running Context Menu Tests ---")
	_test_clamp_right()
	_test_clamp_bottom()
	_test_no_clamp_needed()
	_test_item_click_detection()
	_test_outside_click_closes()
	_report()
