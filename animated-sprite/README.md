# Animated Sprite

A platformer character whose entire sprite sheet is generated at runtime in code — no image files, no imports. `SpriteFrames` is built programmatically from `Image` objects, demonstrating the complete pipeline from CPU pixel data to GPU texture to animated sprite.

## Purpose

Most `AnimatedSprite2D` tutorials start from imported PNG sprite sheets. This demo shows the opposite: generating frames entirely in GDScript using `Image.set_pixel()` and uploading them as textures at runtime. This technique is the foundation of procedurally generated characters (palette swaps, randomized equipment tinting), runtime UI icons, and dynamic map overlays.

Understanding this pipeline also demystifies what sprite sheets do under the hood. A sprite sheet is just multiple `ImageTexture` objects packed into named animation lists inside a `SpriteFrames` resource — which is exactly what this demo builds manually. Once you understand the structure, using `preload("res://sprites/hero.png")` sliced into frames is a mechanical shortcut, not magic.

This is also the correct approach when sprites must change during gameplay — swapping a character's armor color, applying a status-effect tint, or generating unique enemy markings — without switching to a shader.

## How It Works

### Node Tree

```
Main (Node2D)                   ← main.gd
├── Player (Node2D)
│   ├── AnimatedSprite2D        ← plays the generated frames
│   └── CollisionShape2D        ← capsule for floor detection
└── Ground (StaticBody2D)
    └── Collision
```

The `AnimatedSprite2D` has `scale = Vector2(4, 4)` set in the scene, magnifying the 16×20 pixel art frames to 64×80 pixels on screen with crisp pixel edges.

### Building SpriteFrames (`scripts/main.gd`)

```gdscript
func _build_sprite_frames() -> void:
    var frames := SpriteFrames.new()

    frames.add_animation("idle")
    frames.set_animation_loop("idle", true)
    frames.set_animation_speed("idle", 4.0)
    for i in 4:
        frames.add_frame("idle", _make_frame(i, "idle"), 0)

    frames.add_animation("walk")
    frames.set_animation_loop("walk", true)
    frames.set_animation_speed("walk", 8.0)
    for i in 6:
        frames.add_frame("walk", _make_frame(i, "walk"), 0)

    anim.sprite_frames = frames
```

Each animation is registered by name with its loop mode and speed before frames are added. The `0` argument to `add_frame` is the insertion index — appending to the end.

### Image to Texture Pipeline

```gdscript
func _make_frame(idx: int, anim_name: String) -> ImageTexture:
    var img := Image.create(16, 20, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))  # transparent background

    var body_col := Color(0.3, 0.5, 0.9)

    # Body (6×10 block, columns 5–10, rows 8–17)
    for y in range(8, 18):
        for x in range(5, 11):
            img.set_pixel(x, y, body_col)

    # Walk leg animation — offset legs by frame index
    match anim_name:
        "walk":
            var leg_offsets := [0, 1, 2, 1, 0, -1]
            var off: int = leg_offsets[idx % leg_offsets.size()]
            img.set_pixel(6, 18 + off, body_col.darkened(0.3))
            img.set_pixel(9, 18 - off, body_col.darkened(0.3))
        "idle":
            if idx == 3:  # blink on frame 3
                for x in range(6, 8): img.set_pixel(x, 4, body_col)

    return ImageTexture.create_from_image(img)
```

`Image` is CPU-side pixel data. `ImageTexture.create_from_image(img)` uploads it to the GPU as a `Texture2D`, making it usable as a sprite frame. The conversion is a one-time upload per frame.

### Animation State Machine

