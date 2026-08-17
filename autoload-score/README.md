# Autoload Score

Demonstrates the Autoload (Singleton) pattern: a single globally-accessible node that holds game state and emits signals when that state changes.

## Purpose

Game state like score, player health, or inventory often needs to be read or modified by many different scenes — the HUD, the game world, the pause menu, the save system. Passing this data through parent nodes or signals across deep scene hierarchies becomes unwieldy. The Autoload pattern solves this by creating a single, scene-independent node that any script can reference by name.

## Controls

- **Add Points button**: Adds 10 to the score via `ScoreManager.add(10)`
- **Reset button**: Resets score to 0 via `ScoreManager.reset()`
- The label updates automatically via a signal connection

## How It Works

### Project Configuration

```
[autoload]
ScoreManager="*res://scripts/score_manager.gd"
```

The `*` prefix tells Godot to instantiate the script as a Node (not load it as a resource). Godot creates this node at startup and makes it available globally under the name `ScoreManager`. Any script in any scene can write `ScoreManager.add(10)` without any imports or `get_node()` calls.

### Node Tree

```
Main (Control)      ← main.gd
├── AddButton
├── ResetButton
└── ScoreLabel
```

`ScoreManager` does not appear in the scene tree — it lives at the root of the tree automatically.

### `scripts/score_manager.gd`

```gdscript
extends Node
signal score_changed(new_score: int)

var score: int = 0:
    set(value):
        score = value
        score_changed.emit(score)
```

The `score` variable uses a **property setter**: any assignment to `score` (even from other scripts writing `ScoreManager.score = 5`) automatically calls the setter, which emits `score_changed`. This means all consumers stay in sync without remembering to emit the signal manually.

- `add(amount)` — Increments `score` via the setter.
- `reset()` — Sets `score = 0` via the setter.

### `scripts/main.gd`

```gdscript
ScoreManager.score_changed.connect(_on_score_changed)
```

The UI connects to `ScoreManager.score_changed` and updates the label when the signal fires. Crucially, `main.gd` does not store score locally — it only reads the authoritative value from `ScoreManager`. This ensures one source of truth.

## Autoload Theory

### Why Not Use a Global Variable?

GDScript does not have true module-level globals. Even `static var` on a class only persists within that class. The Autoload pattern gives you a globally-accessible node instance that can hold state, run `_process()`, save to disk, and emit signals — things a plain dictionary or static variable cannot do.

### Singleton vs Autoload

Godot calls this feature "Autoload" rather than "Singleton" because the node is not strictly a singleton (you could instantiate `ScoreManager` again as a regular node). The guarantee is simply that Godot creates and registers one instance automatically at startup, accessible by name.

### Property Setters

```gdscript
var score: int = 0:
    set(value):
        score = value
        score_changed.emit(score)
```

GDScript property setters (`:set(value)`) intercept all assignments to the variable. This is preferable to calling `emit()` manually in `add()` and `reset()` because it catches all code paths — including future ones.

### Signal-Driven UI

The main scene does not poll `ScoreManager.score` in `_process()`. Instead it connects once and reacts to the signal. This is more efficient (no per-frame check) and architecturally cleaner (the UI is a consumer, not a poller).

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `[autoload]` in `project.godot` | Register a globally-accessible node |
| `var x: T = v: set(val): ...` | Property setter — intercepts all assignments |
| `signal score_changed(new_score: int)` | Typed signal declaration |
| `score_changed.emit(value)` | Emit signal with argument |
| `signal.connect(callable)` | Register a handler on the signal |

## Files

| File | What it holds |
|------|---------------|
| `scripts/main.gd` | Demo driver: builds the scene, wires the UI, draws the visualisation |
| `scripts/score_manager.gd` | `score manager` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/score_manager.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/score_manager.gd`**
- `add(amount: int = 10) -> void`
- `reset() -> void`
- signal `score_changed(new_score: int)`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- `ScoreManager` is registered as an autoload (Project Settings → Globals). Copy the autoload script and register it there under a name that does not collide with anything in your project.

## Related demos

- [event-bus](../event-bus) — An Autoload event bus so nodes broadcast/listen without direct references.
- [state-machine-hfsm](../state-machine-hfsm) — A hierarchical FSM tree with enter/exit callbacks and cascading transitions.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

