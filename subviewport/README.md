# SubViewport

Demonstrates how a `SubViewport` renders the same `World2D` as the main scene through a separate camera — the standard pattern for minimaps, picture-in-picture, and render-to-texture effects.

## Purpose

A minimap requires two simultaneous views of the same world: one close-up (the main camera following the player) and one zoomed out (the overview). `SubViewport` provides an offscreen render target with its own `Camera2D`. By sharing the parent viewport's `World2D`, both cameras see the same scene content with no duplication.

## Controls

- **Arrow keys / WASD**: Move the player through the world
- Watch the minimap (top-right) update in real-time

## How It Works

### Node Tree

```
Main (Node2D)                    ← main.gd
├── MainCamera (Camera2D)        ← follows player, zoomed in
├── MinimapViewport (SubViewport)
│   └── MinimapCamera (Camera2D) ← fixed, zoomed out to see whole world
└── HUD (CanvasLayer)
    ├── MinimapBorder (ColorRect)
    └── MinimapDisplay (TextureRect)
```

### `scripts/main.gd`

- **`_ready()`** — Shares the main viewport's World2D with the SubViewport: `$MinimapViewport.world_2d = get_viewport().world_2d`. Computes the zoom factor needed to see the entire 1200×900 world in the 160×120 SubViewport. Assigns the SubViewport's texture to the display: `$HUD/MinimapDisplay.texture = $MinimapViewport.get_texture()`.
- **`_process(delta)`** — Moves `_player_pos` with WASD, clamps to world bounds, sets `MainCamera.position = _player_pos`. Updates a small yellow overlay dot in the HUD to mark the player's position in the minimap frame.
- **`_draw()`** — Draws the world background, grid, 35 random colored shapes (generated from a fixed seed), and the player circle. Also draws a translucent rectangle showing the main camera's current viewport frame.

### World2D Sharing

```gdscript
$MinimapViewport.world_2d = get_viewport().world_2d
```

This is the key line. Without it, the SubViewport renders its own empty World2D (nothing visible). With it, both cameras share the same canvas draw calls — `_draw()` content is rendered by both the main camera and the minimap camera simultaneously.

### SubViewport as Texture

`SubViewport.get_texture()` returns a `ViewportTexture` — a live texture that updates every frame. Assigning it to a `TextureRect` displays the SubViewport's output anywhere in the UI tree.

### Camera Zoom for Overview

```gdscript
var zoom := float(MINIMAP_W) / float(WORLD_W)  # 160 / 1200 ≈ 0.133
minimap_cam.zoom = Vector2(zoom, zoom)
minimap_cam.position = Vector2(WORLD_W / 2, WORLD_H / 2)
```

At `zoom = 0.133`, the 160-pixel SubViewport shows `160 / 0.133 ≈ 1200` world units horizontally — exactly the world width. The camera at the world center sees everything.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SubViewport` | Offscreen render target with its own camera |
| `SubViewport.world_2d` | Set to parent's World2D to share the scene |
| `SubViewport.get_texture()` | Returns a live ViewportTexture |
| `SubViewport.size` | Resolution of the offscreen render |
| `TextureRect.texture` | Display a ViewportTexture in the UI |
| `Camera2D.zoom` | Scale factor for world-to-viewport mapping |
