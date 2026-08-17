# Patrol AI

Implements a three-state Finite State Machine for enemy AI: patrol along waypoints, chase the player when detected, and return to the patrol route when the player escapes.

## Purpose

Enemy AI in games requires more than "always move toward the player." A credible enemy patrols predictably when the player is absent, reacts when spotted, and gives up the chase after losing contact. These three behaviors correspond to three distinct states in a Finite State Machine (FSM). This demo shows how to implement a clean FSM with explicit transition logic and per-state behavior.

## Controls

- **Arrow keys**: Move the player
- Watch the enemy label change between PATROL, CHASE, and RETURN
- The enemy's eye always looks at its current target (waypoint or player)

## How It Works

### Node Tree

```
Main (Node2D)
├── Enemy (CharacterBody2D)    ← enemy.gd
│   └── StateLabel (Label)
├── Player (CharacterBody2D)   ← player.gd
└── Waypoints (Node2D)
    ├── WP0 (Marker2D)
    ├── WP1 (Marker2D)
    └── WP2 (Marker2D)
```

### `scripts/enemy.gd`

**State enum + reuse hook:**
```gdscript
enum State { PATROL, CHASE, RETURN }
signal state_changed(new_state: State)   # fires when the enemy switches state
```

**Exported tuning** (editable per-enemy in the Inspector):
```gdscript
@export var detect_range := 180.0  # distance to start chasing
@export var lose_range   := 280.0  # distance to give up chase
@export var patrol_speed := 80.0
@export var chase_speed  := 150.0
```

**`_ready()`** — Collects waypoint positions from `Marker2D` children of the `Waypoints` node into `waypoints: Array[Vector2]`.

**`_physics_process()`:**
```gdscript
func _physics_process(_delta: float) -> void:
    _transition()   # determine next state
    match state:
        State.PATROL: _patrol()
        State.CHASE:  _chase()
        State.RETURN: _return()
    queue_redraw()
```

**`_transition()`** — State machine logic (emits `state_changed` on a flip):
```gdscript
func _transition() -> void:
    var prev := state
    var dist := global_position.distance_to(player.global_position)
    match state:
        State.PATROL:
            if dist < detect_range:
                state = State.CHASE
        State.CHASE:
            if dist > lose_range:
                state = State.RETURN
        State.RETURN:
            if dist < detect_range:
                state = State.CHASE
            elif global_position.distance_to(waypoints[wp_index]) < 10:
                state = State.PATROL
    if state != prev:
        state_label.text = State.keys()[state]
        state_changed.emit(state)
```

**`_patrol()`** — Moves toward `waypoints[wp_index]`. When within 10 pixels of the current waypoint, advances `wp_index` cyclically: `wp_index = (wp_index + 1) % waypoints.size()`.

**`_chase()`** — Moves directly toward `player.global_position` at chase speed.

**`_return()`** — Moves toward `waypoints[wp_index]` at patrol speed, then transitions to PATROL when close.

**`_draw()`** — The enemy's color and eye position change per state. The eye looks at the patrol waypoint in PATROL state and at the player in CHASE state — a subtle but effective visual cue.

## Finite State Machine Theory

### What an FSM Is

A Finite State Machine consists of:
- A **finite set of states** (PATROL, CHASE, RETURN)
- **Transition rules** — conditions that move from one state to another
- **Behaviors** — what to do in each state

The key constraint: the machine is in exactly one state at any time. This prevents the "undefined behavior" of mixing partial behaviors from multiple states.

### Transition Hysteresis

Notice `detect_range` (180) is smaller than `lose_range` (280). This is **hysteresis** — a deliberate gap between the enter and exit conditions. Without it, if the player stood exactly at 180 pixels, the enemy would rapidly flip between PATROL and CHASE every frame ("jitter"). The wider `lose_range` means the player must move significantly further away before the enemy gives up.

This is the same principle used in thermostats: a heater turns on at 68°F and off at 72°F, not at exactly 70°F.

### Separation of Transition and Behavior

`_transition()` runs first, then `match state` dispatches behavior. This order ensures each state's behavior uses the **newly resolved state** each frame. The alternative (checking transitions inside each behavior function) mixes concerns and makes the logic harder to follow.

### Waypoint Cycling

```gdscript
wp_index = (wp_index + 1) % waypoints.size()
```

Modulo arithmetic wraps the index: after the last waypoint, it returns to 0. This works for any number of waypoints without range checking.

### Visual State Feedback

Color and eye direction change per state, giving the player non-verbal information about the enemy's mode. In a real game this might be accompanied by sound (detection bark) and animations. Keeping it visual in this demo makes the state machine behavior immediately legible.

## Files

| File | What it holds |
|------|---------------|
| `scripts/enemy.gd` | Emitted when the enemy changes state. Other systems (animation, an alert |
| `scripts/player.gd` | `player` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

Like [state-machine](../state-machine), this is kept as **one readable file** —
the lesson is the patrol→chase→return FSM read top to bottom, not a generic
framework. Reuse it by lifting the pattern into your own enemy:

1. Copy the `enum State`, the `@export` ranges/speeds, and the three-way `match` in `_transition()` / `_physics_process()`.
2. Point it at your player and waypoints (this demo reads `Marker2D` children of a `Waypoints` node in `_ready`; export a `NodePath` or an `Array[Vector2]` instead for a drop-in enemy).
3. Connect `state_changed(new_state)` to drive animation, an alert sound, or a HUD marker — the reuse hook that keeps presentation out of the FSM.

**Tuning** is exposed via `@export` (`detect_range`, `lose_range`, `patrol_speed`, `chase_speed`); keep `detect_range < lose_range` for the anti-jitter hysteresis described above.

> Input/globals: this enemy references the player via `$"../Player"`; in a real
> project prefer an `@export var target: Node2D` so the enemy isn't tied to a
> fixed scene layout.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `enum State { ... }` | Named integer constants for states |
| `match state: State.X: ...` | Pattern matching (cleaner than if/elif chains) |
| `global_position.distance_to(other)` | World-space distance |
| `direction.normalized() * speed` | Velocity toward a target |
| `move_and_slide()` | Move with collision |
| `Marker2D` | Empty positioned node, useful for waypoints |
| `Array.size()` | Length for modulo cycling |

## Related demos

- [simple-ai](../simple-ai) — An enemy that always moves directly toward the player.
- [vision-cone](../vision-cone) — A 120° FOV cone plus Liang-Barsky line-of-sight test against walls.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

