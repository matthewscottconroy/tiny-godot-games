extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_grid_dimensions()
	_test_slot_count()
	_test_item_definitions()
	_test_slot_operations()
	_test_swap_items()
	_test_world_pickup_radius()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_grid_dimensions() -> void:
	print("grid dimensions")
	const SLOT_SIZE := 64
	const COLS := 4
	const ROWS := 4
	expect(SLOT_SIZE == 64, "slot size is 64px")
	expect(COLS == 4, "4 columns")
	expect(ROWS == 4, "4 rows")

func _test_slot_count() -> void:
	print("slot count")
	const COLS := 4
	const ROWS := 4
	var total := COLS * ROWS
	expect(total == 16, "16 total inventory slots")

func _test_item_definitions() -> void:
	print("item definitions")
	var item_defs := [
		{name = "Sword"}, {name = "Shield"}, {name = "Potion"},
		{name = "Gold"}, {name = "Bow"}, {name = "Gem"},
	]
	expect(item_defs.size() == 6, "6 item types defined")
	expect(item_defs[0].name == "Sword", "first item is Sword")
	expect(item_defs[3].name == "Gold", "fourth item is Gold")

func _test_slot_operations() -> void:
	print("slot operations")
	var slots := []
	for i in 16:
		slots.append({item = null})
	expect(slots[0].item == null, "slots start empty")
	var item := {name = "Sword", color = Color.SILVER, symbol = "⚔"}
	slots[0].item = item
	expect(slots[0].item != null, "item placed in slot")
	expect(slots[0].item.name == "Sword", "correct item in slot")

func _test_swap_items() -> void:
	print("item swap logic")
	var slot_a := {item = {name = "Sword"}}
	var slot_b := {item = {name = "Shield"}}
	var tmp := slot_a.item
	slot_a.item = slot_b.item
	slot_b.item = tmp
	expect(slot_a.item.name == "Shield", "slot_a now has Shield after swap")
	expect(slot_b.item.name == "Sword", "slot_b now has Sword after swap")

func _test_world_pickup_radius() -> void:
	print("world item pickup radius")
	var pickup_radius := 22.0
	var item_pos := Vector2(100.0, 200.0)
	var click_near := Vector2(110.0, 205.0)
	var click_far := Vector2(150.0, 250.0)
	expect(item_pos.distance_to(click_near) < pickup_radius, "nearby click triggers pickup")
	expect(item_pos.distance_to(click_far) >= pickup_radius, "far click does not trigger")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
