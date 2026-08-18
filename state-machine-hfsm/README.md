# Hierarchical Finite State Machine (HFSM)

<!-- tags: component, shows-its-working -->

A character's behavior is organized into a tree of states — Alive contains Idle/Walk/Run/Combat, Combat contains Attack/Block/Dodge — with enter/exit callbacks, cascading transitions, and a real-time tree visualization.

## Purpose

A flat FSM works well for simple characters but breaks down as complexity grows. A character with 10 states needs up to 90 transitions. Worse, behaviors that are common to a group of states (like taking damage while in any combat state) must be duplicated in every member state. HFSMs solve this by grouping related states under a parent. Shared behavior lives in the parent; specializations live in children. A transition to "Combat" automatically enters the default combat sub-state without additional code.

HFSMs are used in game AI from Unreal Engine's behavior context system to character controllers in action games. They map naturally to hierarchical game design: a character is either Alive or Dead; while Alive they are either Moving or in Combat; while in Combat they are Attacking, Blocking, or Dodging. The hierarchy reflects the design, making it readable for both programmers and designers.

Use an HFSM over a flat FSM when you have groups of states that share behavior, or when transitions need to target a "group" rather than a specific state. Use a Behavior Tree instead when you need reactive priority-ordered decisions rather than explicit state transitions.

## How It Works

### HFSMState Class (`scripts/hfsm.gd`)

```gdscript
class_name HFSMState

var name:         String
var parent:       HFSMState = null
var children:     Array[HFSMState] = []
var active_child: HFSMState = null
var _on_enter:    Callable = func(): pass
var _on_exit:     Callable = func(): pass
var _on_tick:     Callable = func(_delta: float): pass
```

Each state is both a leaf (if it has no children) and a container (if it has children). The `active_child` pointer tracks which child is currently active — only one child is active at a time at each level.

### Enter and Exit

```gdscript
func enter() -> void:
    _on_enter.call()
    if children.size() > 0 and active_child == null:
        transition_to(children[0])  # auto-enter first child

func exit() -> void:
    if active_child:
        active_child.exit()  # cascading exit down the branch
        active_child = null
    _on_exit.call()
```

Entering a compound state automatically enters its default child. Exiting a compound state recursively exits all active descendants first, then fires `_on_exit` on the way back up.

### Transitions

```gdscript
func transition_to(target: HFSMState) -> void:
    if active_child:
        active_child.exit()   # exit the old child (cascading)
    active_child = target
    active_child.enter()      # enter the new child (cascading)
```

A transition at any level only exits/enters that level's `active_child`. Transitioning to `_alive` from `_dead` exits Dead and enters Alive (which auto-enters Idle). Transitioning to `_attack` from within Combat exits the current combat sub-state and enters Attack.

### Active Path Query

```gdscript
func is_active() -> bool:
    if parent == null: return true          # root is always active
    return parent.active_child == self and parent.is_active()

func get_active_path() -> Array[String]:
    var path: Array[String] = [name]
    if active_child:
        path.append_array(active_child.get_active_path())
    return path
```

`get_active_path()` returns the full breadcrumb from root to the deepest active leaf: `["Root", "Alive", "Combat", "Attack"]`.

### Building the Tree (`scripts/main.gd`)

```gdscript
_hfsm.add_child(_alive)
_hfsm.add_child(_dead)
_alive.add_child(_idle)
_alive.add_child(_walk)
_alive.add_child(_run)
_alive.add_child(_combat)
_combat.add_child(_attack)
_combat.add_child(_block)
_combat.add_child(_dodge)

_idle._on_enter = func(): _log_push("→ Idle: standing still")
_idle._on_exit  = func(): _log_push("← Idle: leaving idle")

_hfsm.enter()  # starts Root → Alive → Idle
```

## HFSM Theory

The hierarchy:

```
Root
├── Alive
│   ├── Idle
│   ├── Walk
│   ├── Run
│   └── Combat
│       ├── Attack   ← default combat sub-state
│       ├── Block
│       └── Dodge
└── Dead
```

