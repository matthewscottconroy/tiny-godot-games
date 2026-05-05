# Screen Flash

Demonstrates full-screen color flash effects using a ColorRect on a CanvasLayer and Tween.

## How it works

- A `ColorRect` sized to the full viewport sits on a `CanvasLayer` above the world.
- `flash(color, duration)` instantly sets the rect's color (with alpha), then tweens `color:a` to `0.0` over `duration` seconds using an ease-out curve.
- A hazard zone (red box) in the scene automatically triggers a damage flash when the player walks through it.
- Four flash presets can be triggered manually with number keys.

## Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move |
| Space / Up | Jump |
| 1 | Damage flash (red) |
| 2 | Pickup flash (yellow) |
| 3 | Transition flash (blue) |
| 4 | Respawn flash (white) |
| Walk into red zone | Auto damage flash |

## Key concepts

- `ColorRect` with `mouse_filter = MOUSE_FILTER_IGNORE` lets input pass through to the game.
- `tween_property(rect, "color:a", 0.0, duration)` animates only the alpha channel, leaving RGB intact.
- `Tween.EASE_OUT` makes the flash bright initially then fade quickly — more natural than linear.
- Starting a new flash while one is running immediately overrides it (new tween replaces old).
- `CanvasLayer` keeps the flash rect in screen space and unaffected by world shaders.

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | `flash()` implementation, hazard zone connection, key triggers, terrain drawing |
| `scripts/player.gd` | Platformer movement and jump |
| `scenes/main.tscn` | Scene: player, platforms, hazard Area2D, CanvasLayer with FlashRect |
| `tests/test_logic.gd` | Unit tests for flash color, alpha targeting, and preset values |
