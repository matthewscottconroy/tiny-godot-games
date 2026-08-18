# Crafting System

<!-- tags: component, shows-its-working -->

Click two ingredient tiles from a grid of eight materials, press Craft, and get a result looked up from a Dictionary of sorted key pairs — with alphabetic normalization to make every recipe commutative.

## Purpose

Crafting systems appear in survival games, RPGs, adventure games, and city builders. The core mechanic is combining inputs to produce an output not directly obtainable elsewhere, which creates exploration, economy, and planning depth. The data engineering challenge is representing recipes efficiently: you need fast lookup, a clean way to handle commutative inputs (Wood + Iron should equal Iron + Wood), and a clear separation between the ingredient pool, the selection state, and the recipe table.

This demo shows the minimal version of that: eight ingredients, eight recipes, and a lookup key built from a sorted pair of ingredient names. The pattern — sort inputs alphabetically, join with a separator, check a Dictionary — is directly applicable to 2-ingredient, 3-ingredient, and component-based recipes in production games. No graph search, no set intersection: just one Dictionary key lookup.

## How It Works

### Recipe Dictionary

```gdscript
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
```

Keys are two ingredient names joined with `+`, sorted alphabetically. `"Fire+Wood"` not `"Wood+Fire"`. This means each recipe has exactly one key regardless of selection order.

### Commutative Lookup (`scripts/crafting_system.gd`)

The matching logic lives in a reusable class, `CraftingSystem`. Its `craft()`
sorts the ingredients so order never matters, then looks up the result:

```gdscript
func craft(ingredients: Array) -> String:
    return _recipes.get(_key(ingredients), "")   # "" = no match

func _key(ingredients: Array) -> String:
    var sorted := ingredients.duplicate()
    sorted.sort()                                # alphabetical
    return "+".join(sorted)
```

The demo's `_try_craft()` is now just UI feedback around it:

```gdscript
var result := _crafting.craft(_selected)
_result = "Crafted: %s!" % result if result != "" else "Unknown recipe"
```

`Array.sort()` sorts strings alphabetically, so `["Wood", "Fire"]` becomes the key `"Fire+Wood"` and matches the entry — neither order needs its own recipe. (This also scales to 3+ ingredients: `_key` joins however many you pass.)

### Selection State

```gdscript
func _toggle_ingredient(ing: String) -> void:
    var idx := _selected.find(ing)
    if idx >= 0:
        _selected.remove_at(idx)   # deselect
    else:
        if _selected.size() >= 2:
            _selected.pop_front()  # drop oldest (FIFO replacement)
        _selected.append(ing)
```

Maximum two selections enforced by `pop_front()` on the third click. The FIFO replacement means the oldest selection is forgotten first — the same behavior as most crafting games when you click a third ingredient.

## Recipe Lookup Design

**Sorted-string key** — the approach used here. Simple, zero dependencies, O(1) lookup. Works well for 2-ingredient recipes. For 3 ingredients, sort all three and join: `"A+B+C"`.

**Ingredient set (HashSet)** — store recipes as `Set<ingredient> → result`. Equivalent to sorted-string keys but avoids string building; common in compiled-language implementations.

**Fuzzy matching / partial recipes** — for games where quantity matters (2× Wood + 1× Iron), use a Dictionary key that includes counts: `"Iron:1+Wood:2"`. Sort the ingredient-count pairs alphabetically by ingredient name before joining.

**Recipe trees** — for deeply nested crafting (Potion → Greater Potion → Elixir), store each recipe as a node and support recursive lookup. The Dictionary approach here is intentionally flat; add a `"components"` Array and a recursive resolver for multi-tier systems.

## How to Adapt This in Your Project

