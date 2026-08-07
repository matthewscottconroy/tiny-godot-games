# Wave Spawner

A phase-based wave system with intermission countdowns, per-wave difficulty scaling, and click-to-damage enemies — the standard pattern for horde modes, tower defense, and arena survival games.

## Purpose

Wave spawning is one of the most recurring game systems. It appears in tower defense (Plants vs. Zombies), bullet hells (Enter the Gungeon), arena shooters (Doom Eternal), and survival games (Vampire Survivors). The core design problem is managing state across three distinct phases — waiting for player readiness, counting down to the next wave, and running an active wave — without the logic becoming an unreadable tangle of booleans.

This demo solves that cleanly with a `Phase` enum and a single float timer. Transitions are explicit: only one function can enter each phase. The difficulty progression formula is exposed as simple arithmetic, making it trivial to tune. Enemy data is stored as node metadata rather than requiring a dedicated `Enemy` class, showing how to attach arbitrary state to plain `Node2D` objects in GDScript.

## How It Works

### Node Tree

```
Main (Node2D)          ← main.gd  (spawns + draws enemies)
├── WaveLabel
├── StatusLabel
├── EnemyCountLabel
├── Enemies (Node2D)   ← enemy nodes dynamically added here
└── Buttons (HBoxContainer)
    └── [StartBtn, SkipBtn]
```

The phase machine lives in a reusable class, `WaveSpawner`
(`scripts/wave_spawner.gd`), a plain `RefCounted`. It emits signals; `main.gd`
responds by spawning/ticking enemies and calls `wave_cleared()` when the arena
empties. The spawner never touches a node.

### Phase State Machine (`WaveSpawner`)

```gdscript
enum Phase { IDLE, INTERMISSION, WAVE }
```

| Phase | Condition to enter | Condition to exit |
|-------|--------------------|-------------------|
| `IDLE` | Game start, or all waves cleared | `start()` called |
| `INTERMISSION` | After `start()`, or a wave cleared | Countdown reaches 0 |
| `WAVE` | Intermission ends (`wave_started`) | Game calls `wave_cleared()` |

Transitions live in `start()`, `_begin_intermission()`, and `update()`. The game reacts to `intermission_started` / `wave_started` / `all_waves_cleared` — no cross-phase side effects, and the spawner is decoupled from how enemies actually work.

### Difficulty Scaling

```gdscript
func _begin_wave() -> void:
    var count := 3 + (wave - 1) * 2   # wave 1→3, 2→5, 3→7, 4→9, 5→11
    var speed := 40.0 + wave * 12.0   # wave 1→52, 2→64, 3→76, 4→88, 5→100 px/s
    # HP assigned per enemy: 2 + wave   (wave 1→3, 2→4, 3→5, 4→6, 5→7 hits)
```

Linear scaling keeps the math readable. For a real game, replace the linear formulas with an exported curve (`Curve` resource) or a lookup table for fine-grained control over difficulty pacing.

### Enemy Spawning

Enemies are plain `Node2D` instances with gameplay state stored as metadata:

```gdscript
func _spawn_enemy(speed: float) -> void:
    var e := Node2D.new()
    var vel := Vector2(randf_range(-speed, speed), randf_range(-speed, speed))
    if vel.length() < 10: vel = Vector2(speed, 0)  # avoid zero velocity
    e.set_meta("vel", vel)
    e.set_meta("hp",  2 + wave)
    e.position = Vector2(randf_range(60, 580), randf_range(120, 420))
    e.draw.connect(func():
        e.draw_circle(Vector2.ZERO, 14, ENEMY_COLORS[wave % ENEMY_COLORS.size()])
        e.draw_circle(Vector2(-4, -3), 3, Color.WHITE)
        e.draw_circle(Vector2( 4, -3), 3, Color.WHITE))
    enemies.add_child(e)
```

Each enemy connects a lambda to its own `draw` signal for custom rendering. This avoids the need for a dedicated `Enemy` scene or script while still giving each node independent visual behavior.

### Enemy Movement

```gdscript
func _tick_enemies(delta: float) -> void:
    for e in enemies.get_children():
        var vel: Vector2 = e.get_meta("vel")
        e.position += vel * delta
        if e.position.x < 40 or e.position.x > 600: vel.x *= -1
        if e.position.y < 110 or e.position.y > 440: vel.y *= -1
        e.set_meta("vel", vel)
        e.queue_redraw()
```

Enemies bounce off arena walls by negating the relevant velocity component. This is intentional velocity-inversion physics — simpler than reflection math and appropriate for the bouncy-ball-style behavior shown here.

### Click-to-Damage

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if phase != Phase.WAVE: return
        for e in enemies.get_children():
            if e.position.distance_to(event.position) < 18:
                var hp: int = e.get_meta("hp") - 1
                if hp <= 0:
                    e.queue_free()
                else:
                    e.set_meta("hp", hp)
                break  # only hit one enemy per click
