# Data Tables

A Resource-based item database: items are defined as `ItemData` (a `Resource` subclass), stored in a typed array, and browseable through a filter-and-detail UI. Demonstrates the full pattern for structured game data in Godot.

## Purpose

Games have data — items, enemies, spells, levels, dialogue lines. A common mistake is scattering this data across `match` statements, hardcoded dictionaries, or exported node properties. Godot's `Resource` system offers a better path: data and schema live together, fields are typed, the Inspector can edit `.tres` files, and the asset pipeline handles loading automatically.

This demo shows the minimal production pattern: define a `Resource` subclass with `@export` fields (`ItemData`), populate an array of instances (`ItemDB`), and query them with filter functions. The population in this demo is done in code for self-containment — in a real project the identical class structure would be populated from `.tres` files on disk, loaded with `preload()` or `DirAccess`. The code that filters and displays the items does not change.

The alternative — `Dictionary` arrays — is fine for prototyping but loses type safety, breaks refactoring tools, and cannot be inspected in the editor. Use `Resource` subclasses whenever data has a fixed schema.

## How It Works

### The Schema (`scripts/item_data.gd`)

```gdscript
class_name ItemData
extends Resource

@export var item_name   := "Unknown"
@export var item_type   := "weapon"
@export var value       := 0
@export var weight      := 1.0
@export var rarity      := "common"
@export var color       := Color.GRAY
@export var description := ""
```

`class_name ItemData` registers the class globally. `extends Resource` means instances can be serialized as `.tres` files. Every `@export` field is editable in the Godot Inspector when a `.tres` file is open.

### The Database (`scripts/item_db.gd`)

```gdscript
var items: Array[ItemData] = []

func filter_by_type(t: String) -> Array[ItemData]:
    var out: Array[ItemData] = []
    for it in items:
        if it.item_type == t:
            out.append(it)
    return out

func filter_by_rarity(r: String) -> Array[ItemData]:
    var out: Array[ItemData] = []
    for it in items:
        if it.rarity == r:
            out.append(it)
    return out
```

`Array[ItemData]` is a typed array — GDScript's type checker rejects non-`ItemData` insertions. Filter functions return new typed arrays. The DB also exposes `find_by_name(n: String) -> ItemData` for direct lookups.

### Filtering and Display (`scripts/main.gd`)

```gdscript
func _get_filtered() -> Array[ItemData]:
    match _filter:
        "weapon":    return _db.filter_by_type("weapon")
        "armor":     return _db.filter_by_type("armor")
        "consumable":return _db.filter_by_type("consumable")
        "rare_plus":
            var out: Array[ItemData] = []
            for it in _db.items:
                if it.rarity in ["rare", "legendary"]:
                    out.append(it)
            return out
    return _db.items
```

The "Rare+" filter combines rarity values that don't map to a single `filter_by_rarity` call, showing that the DB query layer can be composed ad-hoc in the UI layer.

### Dynamic UI Construction

```gdscript
func _refresh_list() -> void:
    for child in _list_box.get_children():
        child.queue_free()
    for it in _get_filtered():
        var btn := Button.new()
        var rc := RARITY_COLOR.get(it.rarity, Color.WHITE)
        btn.text = "%s  [%s]" % [it.item_name, it.rarity]
        btn.add_theme_color_override("font_color", rc)
        var capture := it          # capture for closure
        btn.pressed.connect(func() -> void: _show_detail(capture))
        _list_box.add_child(btn)
```

Buttons are created and destroyed dynamically on each filter change. The `var capture := it` is required in GDScript closures inside loops — without it, all buttons would share the last value of `it`.

## Resource System Theory

Godot's `Resource` inherits from `RefCounted`, adding serialization support. Any `Resource` subclass with `@export` fields can be saved as a `.tres` (text) or `.res` (binary) file. The Godot editor treats them as first-class assets: you can create them in the FileSystem panel, edit them in the Inspector, and reference them in other resources.

