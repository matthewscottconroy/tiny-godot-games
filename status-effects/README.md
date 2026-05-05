# Status Effects

Poison, burn, and freeze effects applied by walking into colored floor zones. Each effect is a timed modifier stored in a dictionary; multiple effects can be active simultaneously. Demonstrates a clean, data-driven effect stack pattern.

## Purpose

Status effects appear in virtually every RPG and action game. The key design is keeping them data-driven: a single dictionary describes each effect's damage, slow, and duration, so adding a new effect means adding one entry, not subclassing.

## Controls

- **Arrow keys / WASD**: Move (movement slows when frozen)
- Walk into colored zones to receive each effect

## Effects

| Zone | Effect | DPS | Speed | Duration |
|------|--------|-----|-------|----------|
| Green | Poison | 10/s | 100% | 5 s |
| Red | Burn | 22/s | 100% | 3 s |
| Blue | Freeze | 0 | 35% | 4 s |

## How It Works

### Data-driven config (`scripts/player.gd`)

```gdscript
const EFFECT_CFG := {
    "poison": {"dps": 10.0, "slow": 1.00, "duration": 5.0},
    "burn":   {"dps": 22.0, "slow": 1.00, "duration": 3.0},
    "freeze": {"dps":  0.0, "slow": 0.35, "duration": 4.0},
}

var _active: Dictionary = {}  # {name: time_remaining}
```

### Applying and ticking effects

```gdscript
func apply_effect(name: String) -> void:
    _active[name] = EFFECT_CFG[name]["duration"]

func _physics_process(delta: float) -> void:
    var slow := 1.0
    for fx in _active.keys():
        _active[fx] -= delta
        _hp  -= EFFECT_CFG[fx]["dps"] * delta
        slow  = minf(slow, EFFECT_CFG[fx]["slow"])
```

Multiple effects coexist in `_active`. The `slow` multiplier takes the minimum across all active effects — the most restrictive one wins.

### Zone connection (`scripts/main.gd`)

```gdscript
zone.body_entered.connect(_on_zone_entered.bind(effect_name))

func _on_zone_entered(body: Node2D, effect_name: String) -> void:
    if body.has_method("apply_effect"):
        body.apply_effect(effect_name)
```

`.bind()` captures `effect_name` per zone — avoids closure issues in loops.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Dictionary.has(key)` | Check if effect is currently active |
| `Dictionary.erase(key)` | Remove expired effect |
| `Signal.bind(args...)` | Bind extra arguments to a signal callback |
| `node.get_meta("effect")` | Read metadata stored in .tscn per-node |
