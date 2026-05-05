# Stamina System

A depletable/regenerating resource that gates sprinting. Hold Shift to sprint at 360 px/s; stamina drains while sprinting and regenerates after a brief delay when you stop. Sprint is blocked when stamina is zero.

## Purpose

Stamina (or mana, energy, heat) systems are ubiquitous in action games. This demo shows the three-state pattern: drain while active, wait after stopping, then regen. The regen delay prevents players from tapping the action key to exploit instant regen.

## Controls

- **Arrow keys / WASD**: Move
- **Hold Shift**: Sprint (consumes stamina)
- **Up**: Jump

## How It Works

### Three-state logic (`scripts/player.gd`)

```gdscript
if sprinting:
    _stamina    = maxf(_stamina - DRAIN_RATE * delta, 0.0)
    _regen_wait = REGEN_DELAY
else:
    _regen_wait = maxf(_regen_wait - delta, 0.0)
    if _regen_wait <= 0.0:
        _stamina = minf(_stamina + REGEN_RATE * delta, STAMINA_MAX)
```

States:
1. **Sprinting** — drain stamina, reset regen timer
2. **Waiting** — regen timer counting down (no sprint, no regen yet)
3. **Regenerating** — regen timer expired, stamina refilling

The regen timer resets every frame while sprinting, so releasing Shift starts a clean countdown.

### Sprint gate

```gdscript
var want_sprint := Input.is_key_pressed(KEY_SHIFT) and h != 0.0
_sprinting = want_sprint and _stamina > 0.0
```

`_stamina > 0.0` is the gate. Sprint requests are acknowledged immediately — they just don't activate when depleted. The `h != 0.0` check prevents draining stamina while standing still and holding Shift.

### Visual feedback

```gdscript
func _draw() -> void:
    var col := Color.GOLD if _sprinting else Color.DODGER_BLUE
    draw_rect(Rect2(-12, -24, 24, 48), col)
```

Player turns gold while sprinting. The ProgressBar above shows stamina, turning orange-red when low.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Input.is_key_pressed(KEY_SHIFT)` | Held key check without InputMap configuration |
| `maxf(v - rate * delta, 0.0)` | Countdown timer clamped at zero |
| `minf(v + rate * delta, max)` | Regen clamped at maximum |
| `ProgressBar.value` | Direct assignment drives bar fill |
