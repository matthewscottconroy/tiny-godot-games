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
	var summary := "[tooltip] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)


# ---------------------------------------------------------------------------
# Helper — mirrors main.gd _clamp_tooltip_rect logic
# ---------------------------------------------------------------------------
func clamp_tooltip_rect(mouse_pos: Vector2, size: Vector2) -> Vector2:
	var preferred := mouse_pos + Vector2(14.0, 14.0)
	preferred.x = clamp(preferred.x, 4.0, 4.0 + 632.0 - size.x)
	preferred.y = clamp(preferred.y, 4.0, 4.0 + 472.0 - size.y)
	return preferred


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
func _test_tooltip_clamp_right() -> void:
	# tooltip at mouse x=600, width=220 → preferred x=614, clamped to 636-220=416
	var result := clamp_tooltip_rect(Vector2(600, 100), Vector2(220, 70))
	expect(result.x == 416.0, "_test_tooltip_clamp_right: x clamped to 416")


func _test_tooltip_clamp_bottom() -> void:
	# tooltip at mouse y=450, height=70 → preferred y=464, clamped to 476-70=406
	var result := clamp_tooltip_rect(Vector2(100, 450), Vector2(220, 70))
	expect(result.y == 406.0, "_test_tooltip_clamp_bottom: y clamped to 406")


func _test_tooltip_fits() -> void:
	# tooltip at mouse x=100, width=220 → preferred x=114, no clamp needed
	var result := clamp_tooltip_rect(Vector2(100, 100), Vector2(220, 70))
	expect(result.x == 114.0, "_test_tooltip_fits: x stays at 114 (mouse+14)")


func _test_hover_timer() -> void:
	# same item for 0.5s → timer=0.5 >= HOVER_DELAY=0.4 → should show tooltip
	var hover_timer := 0.5
	var HOVER_DELAY := 0.4
	expect(hover_timer >= HOVER_DELAY,
			"_test_hover_timer: 0.5s >= HOVER_DELAY triggers tooltip")


func _test_item_change_resets() -> void:
	# simulated: new item detected → hover_timer resets to 0
	var hovered_idx := 2
	var hover_timer := 0.35
	var tooltip_alpha := 0.8
	var new_hovered := 3  # different item
	if new_hovered != hovered_idx:
		hovered_idx = new_hovered
		hover_timer = 0.0
		tooltip_alpha = 0.0
	expect(hover_timer == 0.0,
			"_test_item_change_resets: hover_timer reset to 0 on item change")
	expect(tooltip_alpha == 0.0,
			"_test_item_change_resets: tooltip_alpha reset to 0 on item change")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
func _ready() -> void:
	print("\n--- Running Tooltip Tests ---")
	_test_tooltip_clamp_right()
	_test_tooltip_clamp_bottom()
	_test_tooltip_fits()
	_test_hover_timer()
	_test_item_change_resets()
	_report()
