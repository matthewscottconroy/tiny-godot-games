# Debug Overlay

Demonstrates a runtime debug information panel using CanvasLayer, updated every frame.

## How it works

- A `CanvasLayer` hosts a `PanelContainer` pinned to the top-left corner of the screen.
- Every frame, `main.gd` writes current engine stats into five labels: FPS, position, velocity, on-floor state, and movement state string.
- The panel is toggled on/off without affecting gameplay — `CanvasLayer` nodes sit above the world and are unaffected by camera movement or world shaders.
- The player tracks a `state` property (`"idle"`, `"run"`, `"air"`) derived from physics state each frame.

## Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move |
| Space / Up | Jump |
| F3 or `` ` `` | Toggle debug overlay |

## Key concepts

- `CanvasLayer` renders UI in screen space, always on top of and independent from the world.
- `Engine.get_frames_per_second()` returns the current FPS as an integer.
- `CharacterBody2D.is_on_floor()` and `.velocity` expose physics state for display.
- Overlay state is a simple boolean toggle; `panel.visible = _overlay_visible` shows/hides the whole panel.

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Updates debug labels, handles toggle key, draws terrain |
| `scripts/player.gd` | Movement, jump, state string tracking |
| `scenes/main.tscn` | Scene: player, platforms, CanvasLayer with panel and labels |
| `tests/test_logic.gd` | Unit tests for formatting, state transitions, toggle logic |
