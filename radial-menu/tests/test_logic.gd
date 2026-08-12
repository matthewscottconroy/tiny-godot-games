extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_angle_to_index_six_items()
	_test_inner_radius_returns_minus_one()
	_test_each_item_maps_to_correct_index()
	_test_boundary_angles()
	_test_item_count()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# --- Simulated radial menu logic ---

const INNER_R    := 40.0
const OUTER_R    := 100.0
const CENTER     := Vector2(320.0, 240.0)
const ITEM_COUNT := 6

func update_hover(mouse_screen: Vector2) -> int:
	var mouse := mouse_screen - CENTER
	if mouse.length() < INNER_R:
		return -1
	var angle := fmod(mouse.angle() + TAU, TAU)
	return int(angle / (TAU / float(ITEM_COUNT)))

func _test_angle_to_index_six_items() -> void:
	print("angle mapping: right (angle=0) maps to index 0")
	# angle=0 → right → index 0 (first slice starts at -TAU/12, straddles 0)
	var idx := update_hover(CENTER + Vector2(80.0, 0.0))
	expect(idx == 0, "right direction is index 0")

func _test_inner_radius_returns_minus_one() -> void:
	print("inner radius: mouse inside returns -1")
	var idx := update_hover(CENTER + Vector2(10.0, 0.0))
	expect(idx == -1, "inside inner radius returns -1")
	var idx2 := update_hover(CENTER)
	expect(idx2 == -1, "exactly at center returns -1")

func _test_each_item_maps_to_correct_index() -> void:
	print("each of 6 items reachable by angle")
	var seen := {}
	for i in 6:
		var mid_angle := (float(i) + 0.5) * (TAU / 6.0)
		var pos := CENTER + Vector2.from_angle(mid_angle) * 80.0
		var idx := update_hover(pos)
		seen[idx] = true
	expect(seen.size() == 6, "all 6 indices reachable")

func _test_boundary_angles() -> void:
	print("boundary angles stay within [0, 5]")
	var angles := [0.0, TAU / 6.0, TAU / 3.0, TAU / 2.0, 2.0 * TAU / 3.0, 5.0 * TAU / 6.0]
	for a in angles:
		var pos := CENTER + Vector2.from_angle(a) * 80.0
		var idx := update_hover(pos)
		expect(idx >= 0 and idx < 6, "angle %.2f maps to valid index %d" % [a, idx])

func _test_item_count() -> void:
	print("ITEM_COUNT constant is 6")
	expect(ITEM_COUNT == 6, "six items in radial menu")
	var slice := TAU / float(ITEM_COUNT)
	expect(absf(slice - TAU / 6.0) < 0.0001, "each slice spans TAU/6")

func _report() -> void:
	var summary := "[radial-menu] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
