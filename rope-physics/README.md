# Rope Physics

A 24-node rope simulation using Verlet integration and iterative distance-constraint relaxation. The first node is pinned to a fixed anchor; all other nodes hang freely under gravity and can be grabbed and dragged with the mouse.

## Purpose

Rope simulation shows up in a surprising range of games: *Hollow Knight*'s hanging platforms, *Ori and the Will of the Wisps*' chain mechanics, *Terraria*'s grappling hooks and chains, and countless 2D games with swinging mechanics. The challenge is that ropes need to feel soft — they should sag, stretch slightly, and not oscillate wildly — while still respecting a maximum length constraint.

Verlet integration with constraint relaxation (the XPBD/Jakobsen approach) is the standard technique for this. It has several advantages over spring-mass systems: the constraint enforcement is decoupled from the integration timestep, there's no need to tune spring constants that fight against each other, and the algorithm is extremely simple to implement correctly. The same pattern is used in cloth simulation, ragdolls, and any soft-body effect.

Understanding this demo unlocks grapple hooks, chain bridges, swinging lanterns, and procedural cloth — all variations on the same two-step loop: integrate positions, then enforce constraints.

## How It Works

### Verlet Integration

Each node stores two positions: the current frame (`_pos[i]`) and the previous frame (`_prev[i]`). Velocity is implicit — it's reconstructed from the difference. Each frame, every free node is updated:

```gdscript
var vel := (_pos[i] - _prev[i]) * DAMPING
_prev[i] = _pos[i]
_pos[i]  = _pos[i] + vel + Vector2(0.0, GRAVITY) * delta * delta
```

The gravity term uses `delta * delta` because position-based integration requires the acceleration term to be scaled by time squared (it's `a * dt²` in the Verlet formula, not `a * dt`). `DAMPING` multiplies the implicit velocity before applying it, which bleeds energy out of the system and prevents infinite oscillation.

### Distance Constraint Relaxation

After integrating, the constraint pass enforces that adjacent nodes stay `SEG_LEN = 12px` apart:

```gdscript
for _iter in ITERS:
    _pos[_ANCHOR_IDX] = _ANCHOR_POS  # re-pin anchor each iteration
    for i in N - 1:
        var diff       := _pos[i + 1] - _pos[i]
        var dist       := diff.length()
        if dist < 0.001:
            continue
        var correction := diff * (1.0 - SEG_LEN / dist) * 0.5
        if i != _ANCHOR_IDX:
            _pos[i]     = _pos[i] + correction
        if (i + 1) != _drag:
            _pos[i + 1] = _pos[i + 1] - correction
```

`diff * (1 - SEG_LEN / dist)` is the total stretch vector. Multiplying by `0.5` splits it equally between both nodes, moving each halfway toward satisfying the constraint. The anchor is re-pinned at the top of each iteration so constraint errors don't propagate upward and lift the anchor point off its pin.

Running `ITERS = 10` iterations per frame makes the rope nearly inextensible. Fewer iterations produces a more elastic, stretchy feel; more iterations approaches a rigid constraint.

## Constraint Relaxation — Why It Works

A single pass of constraint resolution is approximate: fixing one segment may violate its neighbor's constraint. The key insight is that if you repeat the pass enough times, errors propagate back up the chain and cancel out. This is Jakobsen's Position Based Dynamics approach. For N = 24 nodes with ITERS = 10, the residual error is imperceptible — the rope looks rigid even though it's solved iteratively.

The anchor re-pin inside the loop is critical. Without it, the constraint solver would see the anchor as just another node and nudge it out of place over the iterations, causing the rope to slowly drift away from the ceiling.

## Dragging

Clicking near any non-anchor node sets `_drag` to that node's index:

```gdscript
if _pos[i].distance_to(event.position) < 20.0:
    _drag = i
```

While dragging, both `_pos[_drag]` and `_prev[_drag]` are set to the mouse position each frame. Updating `_prev` as well zeroes the implicit Verlet velocity — without this, the node would fly off in the direction it was previously moving the moment you release it.

## How to Adapt This in Your Project

Increase `N` and decrease `SEG_LEN` for a longer, finer rope. Add a bob weight (heavy node at the end) by scaling the gravity term for the last node. For a grapple hook, pin the far end instead of the near end and let the near end follow the player. For cloth, extend to a 2D grid of nodes with horizontal and diagonal constraints. Replace the line renderer in `_draw` with `Line2D` or a texture-based segment for visual polish. Use `ITERS = 4–6` for gameplay-affecting ropes and `ITERS = 10+` for decorative ropes that must look taut.

Pitfall: never normalize a near-zero vector. The `dist < 0.001` guard prevents the `diff / dist` division from exploding when two nodes overlap exactly.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `PackedVector2Array` | Memory-efficient array for the node positions and previous positions |
| `_physics_process(delta)` | Physics-rate update for stable Verlet integration |
| `draw_line(from, to, color, width)` | Draws each rope segment |
| `draw_circle(pos, radius, color)` | Draws each rope node |
| `queue_redraw()` | Schedules a `_draw()` call next frame |

## Controls

| Input | Action |
|-------|--------|
| Left Click + Drag | Grab and move any non-anchor rope node |
| R | Reset rope to horizontal starting position |

## Key Constants

```gdscript
const N       := 24     # Number of rope nodes
const SEG_LEN := 12.0   # Rest length of each segment (px)
const GRAVITY := 600.0  # Downward acceleration (px/s²)
const ITERS   := 10     # Constraint relaxation passes per frame (more = stiffer)
const DAMPING := 0.985  # Per-frame velocity multiplier (energy loss)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Verlet integration, constraint relaxation, mouse dragging, drawing |
| `scenes/main.tscn` | Root Node2D with main.gd attached |
| `tests/test_logic.gd` | Unit tests for constraint correction math |
| `tests/test.tscn` | Scene that runs the tests |