```gdscript
func _physics_process(delta: float) -> void:
    var dir_x := Input.get_axis("ui_left", "ui_right")
    velocity.x = dir_x * SPEED

    if not _on_floor: velocity.y += GRAVITY * delta
    if _on_floor and Input.is_action_just_pressed("ui_up"):
        velocity.y = JUMP_VEL; _on_floor = false

    player.position += velocity * delta
    if player.position.y >= 450:
        player.position.y = 450; velocity.y = 0; _on_floor = true

    if dir_x < -0.1:  anim.flip_h = true
    elif dir_x > 0.1: anim.flip_h = false

    var new_anim: String
    if not _on_floor:
        new_anim = "jump" if velocity.y < 0 else "fall"
    elif abs(velocity.x) > 10:
        new_anim = "walk"
    else:
        new_anim = "idle"

    if anim.animation != new_anim:
        anim.play(new_anim)   # only switch when changed, prevents restart
```

The `anim.animation != new_anim` guard prevents restarting the same animation from the beginning every frame. `flip_h` mirrors the sprite horizontally for left-facing movement without needing mirrored frames.

## SpriteFrames Theory

A `SpriteFrames` resource is a named dictionary of animation tracks. Each track is a list of `(Texture2D, duration)` pairs. `AnimatedSprite2D` advances through the list at the specified FPS, wrapping when `loop = true`.

| Animation | Frames | FPS | Notes |
|-----------|--------|-----|-------|
| idle | 4 | 4.0 | Frame 3 = blink |
| walk | 6 | 8.0 | Leg offset oscillates ±2 px |
| jump | 1 | 4.0 | Arms raised, `loop = false` |
| fall | 1 | 4.0 | Arms out, `loop = false` |

Non-looping one-frame animations (jump, fall) hold the last frame indefinitely, which is exactly the right behavior for airborne states.

## How to Adapt This in Your Project

- For palette swaps, pass a `color_map: Dictionary` to `_make_frame()` that remaps pixel colors at generation time.
- For runtime equipment, call `_make_frame()` again with updated parameters and replace individual frames using `sprite_frames.set_frame("walk", idx, new_texture)`.
- To import from a sprite sheet PNG, use `Image.get_region(Rect2(frame_x, frame_y, w, h))` to slice frames instead of drawing them manually.
- The manual floor-clamping physics works fine for simple platformers. Swap `player.position +=` for a `CharacterBody2D` with `move_and_slide()` for slope handling and one-way platforms.
- For pixel-perfect scaling, set `stretch_mode = "canvas_items"` in Project Settings and keep the `AnimatedSprite2D` scale at a whole-number multiple like 4.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SpriteFrames.new()` | Container for named animation frame lists |
| `SpriteFrames.add_animation(name)` | Register a named animation |
| `SpriteFrames.set_animation_loop(name, bool)` | Whether the animation loops |
| `SpriteFrames.set_animation_speed(name, fps)` | Playback rate |
| `SpriteFrames.add_frame(name, texture, index)` | Append a frame texture |
| `Image.create(w, h, mipmaps, format)` | Create a blank CPU-side image |
| `Image.set_pixel(x, y, color)` | Write a single pixel |
| `ImageTexture.create_from_image(img)` | Upload `Image` to GPU as a texture |
| `AnimatedSprite2D.play(name)` | Start playing a named animation |
| `AnimatedSprite2D.flip_h` | Mirror sprite for left-facing movement |
| `Input.get_axis("ui_left", "ui_right")` | Signed horizontal input |

## Controls

| Key | Action |
|-----|--------|
| Arrow Left / A | Move left |
| Arrow Right / D | Move right |
| Arrow Up / W / Space | Jump |

The label at the top shows the current animation name and frame index.

## Key Constants

```gdscript
const SPEED    := 180.0    # horizontal movement px/s
const JUMP_VEL := -420.0   # initial jump velocity (upward = negative)
const GRAVITY  := 900.0    # downward acceleration px/s²
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | `_build_sprite_frames()`, `_make_frame()`, manual physics, animation state machine |
| `scenes/main.tscn` | Scene tree: Player with AnimatedSprite2D, ground StaticBody2D, AnimLabel |