- **Inventory integration**: Check that `_inventory.count(ing) >= 1` before allowing selection. On successful craft, call `_inventory.remove(ing)` for each ingredient and `_inventory.add(result)`.
- **Quantity recipes**: Add a `RECIPE_COSTS` Dictionary parallel to `RECIPES`: `"Fire+Wood": {"Fire": 1, "Wood": 2}`. Check and deduct each ingredient count individually.
- **Discoverable recipes**: Start with all recipes hidden. When a craft succeeds, add the key to a `_known_recipes: Array` and only show the recipe hint panel for known recipes.
- **Crafting time**: Add a `CRAFT_DURATIONS` Dictionary. When Craft is pressed, set `_crafting_timer = CRAFT_DURATIONS.get(key, 0.0)` and show a progress bar. Complete the craft when the timer expires.
- **Output quantities**: Change recipe values from strings to `{"name": "Torch", "count": 3}` Dictionaries to produce multiple outputs per craft.

## Use as a building block

**Copy:** `scripts/crafting_system.gd` (the `CraftingSystem` class). It's a `RefCounted` — no scene, no UI.

**Public API**
- `add_recipe(ingredients: Array, result: String) -> CraftingSystem` — register a recipe (order-independent); chainable.
- `craft(ingredients: Array) -> String` — the result, or `""` if no recipe matches.

**Integrate**
```gdscript
var crafting := CraftingSystem.new()
crafting.add_recipe(["Iron", "Wood"], "Sword").add_recipe(["Herbs", "Water"], "Potion")
var made := crafting.craft(player_selection)   # order doesn't matter
if made != "": inventory.add(made)
```

**Notes**
- `class_name CraftingSystem` is global — rename if it collides.
- Works for any number of ingredients — `_key` sorts and joins the whole array.
- For quantity recipes, encode counts in the ingredient strings (`"Iron:1"`, `"Wood:2"`) before passing them in; the commutative key logic is unchanged.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Array.sort()` | Alphabetical sort for commutative key generation |
| `Array.find(value)` | Check if ingredient is already selected |
| `Array.pop_front()` | FIFO replacement when selection is full |
| `Dictionary.has(key)` | Recipe existence check |
| `Rect2.has_point(pos)` | Hit-test click against ingredient box or Craft button |
| `String.begins_with(prefix)` | Detect success vs. failure in result string |

## Controls

| Input | Action |
|-------|--------|
| Left-click ingredient | Select it (yellow highlight); click again to deselect |
| Left-click 3rd ingredient | Oldest selection replaced, new one added |
| Left-click CRAFT button | Attempt craft with 2 selected ingredients |

## Key Constants

```gdscript
const INGREDIENTS := ["Wood", "Stone", "Iron", "Fire", "Water", "Herbs", "Cloth", "Gold"]

# 8 recipes, all 2-ingredient:
# Sorted key format: "IngA+IngB" where IngA < IngB alphabetically
# _selected: Array[String], max size 2

# Grid: 4 columns × 2 rows, BOX_W=100, BOX_H=80, BOX_GAP=8
# CRAFT_RECT: Rect2(240, 310, 120, 40)
```

## Recipes

| Ingredients | Result |
|-------------|--------|
| Fire + Wood | Torch |
| Iron + Wood | Sword |
| Iron + Stone | Axe |
| Stone + Wood | Hammer |
| Cloth + Wood | Tent |
| Herbs + Water | Potion |
| Gold + Stone | Gem Ring |
| Fire + Iron | Steel |

## Files

| File | Purpose |
|------|---------|
| `scripts/crafting_system.gd` | **`CraftingSystem`** — reusable commutative recipe book (`add_recipe`/`craft`) |
| `scripts/main.gd` | Ingredient grid, selection state, rendering; owns a `CraftingSystem` |
| `tests/test_logic.gd` | Unit tests: lookup, commutativity, unknown recipe, FIFO selection, post-craft clear |
| `scenes/main.tscn` | Scene root (Node2D with script) |
| `tests/test.tscn` | Test runner scene |

## Related demos

- [drop-table](../drop-table) — Weighted random loot; watch observed rates converge on expected probabilities.
- [experience-leveling](../experience-leveling) — XP collection and leveling on an exponential curve with stat gains.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

