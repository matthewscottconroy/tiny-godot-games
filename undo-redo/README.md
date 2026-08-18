# Undo / Redo

<!-- tags: ui -->

A freehand drawing canvas demonstrating Godot 4's built-in `UndoRedo` class. Draw strokes with the mouse; undo and redo them with Ctrl+Z / Ctrl+Y. The history stack is managed entirely by `UndoRedo` — no manual stack code required.

## Purpose

Undo/redo is expected in any game that lets players build, paint, or configure something: map editors, puzzle games with move history, level editors, ship-building games, colony builders. Without it, a misclick in a complex layout forces the player to undo all their work manually. With it, experimentation feels safe.

The undo/redo problem is harder than it looks. A naive implementation keeps a snapshot of the entire state before each action. That works for small states but becomes expensive when the state is large (a 512×512 tilemap, a scene with hundreds of nodes). The command pattern — recording what was done and how to reverse it — is the standard solution. Godot's `UndoRedo` class implements this pattern directly, handling the stack, redo invalidation on new actions, and history introspection.

Beyond game features, this is the same pattern used by Godot's own editor. Understanding `UndoRedo` is directly transferable to writing editor plugins.

## How It Works

### The Four-Step Pattern

Every undoable action follows the same four-step sequence:

```gdscript
func _commit_stroke() -> void:
    var stroke := _current_stroke.duplicate()
    _undo_redo.create_action("Draw Stroke")
    _undo_redo.add_do_method(self, "_add_stroke", stroke)
    _undo_redo.add_undo_method(self, "_remove_last_stroke")
    _undo_redo.commit_action()
    _update_history()
```

1. `create_action(name)` — opens a new action with a human-readable name.
2. `add_do_method(obj, method, args...)` — records what to call when the action is done (or redone).
3. `add_undo_method(obj, method, args...)` — records what to call when the action is undone.
4. `commit_action()` — closes the action, pushes it onto the stack, and **immediately calls the do-method**.

Because `commit_action()` calls `_add_stroke()` immediately, you do not need to apply the action manually before committing.

### Do and Undo Methods

```gdscript
func _add_stroke(stroke: PackedVector2Array) -> void:
    _strokes.append(stroke)
    queue_redraw()

func _remove_last_stroke() -> void:
    if _strokes.size() > 0:
        _strokes.pop_back()
    queue_redraw()
```

The do-method appends to `_strokes`. The undo-method pops the last entry. `queue_redraw()` in both ensures the canvas repaints immediately.

### Ctrl+Z / Ctrl+Y Input Handling

```gdscript
func _process(_delta: float) -> void:
    if Input.is_key_pressed(KEY_CTRL):
        if Input.is_key_just_pressed(KEY_Z):
            _undo_redo.undo()
            queue_redraw()
            _update_history()
        elif Input.is_key_just_pressed(KEY_Y):
            _undo_redo.redo()
            queue_redraw()
            _update_history()
```

`is_key_just_pressed` fires only on the first frame of a keydown, preventing repeated undo/redo while the key is held. `_update_history()` refreshes the HUD label showing current stroke count.

### Drawing

```gdscript
func _draw() -> void:
    draw_rect(Rect2(0, 0, 640, 480), Color(0.95, 0.95, 0.95))  # canvas

    for stroke in _strokes:
        for i in range(stroke.size() - 1):
            draw_line(stroke[i], stroke[i + 1], Color(0.1, 0.1, 0.8), 3.0, true)

    # In-progress stroke shown in lighter color
    for i in range(_current_stroke.size() - 1):
        draw_line(_current_stroke[i], _current_stroke[i + 1], Color(0.5, 0.5, 0.9), 3.0, true)
```

Committed strokes render in dark blue. The in-progress stroke renders in light blue — a helpful convention that shows the player what will become a committed action when they release the mouse.

## The Undo/Redo Stack Pattern

### Why Methods, Not Closures

`UndoRedo` stores method names as `StringName` values rather than `Callable` closures. This is intentional:

- **Serialisability**: method references survive hot-reload in the Godot editor. Closures that capture local variables do not.
- **Memory safety**: a closure can capture a reference to a freed object. Named methods are looked up on the target object at call time — if the object is freed, the call fails cleanly rather than accessing garbage memory.

The trade-off is that undo/redo logic must live in named functions, not inline lambdas.

### Property-Based Actions

For simple state changes, `add_do_property` / `add_undo_property` are cleaner than methods:

```gdscript
_undo_redo.create_action("Change Color")
_undo_redo.add_do_property(node, "modulate", new_color)
_undo_redo.add_undo_property(node, "modulate", old_color)
_undo_redo.commit_action()
```

Use property-based actions for single-value changes; use method-based actions for structural changes (adding/removing array entries, creating/deleting nodes).

### Redo Invalidation

Calling `commit_action()` after an undo clears the redo stack. This is correct behavior: if you undo 3 strokes and then draw a new stroke, the 3 undone strokes are discarded because the history has diverged. `UndoRedo` handles this automatically.

## How to Adapt This in Your Project

1. For a tile editor: `add_do_method(tilemap, "set_cell", ...)` / `add_undo_method(tilemap, "set_cell", ...)` with old and new tile indices.
2. For node creation/deletion: record the node's data in the undo method, then recreate it in the do method. Alternatively use `add_do_method` / `add_undo_method` with `queue_free()` and `add_child()`.
3. Expose `_undo_redo.get_history_count()` and `_undo_redo.get_action_name(idx)` in a history panel to show the player what they can undo.
4. Call `_undo_redo.clear_history()` on "New File" to prevent stale history after a reset.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `UndoRedo.new()` | Create a standalone undo/redo stack |
| `create_action(name)` | Open a new action record |
| `add_do_method(obj, method, args...)` | What to call on do/redo |
| `add_undo_method(obj, method, args...)` | What to call on undo |
| `add_do_property(obj, prop, value)` | Property change for do/redo |
| `add_undo_property(obj, prop, value)` | Property change for undo |
| `commit_action()` | Push action and immediately execute do-step |
| `undo()` / `redo()` | Step backward / forward through history |
| `clear_history()` | Discard all history |
| `get_history_count()` | Number of recorded actions |

## Controls

| Input | Action |
|-------|--------|
| Left mouse drag | Draw a stroke |
| Ctrl+Z | Undo last stroke |
| Ctrl+Y | Redo last undone stroke |
| Clear button | Wipe canvas and discard all history |

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Drawing input, stroke storage, `UndoRedo` wiring, canvas rendering |
| `scenes/main.tscn` | Node2D canvas with HUD label and Clear button |
| `tests/test_logic.gd` | Unit tests for undo stack behavior |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [entity-component-system](../entity-component-system) — A pure-GDScript ECS: entity IDs, component dicts, system functions.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

