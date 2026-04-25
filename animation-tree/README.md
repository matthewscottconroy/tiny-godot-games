# Animation Tree

Demonstrates `AnimationTree` with `AnimationNodeStateMachine` — building a state machine in code that drives squash-and-stretch animations through idle, walk, jump, and land states.

## Purpose

`AnimationPlayer` plays individual clips; `AnimationTree` routes between them based on game state, with optional blending at transitions. This is the standard architecture for character animation in production games. Understanding how to build the state machine in code (rather than the editor GUI) exposes what the editor stores, and enables data-driven animation graphs loaded at runtime.

## Controls

- **Arrow keys / WASD**: Move left and right
- **Space / Up**: Jump

## How It Works

### Node Tree

```
Main (Node2D)                  ← main.gd
├── Player (Node2D)
│   ├── Visual (Node2D)        ← animated properties target this node
│   ├── AnimationPlayer        ← holds the animation clips
│   └── AnimationTree          ← state machine routing
└── HUD (CanvasLayer)
    └── StateLabel
```

### `scripts/main.gd`

- **`_build_animations()`** — Creates five `Animation` objects (idle, walk, jump, fall, land) as `VALUE` tracks on `Visual:scale` and `Visual:position`. Adds them to an `AnimationLibrary` under the `""` (default) namespace.
- **`_build_state_machine()`** — Creates an `AnimationNodeStateMachine`, adds one `AnimationNodeAnimation` per clip, and connects them with `AnimationNodeStateMachineTransition` objects. Sets `anim_tree.tree_root` and activates the tree.
- **`_playback`** — Retrieved via `anim_tree["parameters/playback"]` after activation. Calling `_playback.travel("walk")` tells the state machine to find a path to the "walk" node and play through any connecting transitions.
- **`_update_state()`** — Called each physics frame. Reads `_playback.get_current_node()` and calls `travel()` based on velocity and floor state.

### AnimationTree Architecture

```
AnimationPlayer   (holds clip data: "idle", "walk", "jump", "fall", "land")
      ↓
AnimationTree     (routes between clips via state machine)
   tree_root = AnimationNodeStateMachine
               ├── Node "idle"  → AnimationNodeAnimation("idle")
               ├── Node "walk"  → AnimationNodeAnimation("walk")
               ├── Node "jump"  → AnimationNodeAnimation("jump")
               ├── Node "fall"  → AnimationNodeAnimation("fall")
               └── Node "land"  → AnimationNodeAnimation("land")
```

### travel() vs. Conditions

This demo uses `_playback.travel("state")` — explicit state requests from code. Alternatively, `AnimationNodeStateMachineTransition.advance_condition` lets transitions trigger automatically when a boolean parameter (e.g. `anim_tree["parameters/conditions/is_walking"]`) changes. `travel()` is clearer for code-driven characters; conditions work better for data-driven graphs.

### Squash and Stretch

Animations drive `Visual:scale` (squash/stretch) and `Visual:position` (bob):
- **idle**: Gentle 1.06x width / 0.94x height breathing cycle
- **jump**: Launch squash → stretch at apex (1.25w/0.75h → 0.85w/1.18h)
- **land**: Impact squash (1.35w/0.65h) → settle to (1.0, 1.0)

The 0.08-second `xfade_time` on each transition blends between clips so state changes don't snap.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `AnimationNodeStateMachine` | State machine root for AnimationTree |
| `AnimationNodeAnimation` | Leaf node — references one AnimationPlayer clip |
| `AnimationNodeStateMachineTransition` | Defines how to move between states |
| `AnimationTree.tree_root` | The root AnimationNode of the graph |
| `AnimationTree.anim_player` | NodePath to the AnimationPlayer source |
| `anim_tree["parameters/playback"]` | Returns AnimationNodeStateMachinePlayback |
| `playback.travel("state")` | Request a transition to the named state |
| `playback.get_current_node()` | Name of the currently active state |
