# State Machine

<!-- tags: physics, ui, signals -->

Implements a four-state Finite State Machine for a platformer character: IDLE, WALK, JUMP, and FALL — each with a distinct color — driven by physics state.

## Purpose

A state machine is one of the most important patterns in game programming. Without it, player state (idle, walking, jumping, falling) is tracked with scattered boolean flags that conflict and produce bugs. A proper FSM makes states explicit, mutually exclusive, and their transitions clear. This demo shows the minimal FSM needed for a platformer character and how to derive states from physics data.

## Controls

- **Arrow keys**: Move left and right
- **Up / W**: Jump
- Watch the character change color with each state change, and the state label update

## How It Works

### Node Tree

```
Player (CharacterBody2D)     ← player.gd
├── StateLabel (Label)
└── CollisionShape2D
```

### `scripts/player.gd`

**State enum:**
```gdscript
enum State { IDLE, WALK, JUMP, FALL }
var state := State.IDLE
```

**Per-state colors:**
```gdscript
var color := {
    State.IDLE: Color.SEA_GREEN,
    State.WALK: Color.LIME_GREEN,
    State.JUMP: Color.SKY_BLUE,
    State.FALL: Color.ORANGE,
}[state]
```

Using a dictionary keyed by state enum values is cleaner than a chain of `if/elif` statements. The expression `{...}[state]` looks up the current state's color in a single step.

Movement values are `@export`ed (`speed`, `jump_velocity`, `gravity`, `walk_threshold`) so they can be tuned per-character in the Inspector without editing the script.

**Physics loop:**
```gdscript
func _physics_process(delta: float) -> void:
    var dir := Input.get_axis("ui_left", "ui_right")
    velocity.x = dir * speed
    if not is_on_floor():
        velocity.y += gravity * delta
    if is_on_floor() and Input.is_action_just_pressed("ui_up"):
        velocity.y = jump_velocity
    move_and_slide()
    _transition()
    queue_redraw()
```

Physics runs first, then `_transition()` derives the new state from the updated physics state. This order ensures the state reflects what just happened, not a prediction of what will happen.

**`_transition()`:**
```gdscript
func _transition() -> void:
    var prev := state
    if is_on_floor():
        state = State.WALK if abs(velocity.x) > walk_threshold else State.IDLE
    else:
        state = State.JUMP if velocity.y < 0 else State.FALL
    if state != prev:
        state_label.text = State.keys()[state]
        state_changed.emit(state)     # reuse hook for animation/audio/UI
```

The transition logic:
- **On floor**: WALK if moving horizontally, IDLE if still
- **In air**: JUMP if moving upward (velocity.y < 0 because Godot's Y axis points down), FALL if moving downward

When the state actually changes, the script emits `state_changed(new_state)`. Nothing in this demo listens to it, but it's the seam a real game hooks into — swap an animation, play a landing sound, update a HUD — without that code having to poll `state` every frame.

`State.keys()[state]` returns the string name of the enum value at index `state` — e.g. `State.keys()[State.JUMP]` = `"JUMP"`. This avoids maintaining a separate name dictionary.

## State Machine Theory

### What States Give You

Without a state machine:
```gdscript
var is_jumping := false
var is_walking := false
var is_falling := false
# These can be true simultaneously — which combination means what?
```

With a state machine, the character is in exactly **one** state at any time. Every combination of conditions maps to exactly one state. This eliminates impossible flag combinations.

### Transition Derivation vs Explicit Transitions

This demo derives state from physics data (floor contact, velocity) rather than maintaining explicit transitions:
```
old_state + conditions → new_state
```

This is simpler than a traditional FSM where each state explicitly lists which transitions lead to which other states. The derived approach works well when states map cleanly onto measurable quantities.

An explicit FSM would look like:
```gdscript
match state:
    State.IDLE:
        if velocity.x > 10: state = State.WALK
        if not is_on_floor(): state = State.FALL
    State.WALK:
        if velocity.x < 10: state = State.IDLE
        # ...
```

### Running Transitions After Physics

`move_and_slide()` updates `is_on_floor()` based on the movement that just happened. If `_transition()` ran before `move_and_slide()`, it would use the previous frame's floor state — potentially causing one-frame glitches when landing or taking off.

### State.keys()[index]

`enum State { IDLE, WALK, JUMP, FALL }` assigns integer values 0, 1, 2, 3 to the names. `State.keys()` returns `["IDLE", "WALK", "JUMP", "FALL"]`. Indexing by the current state integer returns the string name — a convenient way to convert an enum to its string representation.

### Visual State Feedback

Color-coding states serves two purposes:
1. **Game feel**: Players unconsciously register state from color, adding expressiveness without UI clutter
2. **Development**: The color makes the state machine's behavior visible and debuggable

In a real game, this would typically be animation clips keyed to each state.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `enum State { ... }` | Named integer constants |
| `CharacterBody2D.is_on_floor()` | True when resting on a surface |
| `CharacterBody2D.velocity` | Current velocity vector |
| `Input.get_axis(neg, pos)` | −1 to +1 input on one axis |
| `Input.is_action_just_pressed(action)` | Edge-triggered (fires once per press) |
| `move_and_slide()` | Move with collision; updates floor state |
| `Enum.keys()` | Array of string names for enum values |

## Files

| File | What it holds |
|------|---------------|
| `scripts/player.gd` | Emitted whenever the derived state changes. Other systems — an |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

This demo is intentionally **one readable file**, not a generic framework. The
lesson is the *derived-FSM pattern* — `enum` + a single `_transition()` that
reads physics each frame — and that pattern is clearest when you can read it
top to bottom. Wrapping it in a pluggable `StateMachine`/`State`-node system
would teach a different (and heavier) thing. So to reuse it:

**Lift the pattern, not a class.** Copy the three pieces into your own character:
1. `enum State { ... }` — your character's mutually-exclusive states.
2. `var state` + `signal state_changed(new_state)` — the current state and its reuse hook.
3. `_transition()` — derive the new state from measurable data (floor contact, velocity, health, input) and emit `state_changed` when it flips.

**Connect the signal** to drive presentation without polling:
```gdscript
player.state_changed.connect(func(s):
    animation.play(Player.State.keys()[s].to_lower()))
```

**Tuning** is exposed via `@export` (`speed`, `jump_velocity`, `gravity`, `walk_threshold`) — set per-character in the Inspector.

**When to reach for a heavier FSM instead:** if states need per-state
enter/exit code, timers, or transitions that don't map cleanly onto measurable
quantities, graduate to an explicit state object per state. See the
[state-machine-hfsm](../state-machine-hfsm) demo for that approach.

> Note: input uses the built-in `ui_*` actions for zero setup; in a real project
> define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [groups](../groups) — Broadcast a method call to every node in a named group in one line.
- [state-machine-hfsm](../state-machine-hfsm) — A hierarchical FSM tree with enter/exit callbacks and cascading transitions.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

