# Data Tables

A Resource-based item database: items are defined as `ItemData` (a `Resource` subclass with `@export` fields), stored in an `Array[ItemData]`, and browseable through a filter+detail UI. Shows how to use Godot's Resource system as a structured data layer.

## Purpose

Games have data — items, enemies, spells, quests. A common mistake is hardcoding this data in dictionaries or match statements scattered across scripts. Resources offer a better path: data and schema in one place, type-safe, inspectable in the editor, and saveable as `.tres` files. This demo shows the minimal pattern: define a `Resource` subclass with `@export` fields, populate an array of instances, and query them with filter functions.

## Controls

- **Click filter buttons** (All / Weapons / Armor / Consumable / Rare+) to filter the list
- **Click any item** in the list to see its full detail in the right panel

## How It Works

### `scripts/item_data.gd`

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

This is the schema. Every item in the game is an instance of this class. In a real project, these would be `.tres` files saved on disk that Godot's import system handles. In this demo they're created in code, but the structure is identical.

### `scripts/item_db.gd`

```gdscript
var items: Array[ItemData] = []

func filter_by_type(t: String) -> Array[ItemData]:
    var out: Array[ItemData] = []
    for it in items:
        if it.item_type == t:
            out.append(it)
    return out
```

The DB holds an `Array[ItemData]` — typed, so GDScript's type checker catches misuse. Filter functions return new typed arrays. The explicit loop is clearer than the built-in `filter()` lambda for newcomers, and avoids an `as Array[ItemData]` cast.

### Real-project workflow

In production you'd do:
1. Create `ItemData` as a `class_name` resource
2. In the editor, create `.tres` files: `File → New Resource → ItemData`
3. Fill in the exported fields in the Inspector
4. Preload or load them: `preload("res://data/iron_sword.tres")`
5. Or use a directory scan: `DirAccess.get_files_at("res://data/items/")`

The code structure in this demo works identically — only the population method changes.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Resource` | Base for any data object that can be saved as `.tres` |
| `@export` | Makes a field editable in the Inspector |
| `Array[Type]` | Typed array — GDScript enforces element types |
| `class_name ItemData` | Registers the class globally so other scripts can use it |
| `RefCounted` vs `Resource` | Resources can be saved to disk; RefCounted cannot |