```

`queue_free()` schedules the node for deletion at the end of the frame — safe to call while iterating `get_children()`. The `break` ensures exactly one enemy is damaged per click, preventing accidental multi-hit when enemies overlap.

### Wave Completion Check

```gdscript
Phase.WAVE:
    _tick_enemies(delta)
    if enemies.get_child_count() == 0:
        if wave >= 5:
            phase = Phase.IDLE
            status.text = "You survived all 5 waves!"
        else:
            _begin_intermission()
```

The child count check is the simplest possible "all enemies dead" test. For more complex scenarios (enemies that spawn sub-enemies, off-screen enemies), maintain an explicit `alive` counter incremented on spawn and decremented on death.

## Intermission Timer

```gdscript
var intermission_duration := 3.0

Phase.INTERMISSION:
    timer -= delta
    status.text = "Wave %d incoming in %.1f…" % [wave, maxf(timer, 0.0)]
    if timer <= 0.0:
        _begin_wave()
```

`maxf(timer, 0.0)` prevents the label from briefly showing negative numbers on the last frame. The Skip button sets `timer = 0.0` directly — no special state needed.

## How to Adapt This in Your Project

- **Enemy scenes**: replace `Node2D.new()` with `enemy_scene.instantiate()` for enemies with their own scripts and animations. The metadata pattern scales to any node type.
- **Spawn patterns**: replace random position with a list of spawn points (`marker_array[randi() % marker_array.size()]`) for designed spawn locations on a level.
- **Boss waves**: add a `BOSS` phase after every 5th wave. Use the same timer-based approach for boss intro cutscenes.
- **Difficulty curves**: replace linear formulas with `curve_resource.sample(wave / max_waves)` for fine-tuned pacing over 20+ waves.
- **Persistence**: serialize `wave`, `phase`, and enemy positions via `var_to_bytes()` to implement mid-wave checkpointing.

## Use as a building block

**Copy:** `scripts/wave_spawner.gd` (the `WaveSpawner` class). It's a `RefCounted` — the phase/countdown/scaling loop, with no knowledge of your enemies.

**Public API**
- tuning: `max_waves`, `intermission_duration`, `base_count`, `count_per_wave`
- state: `wave`, `phase`, `timer`; `enemy_count_for(w)`
- `start()`, `skip_intermission()`, `wave_cleared()`, `update(delta)`
- signals `intermission_started(wave, duration)`, `wave_started(wave, enemy_count)`, `all_waves_cleared`

**Integrate**
1. `var waves := WaveSpawner.new()`; connect the three signals.
2. On `wave_started(wave, count)`: spawn `count` enemies (scale *their* speed/HP however you like — that's game-specific).
3. Each frame: `waves.update(delta)`; when your enemy container is empty during a wave, call `waves.wave_cleared()`.

**Notes**
- `class_name WaveSpawner` is global — rename if it collides.
- It scales *count* (`enemy_count_for`); scale enemy stats in your `wave_started` handler using `waves.wave`.
- Reference its enum as `WaveSpawner.Phase.WAVE`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Node2D` | Physics-free game object used as an enemy container |
| `Node.set_meta(key, value)` | Attach arbitrary data to a node |
| `Node.get_meta(key)` | Read attached node data |
| `CanvasItem.draw.connect(callable)` | Lambda-based custom draw per node |
| `CanvasItem.queue_redraw()` | Trigger redraw of a specific node |
| `Node.get_child_count()` | Count active enemies in the container |
| `Node.queue_free()` | Safely defer node deletion to end of frame |
| `randf_range(min, max)` | Random float in range |

## Controls

| Input | Action |
|-------|--------|
| **Start button** | Begin the wave sequence (from IDLE) |
| **Skip button** | Skip the intermission countdown |
| **Left-click on enemy** | Deal 1 damage |

## Key Constants

```gdscript
var intermission_duration := 3.0  # seconds between waves

# Per-wave scaling formulas (wave 1 through 5):
# count = 3 + (wave - 1) * 2     → 3, 5, 7, 9, 11
# speed = 40.0 + wave * 12.0     → 52, 64, 76, 88, 100 px/s
# hp    = 2 + wave                → 3, 4, 5, 6, 7 hits
```

## Files

| File | Purpose |
|------|---------|
| `scripts/wave_spawner.gd` | **`WaveSpawner`** — reusable phase/wave loop (`start`/`update`/`wave_cleared`) |
| `scripts/main.gd` | Spawning, enemy movement, click damage; drives a `WaveSpawner` |
| `scenes/main.tscn` | Root scene with labels, Enemies container, and buttons |
