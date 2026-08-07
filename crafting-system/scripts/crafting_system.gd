## A commutative recipe book. Register recipes by their ingredient set, then
## craft() looks up the result regardless of order — sorting the ingredients
## makes "Iron+Wood" and "Wood+Iron" the same recipe.
class_name CraftingSystem
extends RefCounted

var _recipes: Dictionary = {}   # sorted "A+B" key -> result

## Register a recipe. Ingredient order does not matter. Returns self so calls
## can be chained.
func add_recipe(ingredients: Array, result: String) -> CraftingSystem:
	_recipes[_key(ingredients)] = result
	return self

## Returns the crafted item, or "" if the ingredients don't match a recipe.
func craft(ingredients: Array) -> String:
	return _recipes.get(_key(ingredients), "")

func _key(ingredients: Array) -> String:
	var sorted := ingredients.duplicate()
	sorted.sort()
	return "+".join(sorted)