At any moment the active path is a single branch from root to a leaf. Multiple states at different levels are simultaneously "active" (Alive and Combat and Attack), but only one per level.

**Transition rules**: Transitions happen at a specific level. `_alive.transition_to(_combat)` changes Alive's active child from whatever it was (Idle/Walk/Run) to Combat. Because Combat's first child is Attack, this also immediately activates Attack. `_combat.transition_to(_block)` changes only Combat's active child — Alive remains active.

**Enter/exit ordering**: On a transition from `Root > Alive > Walk` to `Root > Alive > Combat > Attack`, only Walk.exit() and Combat.enter() and Attack.enter() fire. Root and Alive are unaffected.

## How to Adapt This in Your Project

- Add a `_on_tick` callable to states that need per-frame logic (e.g., an `Attack` state that increments a combo timer).
- To support transition guards (only transition if a condition is met), wrap `transition_to` calls in `if` checks before calling — the HFSM doesn't need to know about the condition logic.
- For history states (re-entering a compound state restores the previously active child), add a `history_child` field to `HFSMState` and set it in `exit()`.
- The `get_active_path()` array can drive animation: map path strings to `AnimationPlayer` animations for automatic animation switching.
- To serialize the active state for save/load, store `get_active_path()` and on load call `transition_to` for each level in order.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Callable` | Stores `_on_enter`, `_on_exit`, `_on_tick` callbacks |
| `fn.call()` / `fn.call(delta)` | Invoke the callable |
| `Array[String]` | Typed return from `get_active_path()` |
| `draw_rect`, `draw_line`, `draw_circle` | Character figure and tree visualization |
| `draw_string(ThemeDB.fallback_font, ...)` | Text labels without Label nodes |

## Controls

| Key | Action |
|-----|--------|
| W | Walk |
| Shift+W | Run |
| I | Idle |
| C | Enter Combat (auto-enters Attack) |
| 1 | Combat → Attack |
| 2 | Combat → Block |
| 3 | Combat → Dodge |
| D | Die (health = 0, transition to Dead) |
| R | Revive (health = 100, transition to Alive → Idle) |

The left panel shows a stick figure whose pose and color reflect the current leaf state. The right panel highlights the active branch of the HFSM tree in blue.

## Key Constants

```gdscript
# State names are the only constants — all logic is in the HFSM structure
# Character visual dimensions:
var cx := 155.0   # character center x
var cy := 200.0   # character center y
```

## Files

| File | Purpose |
|------|---------|
| `scripts/hfsm.gd` | `HFSMState` class: `add_child`, `enter`, `exit`, `tick`, `transition_to`, `is_active`, `get_active_path` |
| `scripts/main.gd` | Builds the HFSM tree, handles input, draws character figure and tree panel |
| `scenes/main.tscn` | Main scene |
| `tests/test_logic.gd` | Unit tests: initial active state, transition, exit callback, default child, active path, cascading exit |
| `tests/test.tscn` | Test runner scene |

## Use as a building block

**Copy:** `scripts/hfsm.gd` — the `HFSMState` type. `scripts/main.gd` is the demo driver (it builds the scene and draws the visualisation) and is not needed.

**`HFSMState` API**
- `add_child(child: HFSMState) -> HFSMState`
- `enter() -> void`
- `exit() -> void`
- `tick(delta: float) -> void`
- `transition_to(target: HFSMState) -> void`
- `is_active() -> bool`
- `get_active_path() -> Array[String]`

**Notes**
- `class_name HFSMState` is global to the project — rename it if you already define that type.

## Related demos

- [autoload-score](../autoload-score) — The Autoload/Singleton pattern: global state that emits change signals.
- [state-machine](../state-machine) — A four-state FSM (idle/walk/jump/fall) derived from physics state.
- [boid-flocking](../boid-flocking) — 35 agents flock via separation, alignment, and cohesion — emergent behavior.
- [drop-table](../drop-table) — Weighted random loot; watch observed rates converge on expected probabilities.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

