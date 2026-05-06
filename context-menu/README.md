# Context Menu

A right-click context menu built entirely in GDScript using `_draw()` and `_input()`: no Control nodes, no PopupMenu — hover highlighting, screen-edge clamping, and callable action dispatch in a single script.

## Purpose

Context menus appear everywhere in games that give players agency over objects. Inventory screens let you right-click an item to inspect, equip, or drop it. Strategy games use them to issue orders to units or build structures at a map position. RPGs from *Baldur's Gate* to *Diablo* treat right-click as a primary interaction verb.

Godot's built-in `PopupMenu` works well for editor tooling, but in-game context menus usually need custom styling, icon support, and tight integration with game state. Building the menu with `_draw()` gives you pixel-level control over appearance and keeps the menu inside your scene's rendering pipeline — no Control theme inheritance to fight.

This demo also illustrates callable dispatch: menu items carry an `action` key holding a `Callable`, so adding a new menu option means appending one dictionary entry. No `match` branch, no enum expansion, no handler registration — the data is the configuration.

## How It Works

### Data Model

Each menu item is a dictionary with a label, a display color, and an action callable assigned at construction:

```gdscript
_menu_items = [
    {"label": "Spawn Circle",  "color": Color(0.25, 0.55, 1.0),  "action": _action_spawn_circle},
    {"label": "Spawn Square",  "color": Color(0.56, 0.93, 0.56), "action": _action_spawn_square},
    {"label": "Clear All",     "color": Color(1.0, 0.27, 0.0),   "action": _action_clear_all},
    {"label": "Change BG",     "color": Color(0.93, 0.51, 0.93), "action": _action_change_bg},
    {"label": "Show Info",     "color": Color(1.0, 0.84, 0.0),   "action": _action_show_info},
]
```

### Opening and Closing

```gdscript
if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
    _last_right_click = mb.position
    _menu_pos = _clamp_menu_pos(mb.position)
    _menu_visible = true

elif mb.button_index == MOUSE_BUTTON_LEFT and _menu_visible:
    var idx := _get_item_at_mouse(mb.position)
    if idx >= 0:
        _menu_items[idx]["action"].call()
    _menu_visible = false
```

The right-click position is stored separately in `_last_right_click` so spawn actions can place shapes at the cursor, even though the menu itself may have been repositioned by clamping. Escape also closes the menu without firing an action.

### Screen-Edge Clamping

```gdscript
func _clamp_menu_pos(click_pos: Vector2) -> Vector2:
    var pos := click_pos
    var menu_h := _menu_items.size() * ITEM_H
    if pos.x + MENU_W > 636.0:
        pos.x = 636.0 - MENU_W
    if pos.y + menu_h > 476.0:
        pos.y = 476.0 - menu_h
    return pos
```

Without clamping, menus near the right or bottom edge extend off-screen. Godot's `get_viewport_rect()` provides actual viewport dimensions for non-fixed-size projects.

### Hit Testing

```gdscript
func _get_item_at_mouse(mouse_pos: Vector2) -> int:
    if not _menu_visible:
        return -1
    var menu_rect := Rect2(_menu_pos, Vector2(MENU_W, _menu_items.size() * ITEM_H))
    if not menu_rect.has_point(mouse_pos):
        return -1
    return int((mouse_pos.y - _menu_pos.y) / ITEM_H)
```

`Rect2.has_point()` handles the outer bounds check in one call. Dividing the relative y offset by `ITEM_H` gives the row index. This same function is called on `InputEventMouseMotion` to update `_highlighted_item` for hover feedback without any per-item loop in the input handler.

### Drawing

Menu rendering order in `_draw()`: drop shadow → background rect → border rect → per-row highlight fill → color-square icon → label text. A `draw_line()` call after item index 2 ("Clear All") adds a visual separator between the creation actions and the utility actions.

## The Callable Dispatch Pattern

Storing a `Callable` in a data structure decouples the menu's rendering loop from the actions it triggers:

```gdscript
# Any number of items, one dispatch line:
_menu_items[idx]["action"].call()
```

This pattern scales cleanly to dynamic menus populated at runtime (e.g., an inventory's context menu built from an `Item` resource), and items are trivially reorderable without touching dispatch logic.

### Alternatives

- **`PopupMenu` node**: easiest for static menus, hard to style for in-game use.
- **Instanced scene per item**: more flexible for complex rows with nested controls, higher node count.
- **`match` dispatch**: straightforward but requires modifying two places (data array and match block) to add an item.

## How to Adapt This in Your Project

1. Move `_menu_items` construction into a context-aware function that takes the right-clicked object as an argument and builds the list dynamically.
2. Pass the target object into action callables using `.bind()` so each action knows what it was invoked on.
3. For an inventory, populate items from the hovered `Item` resource. For a map, read the tile type at the clicked cell.
4. Replace hard-coded viewport dimensions with `get_viewport_rect().size` for projects that support window resizing.
5. Add a submenu by storing a `"children"` key and rendering a nested panel offset to the right of the hovered row.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `InputEventMouseButton.button_index` | `MOUSE_BUTTON_LEFT` or `MOUSE_BUTTON_RIGHT` |
| `InputEventMouseButton.position` | Screen position of the click |
| `Rect2.has_point(pos)` | Point-in-rectangle test |
| `Callable.call()` | Invoke a stored method reference |
| `Node2D._draw()` | Override for immediate-mode rendering |
| `queue_redraw()` | Schedule a `_draw()` call next frame |
| `draw_rect()` / `draw_string()` / `draw_line()` | Drawing primitives inside `_draw()` |

## Controls

| Input | Action |
|-------|--------|
| Right-click | Open context menu at cursor |
| Left-click on item | Execute action and close menu |
| Left-click outside menu | Dismiss menu |
| Escape | Dismiss menu |

## Key Constants

```gdscript
const MENU_W  := 180.0  # menu panel width in pixels
const ITEM_H  := 34.0   # height of each menu row in pixels
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | All menu logic: data model, input, edge clamping, drawing |
| `scenes/main.tscn` | Single Node2D — no Control nodes |
| `tests/test_logic.gd` | Unit tests for hit-testing, clamping, and action dispatch |
