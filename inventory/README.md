# Inventory

A grid-based inventory: pick up world items into a "held item" cursor, place them into slots, swap between slots, and drop back to the world — all through a single click handler and a `GridContainer` of Button nodes.

## Purpose

Inventory systems appear in nearly every RPG, crafting game, survival title, and adventure game. The central challenge is not the data model (an array of slots) but the interaction state: what does it mean to click a slot when you're holding something vs. not? This demo shows the canonical held-item cursor pattern — a single `_held_item` dictionary that represents what the player is currently carrying. The interaction logic collapses to one function with three branches, and the rendering of the cursor item is just `_draw()` painting at the mouse position. No drag-and-drop nodes, no complex event routing.

The architecture keeps world items and inventory slots in completely separate arrays (`_world_items` and `_slots`), connected only through the shared item definition format. This separation makes it straightforward to serialize, display in multiple UIs simultaneously, or extend with item categories and weight systems.

## How It Works

### Node Tree

```
Main (Control)              ← main.gd
├── WorldItems (Node2D)     ← world items rendered here via _draw()
└── Inventory (PanelContainer)
    └── VBox
        └── GridContainer (columns=4)
            └── [16 Button slots]
```

### Item Definition Format

```gdscript
const ITEM_DEFS := [
    {"name": "Ruby",    "color": Color(0.9, 0.1, 0.1), "symbol": "R"},
    {"name": "Emerald", "color": Color(0.1, 0.8, 0.2), "symbol": "E"},
    # ...
]
```

Items are plain Dictionaries with `name`, `color`, and `symbol`. `null` in a slot means empty.

### The Held-Item Pattern

```gdscript
var _held_item: Dictionary = {}   # empty dict = nothing held
var _slots: Array = []            # 16 entries, each null or item dict
```

`_on_slot_clicked(idx)` is the single handler for all slot interactions:

```gdscript
func _on_slot_clicked(idx: int) -> void:
    if _held_item.is_empty():
        if _slots[idx] != null:          # pick up
            _held_item = _slots[idx]
            _slots[idx] = null
    else:
        var temp = _slots[idx]
        _slots[idx] = _held_item         # place or swap
        _held_item = temp if temp != null else {}
```

If `_held_item` is empty, a non-empty slot picks up its item. If `_held_item` is non-empty, the slot contents swap with the held item — an empty slot simply places, a full slot swaps, and clicking the same item twice returns it to the slot (swap with `{}` then normalize).

### Cursor Rendering

The held item doesn't move between nodes — `_draw()` paints it at the mouse position every frame:

```gdscript
if not _held_item.is_empty():
    draw_circle(mouse_pos, 18, _held_item["color"])
    draw_string(font, mouse_pos + Vector2(-6, 5),
        _held_item["symbol"], ...)
```

This avoids all the complexity of dragging actual scene nodes and works correctly regardless of UI scaling or canvas transforms.

## Inventory Design Considerations

**Slot-based vs. weight-based**: This demo uses a fixed 16-slot grid. Weight-based inventories store a `weight` field per item and sum against a `max_carry_weight` constant. They are more realistic but require sorting UI and often frustrate players — most modern games prefer slot limits.

**Stacking**: To allow stacking, add a `"count": int` field to item dictionaries. When placing into a slot with the same `name`, increment `count` instead of filling a new slot.

**Right-click to drop**: Right-click on a slot removes the item from `_slots[idx]` and instantiates it back in the world at a position near `_world_items_origin`. This demo supports it via `InputEventMouseButton.button_index == MOUSE_BUTTON_RIGHT`.

**Serialization**: Because items are plain Dictionaries, `JSON.stringify(_slots)` works directly (with `null` converted to JSON null). On load, use `JSON.parse_string()` and restore the array.

## How to Adapt This in Your Project

- **More columns**: Change `GridContainer.columns` to 6 for a wider grid; add more entries to `_slots`. The rest of the code adapts automatically.
- **Equipment slots**: Add named `_equipment: Dictionary` (`{"head": null, "chest": null, ...}`) alongside `_slots`. Route equip-compatible items to equipment slots on right-click.
- **Item categories / filters**: Add a `"type": "weapon"|"consumable"` field to item defs and check it before allowing placement into restricted slots.
- **Tooltip on hover**: Connect `Button.mouse_entered` to show a tooltip Label with `_slots[idx]["name"]` and any stats.
- **Drag between multiple inventories**: Use a global `HeldItemManager` Autoload so merchant inventory and player inventory share the same `_held_item` state.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `GridContainer.columns` | Number of columns in the slot grid |
| `Button.pressed.connect(callable)` | Per-slot click handler |
| `Button.text` | Symbol shown on the slot button |
| `Button.modulate` | Tint button to show item color |
| `Control.get_global_mouse_position()` | Cursor position for rendering held item |
| `InputEventMouseButton.button_index` | Distinguish left vs right click |
| `Dictionary.is_empty()` | Check whether `_held_item` is the empty sentinel |

## Controls

| Input | Action |
|-------|--------|
| Left-click world item | Pick it up into the cursor |
| Left-click empty slot (holding) | Place held item into slot |
| Left-click full slot (holding) | Swap held item with slot contents |
| Left-click full slot (not holding) | Pick up slot item |
| Right-click full slot | Drop slot item back to world |

## Key Constants / Data

```gdscript
# 6 item types; 16 inventory slots (4×4 GridContainer)
# _held_item: {} means nothing held; non-empty dict = item being carried
# _slots: Array of 16 entries — null = empty, Dictionary = item
# World items rendered as colored circles with symbol letters in _draw()
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Item definitions, slot array, held-item logic, rendering |
| `scenes/main.tscn` | Scene with Control root, GridContainer, Button slots |
