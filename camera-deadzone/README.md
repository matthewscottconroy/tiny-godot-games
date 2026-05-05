# Camera Deadzone

A side-scrolling camera that only follows when the player leaves a central dead zone rectangle. Inside the zone the camera is static; outside it, the camera lerps to re-center the player at the zone edge.

## Purpose

Simple camera lerp follows the player constantly, which can feel jittery and disorienting for small movements. A deadzone gives the player freedom to make minor movements without the camera moving — the camera only catches up when the player commits to moving significantly. This is the standard approach in most 2D platformers.

## Controls

- **Arrow keys / WASD**: Move
- **Up**: Jump
- Walk far right or left — the world extends 3000 px

## How It Works

### Dead zone tracking (`scripts/main.gd`)

```gdscript
const DEAD_W := 80.0
const DEAD_H := 40.0

func _process(delta: float) -> void:
    var offset := _player.global_position - _cam.global_position
    var target := _cam.global_position

    if offset.x > DEAD_W:    target.x = _player.global_position.x - DEAD_W
    elif offset.x < -DEAD_W: target.x = _player.global_position.x + DEAD_W
    if offset.y > DEAD_H:    target.y = _player.global_position.y - DEAD_H
    elif offset.y < -DEAD_H: target.y = _player.global_position.y + DEAD_H

    _cam.global_position = _cam.global_position.lerp(target, FOLLOW_SPEED * delta)
```

`offset` is the vector from camera to player. If the player is within the dead zone bounds, `target` equals the current camera position — no movement. Outside the bounds, `target` is set to position the camera so the player sits exactly at the zone edge.

The `lerp` gives a smooth catch-up instead of an instant snap.

### Visualization

The yellow rectangle drawn on screen shows the dead zone in viewport space. Because it's drawn in `_draw()` using viewport-space coordinates, it stays fixed on screen while the world scrolls.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Camera2D.global_position` | Move camera by setting its world-space position |
| `Camera2D.position_smoothing_enabled` | Disable built-in smoothing (we handle it manually) |
| `CanvasLayer` | HUD labels that stay fixed in screen space |
| `Vector2.lerp(target, weight)` | Exponential approach to target position |
