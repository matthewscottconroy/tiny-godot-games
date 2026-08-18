# Procedural Animation

<!-- tags: shows-its-working -->

Implements FABRIK (Forward And Backward Reaching Inverse Kinematics) on an 8-joint chain that follows the mouse cursor in real time, drawn as a tapered, color-graded snake/tentacle using procedural polygon rendering.

## Purpose

Inverse Kinematics is the backbone of procedural character animation — the technique that makes arms reach for ledges in climbing games, tentacles wrap around objects in horror games, and spider legs plant on uneven terrain in creature AI. IK computes joint angles from a target position, rather than requiring the animator to keyframe every joint explicitly.

FABRIK in particular is favored for game use because it converges quickly (8 iterations is usually enough for any chain length), handles both reachable and unreachable targets gracefully, and has no trigonometry — only normalized direction vectors and distance constraints. Limb IK in procedural character rigs, rope physics, hair/cloth chains, and mechanical arm simulations all use variations of this algorithm.

## How It Works

### Chain Data (`scripts/main.gd`)

```gdscript
const N       := 8      # number of segments
const SEG_LEN := 28.0   # pixels per segment (total reach = 224px)
const ITERS   := 8      # solver iterations per frame

var _joints: PackedVector2Array   # N+1 joint positions
var _base: Vector2 = Vector2(320, 400)   # fixed anchor (tail)
var _target: Vector2                     # mouse cursor (head target)
```

The chain has `N+1 = 9` joints defining `N = 8` segments. `_joints[0]` is the head (reaches toward target), `_joints[N]` is the tail (fixed to `_base`).

### FABRIK Solver

```gdscript
func _fabrik_solve() -> void:
    for _iter in range(ITERS):
        # Forward pass: drag head to target, propagate to tail
        _joints[0] = _target
        for i in range(1, N + 1):
            var dir := (_joints[i] - _joints[i - 1]).normalized()
            _joints[i] = _joints[i - 1] + dir * SEG_LEN

        # Backward pass: anchor tail to base, propagate to head
        _joints[N] = _base
        for i in range(N - 1, -1, -1):
            var dir := (_joints[i] - _joints[i + 1]).normalized()
            _joints[i] = _joints[i + 1] + dir * SEG_LEN
```

**Forward pass**: Place joint 0 at the target. For each subsequent joint, compute the direction from the previous joint to itself, then place it exactly `SEG_LEN` away from the previous joint in that direction. This stretches the chain toward the target but breaks the base constraint.

**Backward pass**: Restore joint N to the fixed base position. Work backward from tail to head, applying the same distance constraint. This restores the base anchor but may move the head slightly away from the target.

Alternating these two passes iteratively pulls the chain into a valid configuration. For a reachable target (distance < total chain length), it converges to the exact target position. For unreachable targets (distance ≥ N × SEG_LEN = 224px), the chain extends straight toward the target.

## FABRIK Algorithm in Depth

### Convergence

A single iteration of FABRIK satisfies only one end constraint. Each additional iteration reduces residual error at both ends. For an 8-segment chain, 8 iterations drives head error to sub-pixel values in virtually all reachable configurations. The cost is linear: O(ITERS × N) per frame — for this demo that is 8 × 8 = 64 vector normalizations.

### Reachability Test

```
if target.distance_to(_base) >= N * SEG_LEN:
    # chain fully extended — cannot reach
```

The chain fully extends in a straight line toward the target. FABRIK handles this naturally without a special case — the backward pass places all joints along the target direction.

### No Angle Constraints

FABRIK as implemented here has no joint angle limits — each joint can rotate freely 360°. Real character IK (elbow bends one way, knee bends forward) requires angle constraints applied after each FABRIK pass. The pattern is: apply FABRIK normally, then clamp each joint's angle relative to its parent to the allowed range.

### Tapered Polygon Drawing

Each segment is drawn as a quadrilateral (trapezoid) rather than a line:

```gdscript
var w0 := lerp(18.0, 4.0, float(i) / float(N)) * 0.5
var w1 := lerp(18.0, 4.0, float(i + 1) / float(N)) * 0.5
var perp := seg_dir.normalized().rotated(PI * 0.5)

var poly := PackedVector2Array([
    p0 + perp * w0,
    p0 - perp * w0,
    p1 - perp * w1,
    p1 + perp * w1
])
draw_colored_polygon(poly, seg_color)
```

Width tapers from 18 pixels at the head (i=0) to 4 pixels at the tail (i=N) using `lerp`. The perpendicular direction is the segment direction rotated 90°. Each segment forms a quadrilateral with its wide end at the head side and narrow end at the tail side, producing an organic tapered silhouette.

The color gradient runs from cyan-green at the head to dark teal at the tail using per-component `lerp`. Segments are drawn tail-to-head so the head (drawn last) overlaps the neck.

## How to Adapt This in Your Project

- **Arm IK for a character**: Constrain `_base` to the shoulder socket position (updated each frame). Set `_target` to a held object's position. Lock `N = 2` segments for a two-bone arm (upper arm + forearm).
- **Leg IK on uneven terrain**: Raycast downward from each foot's neutral position. Set `_target` to the raycast hit point. Update only when the foot is in a "step" state.
- **Rope/chain between two points**: Run FABRIK from both ends simultaneously (two anchors, no free target). This is called "double-anchored FABRIK" or "CCD with two endpoints."
- **Angle constraints**: After the backward pass, for each joint compute the angle from its parent-to-self direction and clamp it to an allowed cone using `Vector2.rotated()` and `clampf`.
- **Pitfall**: FABRIK needs normalized direction vectors. If two joints land on the same position (zero-length segment), `normalized()` returns `Vector2.ZERO` and the chain breaks. Guard with `if diff.length_squared() > 0.001`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `PackedVector2Array` | Efficient array of Vector2 for joint positions |
| `Vector2.normalized()` | Unit direction vector |
| `Vector2.rotated(PI * 0.5)` | 90° rotation for perpendicular |
| `draw_colored_polygon(PackedVector2Array, Color)` | Filled quad per segment |
| `draw_polyline(PackedVector2Array, Color, width)` | Outline edges per segment |
| `lerp(a, b, t)` | Width and color gradient along the chain |
| `get_global_mouse_position()` | Mouse cursor in world coordinates |

## Controls

| Input | Action |
|-------|--------|
| Mouse move | Moves the FABRIK target (head of the chain) |

## Key Constants

```gdscript
const N       := 8      # chain segment count (joints = N+1 = 9)
const SEG_LEN := 28.0   # pixels per segment; total reach = N * SEG_LEN = 224px
const ITERS   := 8      # FABRIK iterations per frame

# Drawing:
head_width := 18.0      # pixels wide at joint 0
tail_width := 4.0       # pixels wide at joint N
# Interpolated: lerp(18.0, 4.0, float(i) / float(N))
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | FABRIK solver, tapered polygon drawing, head/eye rendering |
| `scenes/main.tscn` | Single Node2D scene |
| `tests/test.tscn` | FABRIK correctness tests (segment length preservation, base anchoring) |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

## Related demos

- [tool-script](../tool-script) — `@tool`: a layout helper that arranges its children in the editor, before the game runs.
- [input-recording](../input-recording) — Capturing input per frame and replaying it deterministically.
- [pathfinding-astar](../pathfinding-astar) — Interactive A* on a grid, visualizing open/closed sets and the optimal path.
- [radial-menu](../radial-menu) — Hold Tab to open a six-item radial action menu.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

