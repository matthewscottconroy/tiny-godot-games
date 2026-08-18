# Health Bar

<!-- tags: ui, signals, component -->

Implements a complete health system with animated HP bar, color-coded feedback flashes, a reactive character display, and game-over state — all driven by a central HP value.

## Purpose

Health is one of the most common game systems, yet implementing it cleanly requires several pieces working together: clamped HP arithmetic, animated UI feedback, color transitions based on HP ratio, and state communication between different visual components. This demo shows how to coordinate all of these around a single source of truth.

## Controls

- **Damage button**: Subtract 10 HP (clamped at 0)
- **Heal button**: Add 10 HP (clamped at MAX_HP)
- The progress bar animates, the character fades from blue to red, and at 0 HP the character shows "X" eyes

## How It Works

### Node Tree

```
Main (Node2D)                   ← main.gd  (the view)
├── Health (Node)               ← health.gd  →  class_name Health (the model)
├── HPBar (ProgressBar)
├── HPLabel (Label)
├── GameOverLabel (Label)
├── PlayerDisplay (Node2D)      ← player_display.gd
├── DamageBtn (Button)
└── HealBtn (Button)
```

This is a **model / view** split. `Health` owns the number and the rules; `main.gd` owns the presentation and reacts to the model's signals. That separation is what makes the health system reusable — the model has no idea a `ProgressBar` exists.

### `scripts/health.gd` — The HP Model (`class_name Health`)

Holds the single authoritative HP value and all mutation logic, and announces changes via signals.

```gdscript
signal health_changed(hp: int, max_hp: int)
signal died

@export var max_hp := 100
var hp: int

func damage(amount: int) -> void:
    if hp <= 0: return          # can't hurt the dead
    hp = maxi(0, hp - amount)   # never negative
    health_changed.emit(hp, max_hp)
    if hp == 0:
        died.emit()
```

`heal()` mirrors this (clamped to `max_hp`, can revive from 0). The model never touches UI — it only emits `health_changed` / `died`.

### `scripts/main.gd` — The View

The buttons call `health.damage(10)` / `health.heal(10)`; everything visual happens in response to `health_changed`:

```gdscript
func _on_health_changed(hp: int, max_hp: int) -> void:
    # direction of change picks the flash colour
    if hp < _shown_hp: _flash(Color.TOMATO)
    elif hp > _shown_hp: _flash(Color.LIME_GREEN)
    _shown_hp = hp
    var tween := create_tween()
    tween.tween_property(hp_bar, "value", float(hp), 0.2)
    hp_label.text = "HP: %d / %d" % [hp, max_hp]
    player_display.hp_ratio = float(hp) / max_hp
    game_over_label.visible = hp == 0
```

Tweening `hp_bar.value` gives a smooth drain/fill rather than a snap. `hp_label` updates instantly (numbers should be exact); the bar is decorative and can lag by 200 ms.

**Flash feedback:**
```gdscript
func _flash(color: Color) -> void:
    var tween := create_tween()
    tween.tween_property(hp_bar, "modulate", color, 0.05)
    tween.tween_property(hp_bar, "modulate", Color.WHITE, 0.35)
```

Two sequential tween steps: snap to the hit color quickly, then fade back to white slowly. This creates a "flash" feel — fast red flash, slow recovery.

### `scripts/player_display.gd` — Reactive Visual

```gdscript
var hp_ratio := 1.0 :
    set(v):
        hp_ratio = v
        queue_redraw()

func _draw() -> void:
    var color := Color.CORNFLOWER_BLUE.lerp(Color.TOMATO, 1.0 - hp_ratio)
    draw_rect(...)
    if hp_ratio > 0.0:
        # normal eyes
    else:
        # X eyes (dead)
```

`hp_ratio` uses a property setter: any assignment triggers `queue_redraw()`, so the visual always reflects the latest value without polling.

`Color.lerp(other, t)` interpolates between two colors. At `hp_ratio = 1.0` (full health): `t = 0.0` → blue. At `hp_ratio = 0.0` (dead): `t = 1.0` → red. At half health: `t = 0.5` → purple.

The dead state draws crossed lines over the eye positions instead of rectangles, using `draw_line()`.

## Design Theory

### Single Source of Truth

`hp` lives only inside the `Health` model. `HPBar` and `PlayerDisplay` do not store HP — they receive it on each `health_changed` signal. This means there is no possibility of the bar and the display showing different values.

### Clamping

```gdscript
hp = maxi(0, hp - amount)        # cannot go below 0
hp = mini(max_hp, hp + amount)   # cannot exceed max_hp
```

These clamps are applied inside `Health` at the point of mutation, not at the display layer. Every view reads the already-clamped value.

### Tween for UX Polish

Instant value jumps are jarring. A 200ms tween on the bar gives the player's eye time to track the change. The label shows the exact number immediately (critical information) while the bar provides the emotional impact (slow drain).

### Color Lerp for State Communication

Rather than switching between two fixed colors, `lerp` gives a continuous spectrum. At 60% HP the character is slightly purple — a visual warning that communicates HP without requiring the player to read the number. This is a common game UX technique.

## Files

| File | What it holds |
|------|---------------|
| `scripts/health.gd` | A reusable hit-point model. Holds hp/max_hp and emits signals on change and |
| `scripts/main.gd` | Demo driver: the buttons call the reusable Health model (scripts/health.gd); |
| `scripts/player_display.gd` | `player display` behaviour |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite |

## Use as a building block

**Copy:** `scripts/health.gd` (the `Health` class). It's a plain `Node` with no UI or scene dependencies.

**Public API**
- `@export max_hp: int`
- `hp: int` — current value (set to `max_hp` on `_ready`).
- `damage(amount)` / `heal(amount)` — clamped mutation; `heal` can revive from 0.
- signals `health_changed(hp, max_hp)`, `died`.

**Integrate**
1. Add a `Health` node under any entity (player, enemy, destructible), set `max_hp` in the Inspector.
2. Deal damage from a hitbox/trap: `$Health.damage(10)`.
3. Wire the view: `health.health_changed.connect(_update_bar)` and `health.died.connect(_on_death)` — the model stays UI-agnostic, so the same `Health` drives a bar, a shader, or nothing.

**Notes**
- `class_name Health` is global — rename if it collides.
- For regeneration, call `heal()` from a `Timer`; for armor/resistance, scale `amount` before calling `damage()`.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ProgressBar.value` | Current fill amount |
| `ProgressBar.max_value` | Maximum fill value |
| `ProgressBar.modulate` | Tint multiplied over the bar's color |
| `create_tween().tween_property(node, prop, target, time)` | Animate property |
| `Color.lerp(other, t)` | Interpolate between two colors |
| `var x: T: set(v):` | Property setter for reactive updates |
| `draw_line(from, to, color, width)` | Line in _draw() |

## Related demos

- [hitbox-hurtbox](../hitbox-hurtbox) — The hitbox/hurtbox pattern — attack area separate from vulnerable area.
- [knockback](../knockback) — Velocity-based hit recoil that decays exponentially, with i-frames.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

