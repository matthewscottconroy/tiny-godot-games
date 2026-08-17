# Debug Overlay

A toggleable, always-on-top HUD panel that displays live runtime data — FPS, world position, velocity, floor contact, and movement state — while the game is running.

## Purpose

Every game needs a way to inspect internal state during development. Without a debug overlay you resort to `print()` statements that scroll off the console and disappear the moment you need them. A debug overlay surfaces the same information as persistent, readable on-screen text that updates every frame.

Real games use this heavily during development. *Celeste* ships with a dev console that exposes room names, velocity, and coyote-time flags. *Hollow Knight* has an F3 overlay for collision layers. The technique is identical: a `CanvasLayer` at a high layer index renders UI text in screen space, independent of the camera, and is toggled with a key that would never appear in a release build.

The overlay pattern is also the right scaffold for profiling custom systems. When you add a new mechanic, display its key variables here first — a one-frame snapshot is far more useful than a `print` that floods the console at 60 Hz.

## How It Works

### Node Tree

```
Main (Node2D)                  ← main.gd
├── Player (CharacterBody2D)   ← player.gd
└── CanvasLayer
    └── Panel (PanelContainer)
        └── VBox (VBoxContainer)
            ├── FPSLabel
            ├── PosLabel
            ├── VelLabel
            ├── FloorLabel
            └── StateLabel
```

### `scripts/main.gd` — The Overlay

The overlay reads from the player node every frame and formats five labels:

```gdscript
func _process(_delta: float) -> void:
    if Input.is_key_just_pressed(KEY_F3) or Input.is_key_just_pressed(KEY_QUOTELEFT):
        _overlay_visible = !_overlay_visible
        _panel.visible = _overlay_visible

    if _overlay_visible:
        _fps_label.text   = "FPS:     %d"           % Engine.get_frames_per_second()
        _pos_label.text   = "Pos:     (%.0f, %.0f)" % [_player.global_position.x, _player.global_position.y]
        _vel_label.text   = "Vel:     (%.0f, %.0f)" % [_player.velocity.x, _player.velocity.y]
        _floor_label.text = "OnFloor: %s"           % str(_player.is_on_floor())
        _state_label.text = "State:   %s"           % _player.state
```

Label updates are gated behind `_overlay_visible` — no string formatting happens when the panel is hidden. The toggle accepts both F3 (common in games like Minecraft and Terraria) and the backtick key (common in developer consoles).

### `scripts/player.gd` — Exposing State

The player derives a string state from physics each frame and stores it as a public variable so the overlay can read it:

```gdscript
var state: String = "idle"

# At the end of _physics_process:
if not is_on_floor():
    state = "air"
elif absf(velocity.x) > 1.0:
    state = "run"
else:
    state = "idle"
```

`main.gd` accesses `_player.state` directly. This is acceptable for a dev tool — the coupling is intentional and never ships.

## The Debug Overlay Pattern

The canonical overlay design has three properties: it sits above everything, it never affects gameplay, and it toggles without a scene reload.

`CanvasLayer` provides the first two: its children render in screen-space coordinates at a layer above the game world, unaffected by `Camera2D` transforms or world shaders. Setting `panel.visible` achieves the third — the node stays in the tree, retains its state, and gameplay continues uninterrupted.

An important subtlety: label updates only happen when `_overlay_visible` is true. At release you can set `_overlay_visible = false` by default (or strip the overlay entirely) with zero performance impact.

### Alternatives

- **Godot's built-in Performance monitor** (`Performance.get_monitor()`): exposes engine-level metrics but not game-specific state.
- **`print()` / `print_rich()`**: useful for one-shot events, not for continuous state.
- **EngineDebugger / remote debugging**: powerful but requires the editor. An in-game overlay works in exported builds and on devices.

## How to Adapt This in Your Project

1. Add a `CanvasLayer` autoload (or child node) with a `PanelContainer` docked to a corner.
2. Create one `Label` per variable you want to watch.
3. In your `_process`, write to those labels only when the overlay is visible.
4. Expose public variables on any node you want to inspect — avoid reaching into private state from the overlay.
5. Add your toggle key to the list of keys that are stripped or disabled in release builds.

A common extension is color-coding labels by severity — green for normal, yellow for warnings, red for error states. You can also add `ChartsRenderer` as a child and draw a rolling FPS graph with `draw_polyline()`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `CanvasLayer` | Renders children in screen space above the game world |
| `Engine.get_frames_per_second()` | Current FPS as an integer |
| `CharacterBody2D.velocity` | Current velocity vector (updated by `move_and_slide()`) |
| `CharacterBody2D.is_on_floor()` | True when resting on a floor surface |
| `Input.is_key_just_pressed(keycode)` | Edge-triggered key detection |
| `panel.visible` | Shows or hides a control without removing it from the tree |

## Controls

| Key | Action |
|-----|--------|
| Arrow keys | Move |
| Up | Jump |
| F3 or `` ` `` | Toggle debug overlay |

## Key Constants

```gdscript
# In main.gd — no tuneable constants; labels update every frame automatically.
# In player.gd:
const SPEED    := 200.0   # horizontal movement speed (px/s)
const JUMP_VEL := -400.0  # vertical velocity applied on jump
const GRAVITY  := 900.0   # downward acceleration (px/s²)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Updates debug labels each frame, handles toggle key, draws terrain |
| `scripts/player.gd` | Movement, jump, derives and exposes `state` string |
| `scenes/main.tscn` | Player, platforms, CanvasLayer with panel and five labels |
| `tests/test_logic.gd` | Unit tests for label formatting, state transitions, toggle logic |

## Use as a building block

**Copy:** `scripts/player.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [performance-profiling](../performance-profiling) — Measuring where a frame's time goes, against the budget the target rate gives you.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

