extends Node

# Drives the real CraftingSystem from scripts/crafting_system.gd rather than a
# copy of its lookup logic, so a change to the component is visible here.

var _pass := 0
var _fail := 0


func _ready() -> void:
	_test_recipe_lookup()
	_test_recipe_sort()
	_test_unknown_recipe()
	_test_add_recipe_chains()
	_test_recipe_can_be_overwritten()
	_test_max_selection()
	_report()


func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)


func _report() -> void:
	var summary := "[crafting-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)


func _make_book() -> CraftingSystem:
	var book := CraftingSystem.new()
	book.add_recipe(["Cloth", "Wood"], "Tent")
	book.add_recipe(["Fire", "Wood"], "Torch")
	book.add_recipe(["Iron", "Stone"], "Axe")
	book.add_recipe(["Iron", "Wood"], "Sword")
	book.add_recipe(["Herbs", "Water"], "Potion")
	return book


func _test_recipe_lookup() -> void:
	expect(_make_book().craft(["Fire", "Wood"]) == "Torch", "Recipe lookup: Fire+Wood = Torch")


func _test_recipe_sort() -> void:
	# The point of the component: ingredients are sorted into a canonical key, so
	# order does not matter at the call site.
	var book := _make_book()
	expect(book.craft(["Wood", "Fire"]) == book.craft(["Fire", "Wood"]),
		"Recipe sort: Wood+Fire == Fire+Wood (commutative)")
	expect(book.craft(["Wood", "Fire"]) == "Torch", "Recipe sort: Wood+Fire = Torch")


func _test_unknown_recipe() -> void:
	# craft() reports a miss with "", leaving the wording of the failure to the UI.
	expect(_make_book().craft(["Fire", "Water"]) == "", "Unknown combination returns an empty string")


func _test_add_recipe_chains() -> void:
	var book := CraftingSystem.new()
	var returned := book.add_recipe(["Gold", "Stone"], "Gem Ring")
	expect(returned == book, "add_recipe returns self so registrations can chain")
	book.add_recipe(["Fire", "Iron"], "Steel").add_recipe(["Stone", "Wood"], "Hammer")
	expect(book.craft(["Iron", "Fire"]) == "Steel", "chained registration: Fire+Iron = Steel")
	expect(book.craft(["Wood", "Stone"]) == "Hammer", "chained registration: Stone+Wood = Hammer")


func _test_recipe_can_be_overwritten() -> void:
	var book := CraftingSystem.new()
	book.add_recipe(["Iron", "Wood"], "Sword")
	book.add_recipe(["Wood", "Iron"], "Spear")   # same canonical key
	expect(book.craft(["Iron", "Wood"]) == "Spear", "re-registering a key replaces the result")


func _test_max_selection() -> void:
	# The demo's UI keeps at most two selected ingredients, dropping the oldest.
	var selected: Array[String] = ["Wood", "Fire"]
	if selected.size() >= 2:
		selected.pop_front()
	selected.append("Iron")
	expect(selected.size() == 2, "Max selection: only 2 ingredients selected")
	expect(selected[0] == "Fire", "Max selection: oldest replaced, Fire remains")
	expect(selected[1] == "Iron", "Max selection: newest added (Iron)")
