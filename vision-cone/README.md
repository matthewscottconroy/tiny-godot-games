# Vision Cone

<!-- tags: component, shows-its-working -->

A patrolling enemy detects the player using a 120-degree field-of-view cone combined with a Liang-Barsky line-of-sight test against axis-aligned wall obstacles — no physics engine involved.

## Purpose

Vision cones are the core mechanic of stealth games from Metal Gear Solid to Alien: Isolation. A simple distance check is not enough: an enemy should not see through walls, and peripheral awareness should differ from direct gaze. This demo implements the full three-gate detection pipeline — range, angle, and occlusion — entirely in GDScript math, making the logic transparent and easily portable to any 2D project.

Physics-based raycasting (Godot's `intersect_ray`) is powerful but couples detection to the physics simulation layer. The manual segment-rectangle intersection used here runs purely in `_process`, works in headless/test environments, and requires no collision layers or physics bodies for walls. It is the right choice when your walls are static and axis-aligned.

For dynamic or rotated obstacles, prefer the physics raycast approach demonstrated in the line-of-sight demo. For 3D, a dot-product angle check plus a Raycast3D node gives the same three-gate structure.

## How It Works

The detection math lives in a reusable class, `VisionCone`
(`scripts/vision_cone.gd`), a plain `RefCounted`. `main.gd` moves the player and
enemy and draws everything, then asks the cone one question per frame:
`_vision.can_see(enemy_pos, enemy_dir, player_pos, walls)`.

### Detection Pipeline (`VisionCone.can_see`)

Detection uses three ordered gates, cheapest first:

```gdscript
func can_see(origin, facing, target, walls := []) -> bool:
    # Gate 1: distance
    if origin.distance_to(target) > max_range:
        return false
    # Gate 2: angle — is the target within the cone half-angle?
    var angle_diff := angle_difference((target - origin).angle(), facing)
    if absf(angle_diff) > half_angle:
        return false
    # Gate 3: occlusion — does any wall block the line?
    for w in walls:
        if _segment_intersects_rect(origin, target, w):
            return false
    return true
```

`angle_difference` is a Godot built-in that correctly handles the ±π wrap-around (e.g., comparing 170° to −170° gives 20°, not 340°).

### Liang-Barsky Slab Test

The occlusion check uses the slab method to test whether a segment intersects a `Rect2`:

```gdscript
func _segment_intersects_rect(p1: Vector2, p2: Vector2, r: Rect2) -> bool:
    var d := p2 - p1
    var t_min := 0.0
    var t_max := 1.0
    var tests := [
        [d.x, r.position.x - p1.x, r.position.x + r.size.x - p1.x],
        [d.y, r.position.y - p1.y, r.position.y + r.size.y - p1.y],
    ]
    for t in tests:
        var dv: float = t[0]; var lo: float = t[1]; var hi: float = t[2]
        if absf(dv) < 1e-6:
            if lo > 0.0 or hi < 0.0: return false
        else:
            var t1 := lo / dv; var t2 := hi / dv
            if t1 > t2: var tmp := t1; t1 = t2; t2 = tmp
            t_min = maxf(t_min, t1)
            t_max = minf(t_max, t2)
            if t_min > t_max: return false
    return true
```

The segment is parameterized as `P(t) = p1 + t*(p2-p1)` for `t ∈ [0, 1]`. For each axis-aligned slab the parameter range `[t_enter, t_exit]` at which the segment is inside that slab is computed and intersected. A non-empty intersection (`t_min ≤ t_max`) means the segment crosses the rectangle.

### Cone Rendering

The cone is drawn as a polygon fan, not a texture, giving a crisp visual at any scale:

```gdscript
var cone_pts := PackedVector2Array()
cone_pts.append(_enemy_pos)
var arc_steps := 16
for i in range(arc_steps + 1):
    var t := float(i) / float(arc_steps)
    var a := (_enemy_dir - CONE_ANGLE) + t * (CONE_ANGLE * 2.0)
    cone_pts.append(_enemy_pos + Vector2(cos(a), sin(a)) * CONE_RANGE)
draw_polygon(cone_pts, PackedColorArray([cone_color]))
```

The color flips from yellow-tinted to red-tinted when detection fires.

### Enemy Patrol

The enemy oscillates between `_PATROL_LEFT` (x = 80) and `_PATROL_RIGHT` (x = 260). Facing direction is updated from movement direction each frame using `atan2(0, sign(dx))` — which returns 0 when facing right and π when facing left.

## Vision Cone Theory

The three gates form a funnel:

| Gate | Test | Cost |
|------|------|------|
| Range | `distance ≤ CONE_RANGE` | O(1) — one float comparison |
| Angle | `abs(angle_diff) ≤ CONE_ANGLE` | O(1) — `angle()` + `angle_difference()` |
| Occlusion | segment vs each wall rect | O(w) — one Liang-Barsky per wall |

With five walls and typical rejection at gate 1, the occlusion test almost never runs. When it does run, `_wall_blocks_segment` returns on the first intersecting wall, so average cost is far below O(w).

For large numbers of walls (> ~50), replace the linear wall scan with a spatial structure (quadtree or grid) keyed on wall AABBs to reduce occlusion cost to O(log w).

## How to Adapt This in Your Project

- To support rotating walls, replace the Liang-Barsky test with a separating-axis (SAT) test against an OBB, or use Godot's `intersect_ray` with collision layers.
- For a wider FOV (e.g., a 180° floodlight), increase `half_angle` toward `PI / 2`. For a narrow sniper scope, decrease it toward 0.1 radians.
- Add a `memory_timer` to the enemy: after losing sight of the player, keep `_detected = true` for 1–2 seconds before returning to patrol. This prevents the jittery "blink" effect at detection boundaries.
- The same three-gate structure works in 3D: replace the 2D angle test with a `dot(forward, to_player.normalized()) > cos(half_angle)` check, then fire a `Raycast3D`.

## Use as a building block

**Copy:** `scripts/vision_cone.gd` (the `VisionCone` class). It's a `RefCounted` with no scene or physics dependency — pure geometry over positions and `Rect2` walls.

**Public API**
- `_init(half_angle := PI/3, range := 180)` — construct with FOV and range.
- `half_angle`, `max_range` — tunable fields.
- `can_see(origin, facing, target, walls := []) -> bool` — the three-gate test.

**Integrate**
1. `var _vision := VisionCone.new(deg_to_rad(60), 300)`.
2. Each frame: `if _vision.can_see(guard.position, guard.facing_angle, player.position, wall_rects): alert()`.
3. Supply obstacles as `Array[Rect2]` (or `[]` for open sight).

**Notes**
- `class_name VisionCone` is global — rename if it collides.
- For physics-body walls instead of `Rect2`s, swap the occlusion gate for a raycast — see the [line-of-sight](../line-of-sight) demo's `LineOfSight` helper.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `angle_difference(a, b)` | Signed angular difference that handles ±π wrap |
| `Vector2.angle()` | Angle of a vector from the positive X axis |
| `draw_polygon(pts, colors)` | Filled polygon for the cone wedge |
| `draw_line(a, b, color, width)` | Cone edge lines and direction indicator |
| `absf`, `clampf`, `signf` | Float math builtins (no cast needed in GDScript 2) |

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrow Keys | Move the player (blue circle) |

Step behind a wall to break line of sight. When detected the enemy turns red and "DETECTED!" appears on screen.

## Key Constants

```gdscript
# main.gd — demo tuning (also passed into the VisionCone)
const CONE_ANGLE  := PI / 3.0  # 60° half-angle → 120° total FOV
const CONE_RANGE  := 180.0     # detection radius in pixels
const ENEMY_SPEED := 80.0      # patrol speed px/s
const PLAYER_SPEED := 150.0

# vision_cone.gd — fields (defaults match the demo)
var half_angle := PI / 3.0
var max_range  := 180.0
```

## Files

| File | Purpose |
|------|---------|
| `scripts/vision_cone.gd` | **`VisionCone`** — reusable FOV + occlusion test (`can_see`) |
| `scripts/main.gd` | Player/enemy movement and `_draw()`; owns a `VisionCone` |
| `scenes/main.tscn` | `Node2D` root with `main.gd` attached |
| `tests/test_logic.gd` | Headless unit tests for detection and wall intersection |
| `tests/test.tscn` | Test runner scene |

## Related demos

- [patrol-ai](../patrol-ai) — A three-state FSM: patrol waypoints, chase on detection, return when escaped.
- [wave-spawner](../wave-spawner) — Phase-based waves with intermission countdowns and difficulty scaling.
- [noise-terrain](../noise-terrain) — 1D terrain from `get_noise_1d()`, redrawing live as you tune parameters.
- [radial-menu](../radial-menu) — Hold Tab to open a six-item radial action menu.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

