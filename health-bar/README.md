# Health Bar

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
Main (Node2D)                   ← main.gd
├── HPBar (ProgressBar)
├── HPLabel (Label)
├── GameOverLabel (Label)
├── PlayerDisplay (Node2D)      ← player_display.gd
├── DamageBtn (Button)
└── HealBtn (Button)
```

### `scripts/main.gd` — The HP Controller

Holds the single authoritative HP value and all mutation logic.

```gdscript
const MAX_HP := 100
var hp := MAX_HP

func _damage() -> void:
    if hp <= 0: return
    hp = max(0, hp - 10)
    _refresh()
    _flash(Color.TOMATO)
    if hp == 0:
        game_over_label.visible = true
```

- `max(0, hp - 10)` prevents HP from going negative.
- `_refresh()` triggers a Tween on `hp_bar.value` and propagates `hp_ratio` to `PlayerDisplay`.
- `_flash(color)` briefly tints the progress bar red (damage) or green (heal).

**Animated bar:**
```gdscript
func _refresh() -> void:
    var tween := create_tween()
    tween.tween_property(hp_bar, "value", float(hp), 0.2)
    hp_label.text = "HP: %d / %d" % [hp, MAX_HP]
    player_display.hp_ratio = float(hp) / MAX_HP
```

Tweening `hp_bar.value` gives a smooth bar drain/fill rather than a snap. `hp_label` updates instantly (numbers should be exact); the bar is decorative and can lag by 200 ms.

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

`hp` lives only in `main.gd`. `HPBar` and `PlayerDisplay` do not store HP — they receive it on each update. This means there is no possibility of the bar and the display showing different values.

### Clamping

```gdscript
hp = max(0, hp - 10)   # cannot go below 0
hp = min(MAX_HP, hp + 10)  # cannot exceed MAX_HP
```

These clamps are applied at the point of mutation, not at the display layer. Every display reads the already-clamped value.

### Tween for UX Polish

Instant value jumps are jarring. A 200ms tween on the bar gives the player's eye time to track the change. The label shows the exact number immediately (critical information) while the bar provides the emotional impact (slow drain).

### Color Lerp for State Communication

Rather than switching between two fixed colors, `lerp` gives a continuous spectrum. At 60% HP the character is slightly purple — a visual warning that communicates HP without requiring the player to read the number. This is a common game UX technique.

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
