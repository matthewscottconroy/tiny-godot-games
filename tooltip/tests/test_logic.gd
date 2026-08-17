extends Node

# Drives the real hover logic from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_items_are_laid_out()
	_test_nothing_is_hovered_to_start_with()
	_test_the_cursor_picks_out_an_item()
	_test_the_cursor_between_items_picks_nothing()
	_test_a_tooltip_waits_before_appearing()
	_test_a_tooltip_fades_in_rather_than_snapping()
	_test_moving_off_an_item_hides_the_tooltip()
	_test_crossing_items_restarts_the_wait()
	_test_the_tooltip_never_over_or_under_shoots()
	_test_the_tooltip_stays_on_screen()
	_report()

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

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _hover(m: Node2D, at: Vector2, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		m.tick(STEP, at)
		elapsed += STEP

func _item_pos(m: Node2D, i: int) -> Vector2:
	return m._items[i]["pos"]

## Somewhere with no item under it.
func _empty_space() -> Vector2:
	return Vector2(620.0, 60.0)

func _test_the_items_are_laid_out() -> void:
	print("the items")
	begin_quiet()
	var m := _make()
	expect(m._items.size() > 2, "there are several items to hover")
	for item in m._items:
		expect_quiet(item["title"] != "", "each has a title")
		expect_quiet(item["desc"] != "", "and a description")
		expect_quiet(item["radius"] > 0.0, "and a size to hit")
	expect(_quiet_failures == 0, "every item has a title, a description and a size")

func _test_nothing_is_hovered_to_start_with() -> void:
	print("before hovering")
	var m := _make()
	expect(m._hovered_idx == -1, "nothing is hovered")
	expect(is_zero_approx(m._tooltip_alpha), "and no tooltip is showing")

func _test_the_cursor_picks_out_an_item() -> void:
	print("hovering")
	var m := _make()
	m.tick(STEP, _item_pos(m, 2))
	expect(m._hovered_idx == 2, "the cursor over an item hovers that item")

	# Just inside the edge counts; just outside does not.
	var item: Dictionary = m._items[2]
	m.tick(STEP, item["pos"] + Vector2(item["radius"] - 2.0, 0.0))
	expect(m._hovered_idx == 2, "the edge of an item is still the item")
	m.tick(STEP, item["pos"] + Vector2(item["radius"] + 4.0, 0.0))
	expect(m._hovered_idx == -1, "and just past it is not")

func _test_the_cursor_between_items_picks_nothing() -> void:
	print("empty space")
	var m := _make()
	m.tick(STEP, _empty_space())
	expect(m._hovered_idx == -1, "the cursor over the background hovers nothing")

func _test_a_tooltip_waits_before_appearing() -> void:
	print("the delay")
	begin_quiet()
	var m := _make()
	# A tooltip that appears instantly flashes up whenever the cursor crosses
	# an item on its way somewhere else.
	_hover(m, _item_pos(m, 0), m.HOVER_DELAY * 0.5)
	expect(is_zero_approx(m._tooltip_alpha), "nothing shows before the delay is up")
	_hover(m, _item_pos(m, 0), m.HOVER_DELAY)
	expect(m._tooltip_alpha > 0.0, "and it appears once the cursor has settled")

	# Every item, not just the first: an index test that only holds for item
	# zero would leave the rest of the row silent.
	for i in range(1, m._items.size()):
		var each := _make()
		_hover(each, _item_pos(each, i), m.HOVER_DELAY + m.FADE_IN_TIME)
		expect_quiet(each._tooltip_alpha > 0.0, "item %d shows a tooltip too" % i)
	expect(_quiet_failures == 0, "and so does every other item in the row")

func _test_a_tooltip_fades_in_rather_than_snapping() -> void:
	print("fading in")
	var m := _make()
	_hover(m, _item_pos(m, 0), m.HOVER_DELAY + STEP * 2.0)
	var early: float = m._tooltip_alpha
	expect(early > 0.0 and early < 1.0, "the tooltip starts part-way faded in")
	_hover(m, _item_pos(m, 0), m.FADE_IN_TIME * 2.0)
	expect(is_equal_approx(m._tooltip_alpha, 1.0), "and reaches full opacity shortly after")

func _test_moving_off_an_item_hides_the_tooltip() -> void:
	print("moving away")
	var m := _make()
	_hover(m, _item_pos(m, 0), m.HOVER_DELAY + m.FADE_IN_TIME * 2.0)
	expect(is_equal_approx(m._tooltip_alpha, 1.0), "showing")
	m.tick(STEP, _empty_space())
	expect(is_zero_approx(m._tooltip_alpha), "moving off the item clears it at once")
	expect(m._hovered_idx == -1, "and nothing is hovered any more")

func _test_crossing_items_restarts_the_wait() -> void:
	print("crossing items")
	var m := _make()
	_hover(m, _item_pos(m, 0), m.HOVER_DELAY * 0.9)
	m.tick(STEP, _item_pos(m, 1))
	expect(m._hovered_idx == 1, "the cursor moves to the next item")
	expect(is_zero_approx(m._hover_timer), "and the wait starts again from nothing")
	_hover(m, _item_pos(m, 1), m.HOVER_DELAY * 0.5)
	expect(is_zero_approx(m._tooltip_alpha), "so no tooltip appears part-way through the crossing")

func _test_the_tooltip_never_over_or_under_shoots() -> void:
	print("bounds")
	var m := _make()
	_hover(m, _item_pos(m, 0), 5.0)
	expect(m._tooltip_alpha <= 1.0, "the fade stops at fully opaque")
	_hover(m, _empty_space(), 5.0)
	expect(m._tooltip_alpha >= 0.0, "and at fully transparent, rather than going negative")

var _quiet_failures := 0

## Counted rather than printed, for checks that run once per item. Each test
## zeroes the tally first, so one failure cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")

func _test_the_tooltip_stays_on_screen() -> void:
	print("placement")
	begin_quiet()
	var m := _make()
	var size := Vector2(220.0, 90.0)
	var box := Rect2(4.0, 4.0, 632.0, 472.0)

	var beside_cursor: Vector2 = m._clamp_tooltip_rect(Vector2(200.0, 200.0), size)
	expect(beside_cursor.x > 200.0 and beside_cursor.y > 200.0,
		"a tooltip in open space sits just off the cursor")

	# In the corners it has to tuck back in, or half of it is off the window.
	for corner in [Vector2(636.0, 476.0), Vector2(0.0, 476.0), Vector2(636.0, 0.0), Vector2(0.0, 0.0)]:
		var placed: Vector2 = m._clamp_tooltip_rect(corner, size)
		expect_quiet(box.encloses(Rect2(placed, size)),
			"a tooltip at %s is pulled back on screen" % corner)
	expect(_quiet_failures == 0, "the tooltip stays inside the window in every corner")
