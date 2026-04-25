# Animated Sprite

Builds `SpriteFrames` entirely in code — generating pixel-art animation frames as `Image` objects, converting them to textures, and driving a platformer character through idle/walk/jump/fall states with `AnimatedSprite2D`.

## Purpose

Most `AnimatedSprite2D` tutorials import PNG sprite sheets. This demo shows the programmatic equivalent: creating frames from scratch at runtime. This unlocks procedurally generated animations, runtime palette swaps, and a deep understanding of what sprite sheets do under the hood.

## Controls

- **Arrow keys / WASD**: Move left and right
- **Space / Up**: Jump

## How It Works

### Node Tree

```
Main (Node2D)                ← main.gd
├── Player (Node2D)
│   └── AnimatedSprite2D (scale=4,4)
└── Ground (visual only)
```

### `scripts/main.gd`

- **`_build_sprite_frames()`** — Creates a `SpriteFrames` resource, adds four animations (idle, walk, jump, fall), and populates each with textures returned by `_make_frame()`. Sets loop mode and FPS per animation.
- **`_make_frame(idx, anim_name)`** — Creates a 16×20 `Image` (pixel art at 1× before the 4× scale), draws a character using `Image.set_pixel()` for each body part. Different `anim_name` and `idx` values produce different poses (walk leg offsets, jump arms, blink).
- **Physics** — Implemented manually in `_physics_process()` using a `_vel` Vector2 and floor clamping, without `CharacterBody2D`. This keeps the script self-contained.
- **State switching** — Checks velocity and floor state each frame; sets `animated_sprite.animation` only when it changes to avoid restart interruption.

### SpriteFrames in Code

```gdscript
var frames := SpriteFrames.new()
frames.add_animation("walk")
frames.set_animation_loop("walk", true)
frames.set_animation_speed("walk", 8.0)   # FPS
for i in 4:
    var tex := _make_frame(i, "walk")
    frames.add_frame("walk", tex)
animated_sprite.sprite_frames = frames
```

### Image → Texture Pipeline

```gdscript
var img := Image.create(16, 20, false, Image.FORMAT_RGBA8)
img.set_pixel(x, y, color)
return ImageTexture.create_from_image(img)
```

`Image` is CPU-side pixel data. `ImageTexture.create_from_image()` uploads it to the GPU as a texture, making it usable as a sprite frame. The 4× scale on `AnimatedSprite2D` magnifies the 16×20 image to 64×80 pixels on screen with crispy pixel edges (no anti-aliasing).

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SpriteFrames.new()` | Container for named animation frame lists |
| `SpriteFrames.add_animation(name)` | Create a named animation |
| `SpriteFrames.add_frame(anim, texture)` | Append a frame texture |
| `SpriteFrames.set_animation_speed(anim, fps)` | Playback rate in frames/sec |
| `Image.create(w, h, mipmaps, format)` | Create a blank CPU image |
| `Image.set_pixel(x, y, color)` | Set a single pixel |
| `ImageTexture.create_from_image(img)` | Upload Image to GPU as texture |
| `AnimatedSprite2D.animation` | Name of the currently playing animation |
| `AnimatedSprite2D.play()` / `.stop()` | Start / stop playback |
