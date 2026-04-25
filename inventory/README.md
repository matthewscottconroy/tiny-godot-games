# Inventory

Implements a grid-based inventory system — picking up world items, placing them in slots, swapping between slots, and dropping back to the world — using `GridContainer` and `Button` nodes.

## Purpose

Inventory systems appear in nearly every RPG, crafting, or adventure game. The core challenge is managing a "held item" cursor state cleanly. This demo shows the canonical approach: a single `_held_item` dictionary that represents what the player is currently carrying, and a unified `_on_slot_clicked(idx)` handler that routes through all cases (empty → place, full → swap, same → drop).

## Controls

- **Left-click a world item**: Pick it up (it disappears from the world and attaches to the cursor)
- **Left-click an inventory slot (while holding)**: Place the item; if slot is full, swap
- **Right-click an inventory slot**: Drop the item back to the world near its original position
- Move the mouse with a held item to see the cursor follow

## How It Works

### Node Tree

```
Main (Control)              ← main.gd
├── WorldItems (Node2D)     ← world items drawn here
└── Inventory (PanelContainer)
    └── VBox
        └── GridContainer (columns=4)
            └── [16 Button slots]
```

### `scripts/main.gd`

- **`ITEM_DEFS`** — Array of `{name, color, symbol}` dictionaries defining the 6 item types.
- **`_slots`** — Array of 16 `{item or null}` entries. `null` means the slot is empty.
- **`_held_item`** — Dictionary with the currently carried item (or `{}` when nothing is held). Also tracks `mouse_pos` for the cursor indicator.
- **`_on_slot_clicked(idx)`** — The state machine: if holding and slot empty → place; if holding and slot full → swap; if not holding and slot full → pick up.
- **`_draw()`** — Renders world items as colored circles with letter symbols. When `_held_item` is non-empty, draws a copy of the item following the mouse cursor.

### The Held Item Pattern

A single `_held_item` variable replaces complex drag-and-drop state. The item doesn't move between nodes — it's just a dictionary that `_draw()` renders at the mouse position. This avoids all the complexity of dragging actual scene nodes around.

### GridContainer

`GridContainer` arranges its children in a grid with a fixed number of columns. Children are added left-to-right, top-to-bottom. Changing `columns` at runtime relayouts automatically. This makes it trivial to display different inventory widths.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `GridContainer.columns` | Number of columns in the grid |
| `Button.pressed.connect(callable)` | Click handler for each slot |
| `Button.text` | Set the item symbol displayed |
| `Button.modulate` | Tint the button to show item color |
| `Control.get_global_mouse_position()` | Cursor position in global space |
| `InputEventMouseButton.button_index` | Distinguish left vs right click |