**Production workflow**:
1. Define `class_name ItemData extends Resource` with `@export` fields
2. In the editor: FileSystem → New Resource → ItemData → fill fields in Inspector → save as `iron_sword.tres`
3. In code: `preload("res://data/items/iron_sword.tres") as ItemData`
4. Or load a directory: `DirAccess.get_files_at("res://data/items/")`

The code in this demo (creating instances in `_populate()`) is a stand-in for step 3/4. The filter and display code is identical either way.

**Rarity color mapping**:
```gdscript
const RARITY_COLOR := {
    "common":    Color(0.7, 0.7, 0.7),
    "uncommon":  Color(0.3, 0.85, 0.3),
    "rare":      Color(0.3, 0.5, 1.0),
    "legendary": Color(1.0, 0.7, 0.1),
}
```

This dictionary is the only place rarity → color is defined. The list and detail panels both use `RARITY_COLOR.get(it.rarity, Color.WHITE)`, so adding a new rarity requires one line here.

## How to Adapt This in Your Project

- To load from disk: replace `_populate()` with a loop over `DirAccess.get_files_at("res://data/items/")`, loading each file with `load(path) as ItemData`.
- To add a new field (e.g., `damage: int`), add `@export var damage := 0` to `item_data.gd`. All existing `.tres` files load without error; the new field defaults to 0.
- For sorted display, add `_db.items.sort_custom(func(a, b): return a.value < b.value)` before `_refresh_list()`.
- For a search box, filter `_db.items` by `it.item_name.to_lower().contains(search_text.to_lower())`.
- To share one database everywhere, hold an `ItemDB` inside an Autoload singleton (a small Node that does `var db := ItemDB.new()`), then call `Game.db.find_by_name("Fire Staff")`. (`ItemDB` is a `RefCounted`, so it can't be an Autoload directly — Autoloads must be Nodes.)

## Use as a building block

**Copy:** `scripts/item_data.gd` (`ItemData`) and `scripts/item_db.gd` (`ItemDB`). Both are self-contained — `ItemData` is a `Resource`, `ItemDB` is a `RefCounted`. Neither needs the demo's UI.

**Public API**
- `ItemData` — an `@export`ed data schema; add/remove fields freely.
- `ItemDB` — populates itself in `_init()`; exposes `items: Array[ItemData]`, `find_by_name(name)`, `filter_by_type(type)`, `filter_by_rarity(rarity)`.

**Integrate**
1. Replace `ItemDB._populate()` with your real data source — hand-authored `.tres` files loaded from a folder is the production pattern (see *Resource System Theory* above).
2. `var db := ItemDB.new()` — it's ready to query immediately (no tree, no `_ready()`).
3. Query with `db.find_by_name(...)` / `db.filter_by_type(...)`.

**Notes**
- `class_name ItemData` / `ItemDB` are global — rename if either collides with your project.
- Because `ItemDB` is `RefCounted`, it's freed automatically when no longer referenced; keep a reference (e.g. in an Autoload) to keep it alive.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Resource` | Base class for serializable data objects |
| `@export` | Makes a field visible and editable in the Inspector |
| `class_name ItemData` | Registers the class globally for type-safe use |
| `Array[ItemData]` | Typed array — GDScript enforces element types |
| `Button.pressed.connect(callable)` | Wire a button to a display function |
| `btn.add_theme_color_override("font_color", color)` | Tint button text by rarity |
| `node.queue_free()` | Safely remove a dynamically-created UI node |

## Controls

| Input | Action |
|-------|--------|
| Click filter buttons | All / Weapons / Armor / Consumable / Rare+ |
| Click item in list | Show full detail in the right panel |

## Files

| File | Purpose |
|------|---------|
| `scripts/item_data.gd` | `ItemData` Resource subclass — the data schema |
| `scripts/item_db.gd` | `ItemDB` (RefCounted) — array of items plus filter/lookup methods |
| `scripts/main.gd` | UI: filter buttons, item list, detail panel |
| `scenes/main.tscn` | `Control` root with `MainPanel`, filter row, list pane, detail pane |

## Related demos

- [custom-resource](../custom-resource) — `class_name` resources with `@export` vars as typed data containers.
- [inventory](../inventory) — A grid inventory: pick up, place, swap slots, and drop back to the world.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

