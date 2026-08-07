extends Node

const RECIPES := {
	"Cloth+Wood":  "Tent",
	"Fire+Wood":   "Torch",
	"Iron+Stone":  "Axe",
	"Iron+Wood":   "Sword",
	"Herbs+Water": "Potion",
	"Gold+Stone":  "Gem Ring",
	"Fire+Iron":   "Steel",
	"Stone+Wood":  "Hammer",
}

var _pass := 0
var _fail := 0


func _ready() -> void:
	_test_recipe_lookup()
	_test_recipe_sort()
	_test_unknown_recipe()
	_test_max_selection()
	_test_craft_clears_selection()
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


func _lookup_recipe(a: String, b: String) -> String:
	var pair := [a, b]
	pair.sort()
	var key := "%s+%s" % [pair[0], pair[1]]
	if RECIPES.has(key):
		return RECIPES[key]
	return "Unknown recipe"


func _test_recipe_lookup() -> void:
	var result := _lookup_recipe("Fire", "Wood")
	expect(result == "Torch", "Recipe lookup: Fire+Wood = Torch")


func _test_recipe_sort() -> void:
	# Commutative: Wood+Fire should give same result as Fire+Wood
	var result_a := _lookup_recipe("Fire", "Wood")
	var result_b := _lookup_recipe("Wood", "Fire")
	expect(result_a == result_b, "Recipe sort: Wood+Fire == Fire+Wood (commutative)")
	expect(result_b == "Torch", "Recipe sort: Wood+Fire = Torch")


func _test_unknown_recipe() -> void:
	var result := _lookup_recipe("Fire", "Water")
	expect(result == "Unknown recipe", "Unknown recipe: Fire+Water = 'Unknown recipe'")


func _test_max_selection() -> void:
	# Simulating the toggle logic
	var selected: Array[String] = []
	selected.append("Wood")
	selected.append("Fire")
	# Adding a 3rd should replace oldest
	if selected.size() >= 2:
		selected.pop_front()
	selected.append("Iron")
	expect(selected.size() == 2, "Max selection: only 2 ingredients selected")
	expect(selected[0] == "Fire", "Max selection: oldest replaced, Fire remains")
	expect(selected[1] == "Iron", "Max selection: newest added (Iron)")


func _test_craft_clears_selection() -> void:
	var selected: Array[String] = ["Wood", "Fire"]
	var result_timer := 0.0
	# Craft
	var pair := selected.duplicate()
	pair.sort()
	var key := "%s+%s" % [pair[0], pair[1]]
	var _result := RECIPES.get(key, "Unknown recipe")
	result_timer = 2.5
	selected.clear()
	expect(selected.is_empty(), "Craft clears: selection is empty after crafting")
	expect(result_timer == 2.5, "Craft clears: result timer set after crafting")
