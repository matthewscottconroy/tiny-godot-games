# Split Screen

Two-player simultaneous platformer using Godot 4's `SubViewport` and `SubViewportContainer`. Each player has their own independent world, physics simulation, and camera — displayed side by side in the same 640×480 window.

## Purpose

Local multiplayer split-screen is a classic feature in co-op and competitive games. The challenge is that two players in the same scene share the same world: the same physics space, the same collision layers, and the same camera. Split-screen requires isolating each player's view and simulation so they cannot interfere with each other.

Games like Mario Kart, Halo co-op, and Divinity: Original Sin all use some form of viewport splitting. The core technique — independent render targets with isolated physics worlds — is the same regardless of platform. Godot implements this with `SubViewport` (an offscreen render target) and `SubViewportContainer` (a Control node that displays a viewport's output as a texture in the UI).

This demo demonstrates both halves of the technique: visual isolation via `SubViewportContainer` layout and physics isolation via `own_world_2d`, using a single `player.gd` script for both players differentiated by an export variable.

## How It Works

### Node Tree

```
Main (Control 640×480)              <- main.gd (draws dividing line)
├── LeftContainer  (SubViewportContainer, 0–320 px wide)
│   └── LeftViewport  (SubViewport, size=320×480, own_world_2d=true)
│       └── World1 (Node2D)         <- world.gd (camera + player + platforms)
└── RightContainer (SubViewportContainer, 320–640 px wide)
    └── RightViewport (SubViewport, size=320×480, own_world_2d=true)
        └── World2 (Node2D)         <- world.gd (camera + player + platforms)
```

### SubViewport as Independent Render Target

`SubViewport` is a virtual screen — it renders its own scene graph independently of the main viewport. `SubViewportContainer` is a Control node that displays a SubViewport's output as a texture, positioned and sized like any other UI element. Setting `stretch = true` on the Container scales the viewport's output to fill the container's rect.

Two SubViewportContainers placed side by side (left 0–320 px, right 320–640 px) create the split-screen layout without any render pipeline customization.

### Physics Isolation via own_world_2d

```gdscript
# Each SubViewport has own_world_2d = true (set in the scene)
```

Without `own_world_2d = true`, both SubViewports share the same `World2D`. Physics bodies in World1 would collide with bodies in World2, and both players would occupy the same physics space. Setting `own_world_2d = true` gives each viewport its own isolated physics simulation — Player 1 cannot interact with Player 2's platforms.

### Camera Per Viewport

```gdscript
# scripts/world.gd
func _process(_delta: float) -> void:
    _cam.global_position = _player.global_position
```

Each world has its own `Camera2D`. Because each `SubViewport` is an independent render target, the active camera inside it automatically controls what that viewport shows. No special setup is needed — the camera follows its player by snapping `global_position` each frame.

### One Script, Two Players

```gdscript
# scripts/player.gd
@export var use_wasd: bool = true
@export var body_color: Color = Color.DODGER_BLUE

func _physics_process(delta: float) -> void:
    var h := 0.0
    if use_wasd:
        h = (1.0 if Input.is_key_pressed(KEY_D) else 0.0) \
          - (1.0 if Input.is_key_pressed(KEY_A) else 0.0)
    else:
        h = (1.0 if Input.is_key_pressed(KEY_RIGHT) else 0.0) \
          - (1.0 if Input.is_key_pressed(KEY_LEFT) else 0.0)
    var jump_key := KEY_W if use_wasd else KEY_UP
    if Input.is_key_just_pressed(jump_key) and is_on_floor():
        velocity.y = JUMP_VEL
```

Both players run the same script. The `use_wasd` export flag (set per instance in the scene) routes input to different physical keys. This avoids duplicating player logic while keeping bindings fully separate.

### The Dividing Line

```gdscript
# scripts/main.gd
func _draw() -> void:
    draw_rect(Rect2(319.0, 0.0, 2.0, 480.0), Color(0.9, 0.9, 0.9, 1.0))
```

`Main` is a `Control` node that fills the window, so its `_draw()` renders on top of both `SubViewportContainer` children. A 2-pixel rect provides a clean visual boundary.

## SubViewport vs Viewport

`SubViewport` is embedded inside the scene tree as a node. `Viewport` (the base class) is the root render target. The distinction matters because `SubViewport` participates in the normal parent-child hierarchy and can be placed anywhere a `Node` can go, while the main `Viewport` is managed by Godot's engine root. For split-screen, always use `SubViewport`.

## How to Adapt This in Your Project

- **4-player split**: Add two more `SubViewportContainer` / `SubViewport` pairs. Divide the window into quadrants (320×240 each). Assign arrow keys, WASD, and gamepad device IDs per player.
- **Asymmetric split**: Change the Container widths to 213/427 for 1/3 + 2/3 split (useful when one player has a map view and the other has a game view).
- **Gamepad per player**: In `player.gd`, add `@export var joy_device: int = 0` and use `Input.get_joy_axis(joy_device, ...)` instead of keyboard reads.
- **Shared world**: Remove `own_world_2d = true` to put both players in the same physics world — useful for co-op where players interact with shared objects.
- **Single shared scene**: Instead of two world scenes, use one world scene and place both cameras in it. Route each camera's output to a SubViewport using `SubViewport.world_2d` assignment.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `SubViewport` | Offscreen render target with its own scene graph |
| `SubViewport.own_world_2d` | Isolates physics simulation from other viewports |
| `SubViewportContainer` | Control node that displays a SubViewport as a texture |
| `SubViewportContainer.stretch` | Scale viewport output to fill the container |
| `Camera2D` | Controls what the SubViewport renders |
| `Input.is_key_pressed(key)` | Poll raw key state (not action-mapped) |
| `Input.is_key_just_pressed(key)` | One-frame key press detection |

## Controls

| Player | Move | Jump |
|--------|------|------|
| Player 1 | A / D | W |
| Player 2 | Left / Right | Up |

## Key Constants

```gdscript
# scripts/player.gd
const SPEED    := 160.0    # horizontal pixels per second
const JUMP_VEL := -360.0   # initial jump velocity (negative = upward)
const GRAVITY  :=  800.0   # pixels per second squared
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Draws the center dividing line |
| `scripts/world.gd` | Per-world camera follow logic and platform drawing |
| `scripts/player.gd` | Physics movement; use_wasd export selects key binding set |
| `scenes/main.tscn` | Root Control with two SubViewportContainers and their worlds |
| `tests/test.tscn` | Unit tests using local stub classes (no scene tree required) |

## Use as a building block

**Copy:** `scripts/player.gd`, `scripts/world.gd`. `scripts/main.gd` only drives the demo — it builds the scene and draws the visualisation — so you do not need it.

**`scripts/player.gd`**
- `@export use_wasd: bool`
- `@export body_color: Color`

**Notes**
- These scripts have no `class_name`, so reference them with `preload("res://…")` or give them one when you copy them in.

## Related demos

- [local-multiplayer](../local-multiplayer) — Two players on one keyboard via per-instance input schemes.
- [multiplayer-rpc](../multiplayer-rpc) — High-level multiplayer over ENet: host/join, a server-authoritative roster, and `@rpc`.
- [minimap](../minimap) — A real-time minimap drawn in code for a wide side-scrolling world.
- [camera-deadzone](../camera-deadzone) — Camera stays still until the player exits a rectangular dead zone, then catches up.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

