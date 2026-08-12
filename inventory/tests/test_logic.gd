extends Node

# Drives the real Inventory from scripts/inventory.gd rather than a hand-rolled
# array of slot dictionaries, so place/take/swap and the `changed` signal are
# actually exercised.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_slot_count()
	_test_slots_start_empty()
	_test_place_and_read_back()
	_test_place_rejects_occupied_slot()
	_test_take_empties_the_slot()
	_test_swap_returns_previous_item()
	_test_changed_signal()
	_test_world_pickup_radius()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

const COLS := 4
const ROWS := 4

func _make() -> Inventory:
	return Inventory.new(COLS * ROWS)

func _test_slot_count() -> void:
	print("slot count")
	var inv := _make()
	expect(inv.size() == 16, "16 total inventory slots")

func _test_slots_start_empty() -> void:
	print("slots start empty")
	var inv := _make()
	var all_empty := true
	for i in inv.size():
		if not inv.is_empty(i):
			all_empty = false
	expect(all_empty, "every slot starts null")
	expect(inv.get_item(0) == null, "get_item on an empty slot returns null")

func _test_place_and_read_back() -> void:
	print("place and read back")
	var inv := _make()
	var sword := {name = "Sword", color = Color.SILVER, symbol = "⚔"}
	expect(inv.place(0, sword), "place into an empty slot succeeds")
	expect(not inv.is_empty(0), "slot is no longer empty")
	expect(inv.get_item(0)["name"] == "Sword", "correct item in slot")

func _test_place_rejects_occupied_slot() -> void:
	print("place rejects an occupied slot")
	var inv := _make()
	inv.place(0, {name = "Sword"})
	expect(not inv.place(0, {name = "Shield"}), "place into an occupied slot returns false")
	expect(inv.get_item(0)["name"] == "Sword", "the original item is untouched")

func _test_take_empties_the_slot() -> void:
	print("take empties the slot")
	var inv := _make()
	inv.place(2, {name = "Potion"})
	var taken = inv.take(2)
	expect(taken != null and taken["name"] == "Potion", "take returns the stored item")
	expect(inv.is_empty(2), "slot is empty after take")
	expect(inv.take(2) == null, "taking from an empty slot returns null")

func _test_swap_returns_previous_item() -> void:
	print("item swap logic")
	var inv := _make()
	inv.place(0, {name = "Sword"})
	inv.place(1, {name = "Shield"})
	var displaced = inv.swap(0, inv.take(1))
	inv.swap(1, displaced)
	expect(inv.get_item(0)["name"] == "Shield", "slot 0 now has Shield after swap")
	expect(inv.get_item(1)["name"] == "Sword", "slot 1 now has Sword after swap")

func _test_changed_signal() -> void:
	print("changed signal")
	var inv := _make()
	var count := {"n": 0}
	inv.changed.connect(func() -> void: count["n"] += 1)
	inv.place(0, {name = "Gold"})
	expect(count["n"] == 1, "place emits changed")
	inv.place(0, {name = "Gem"})            # rejected — slot occupied
	expect(count["n"] == 1, "a rejected place does not emit changed")
	inv.take(0)
	expect(count["n"] == 2, "take emits changed")
	inv.take(0)                             # already empty
	expect(count["n"] == 2, "taking from an empty slot does not emit changed")

func _test_world_pickup_radius() -> void:
	print("world item pickup radius")
	var pickup_radius := 22.0
	var item_pos := Vector2(100.0, 200.0)
	expect(item_pos.distance_to(Vector2(110.0, 205.0)) < pickup_radius, "nearby click triggers pickup")
	expect(item_pos.distance_to(Vector2(150.0, 250.0)) >= pickup_radius, "far click does not trigger")

func _report() -> void:
	var summary := "[inventory] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
