# Status Effects

Poison, burn, and freeze effects applied by walking into colored floor zones. Each effect is a timed modifier stored in a dictionary; multiple effects can be active simultaneously. Demonstrates a clean, data-driven effect stack pattern.

## Purpose

Status effects appear in virtually every RPG, action game, and roguelike. The naive implementation — a boolean `is_poisoned`, a separate timer, a separate damage routine for each effect — becomes unmanageable as the effect count grows. Adding a fourth effect means adding a fourth boolean, timer, damage function, and rendering case.

The data-driven dictionary approach used here scales to dozens of effects without adding new code paths: adding a new effect means adding one entry to `EFFECT_CFG`. The tick loop, the slow multiplier, and the HUD update all handle it automatically. This is the pattern used in production RPGs where designers need to add new effects without touching gameplay code.

This demo also shows stacking: all active effects run simultaneously, and the most restrictive slow multiplier wins — walking into both a burn zone and a freeze zone applies both damage-per-second values while capping speed at freeze's 35%.

## How It Works

The stacking/timing logic lives in a reusable class, `StatusEffectStack`
(`scripts/status_effect_stack.gd`), a plain `RefCounted`. The player owns one,
hands it a catalog of effect definitions, and calls `tick(delta)` each frame;
the stack returns how much damage to apply and the movement multiplier. The
player keeps only the catalog (which includes demo-only data like colour) and
the presentation.

### Data-Driven Config

```gdscript
# scripts/player.gd — the catalog is game data, handed to the stack
const EFFECT_CFG := {
    "poison": {"color": Color(0.20, 0.90, 0.20), "dps": 10.0, "slow": 1.00, "duration": 5.0},
    "burn":   {"color": Color(1.00, 0.30, 0.10), "dps": 22.0, "slow": 1.00, "duration": 3.0},
    "freeze": {"color": Color(0.30, 0.70, 1.00), "dps":  0.0, "slow": 0.35, "duration": 4.0},
}

var _fx := StatusEffectStack.new(EFFECT_CFG)
```

Each effect is fully described by its catalog entry. The stack stores only the remaining duration per active effect — no per-effect state beyond time.

### Applying Effects

```gdscript
func apply_effect(name: String) -> void:
    _fx.apply(name)     # resets the timer to the catalog duration
```

Re-applying refreshes the duration (overwrites the existing timer) — the standard "refresh on reapply" behavior. An alternative would `maxf` the existing and new duration to prevent refresh exploitation.

### Ticking All Active Effects (inside `StatusEffectStack.tick`)

```gdscript
func tick(delta: float) -> Dictionary:
    var damage := 0.0
    var slow := 1.0
    var expired: Array = []
    for effect in _remaining:
        _remaining[effect] -= delta
        var cfg: Dictionary = catalog[effect]
        damage += cfg.get("dps", 0.0) * delta
        slow = minf(slow, cfg.get("slow", 1.0))
        if _remaining[effect] <= 0.0:
            expired.append(effect)
    for effect in expired:
        _remaining.erase(effect); effect_expired.emit(effect)
    return {"damage": damage, "slow": slow}
```

The `slow` multiplier uses `minf` so the most restrictive active effect always wins. Expired effects are collected in `expired` and erased after the loop — modifying a dictionary while iterating it is unsafe. The player then applies the result: `_hp -= result["damage"]` and `velocity.x = input * SPEED * result["slow"]`.

### Zone Connections

```gdscript
# scripts/main.gd
func _ready() -> void:
    for zone_name in ["PoisonZone", "BurnZone", "FreezeZone"]:
        var zone: Area2D = get_node(zone_name)
        var effect_name: String = zone.get_meta("effect")
        zone.body_entered.connect(_on_zone_entered.bind(effect_name))

func _on_zone_entered(body: Node2D, effect_name: String) -> void:
    if body.has_method("apply_effect"):
        body.apply_effect(effect_name)
```

`get_meta("effect")` reads a metadata key set on the Zone node in the scene. `.bind(effect_name)` captures the effect name per-zone at connection time — without `.bind()`, the lambda in a loop would capture the loop variable by reference, and all three zones would apply the last effect.

### Visual Feedback

```gdscript
func _draw() -> void:
    var col := Color.DODGER_BLUE
    for fx in _fx.active():
        col = col.lerp(EFFECT_CFG[fx]["color"], 0.65)
    draw_rect(Rect2(-12, -24, 24, 48), col)
```

The player's color blends toward each active effect's color (read from the catalog via `_fx.active()`). With both poison and freeze active, the player turns a cyan-green mix, giving intuitive multi-effect feedback.

## Effect Stack Design

### Slow Multiplier Strategy: Minimum vs Additive

This demo uses `minf` (most restrictive wins). Alternatives:
- **Multiply**: `slow *= cfg["slow"]` — stacking two 50% slows gives 25% speed. Used in some ARPGs.
- **Additive penalty**: `slow -= (1.0 - cfg["slow"])` — stacking two 50% slows gives 0% speed. Creates harsh stacking.

The minimum approach is most player-friendly and predictable.

### Duration Refresh vs Stack

Reapplying the same effect overwrites the duration. An alternative: cap at `maxf(existing, new_duration)` to prevent refresh, or allow stacks (a counter that multiplies DPS). Implement that by changing `_active` to store `{name: {time, stacks}}` instead of a simple float.

## How to Adapt This in Your Project

- **New effects**: Add one entry to `EFFECT_CFG` with `dps`, `slow`, `duration`, and `color`. No other code changes needed.
- **Persistent effects from items**: Call `player.apply_effect("regen")` from item pickup code; add `"regen"` to `EFFECT_CFG` with negative `dps` (-5.0 = 5 HP/s healing).
- **Boss aura**: Attach a `Timer` to a boss node; on `timeout`, call `player.apply_effect("curse")` to reapply every 2 seconds regardless of the player's position.
- **UI icons**: Iterate `_fx.active()` in a HUD script and show/hide icon nodes by effect name — the data is already there.

## Use as a building block

**Copy:** `scripts/status_effect_stack.gd` (the `StatusEffectStack` class). It's a `RefCounted` with no scene dependencies; effect definitions are plain dictionaries you supply.

**Public API**
- `_init(catalog)` / `catalog` — `name -> {dps, slow, duration, ...}` (extra keys like `color` are ignored by the stack, read by you).
- `apply(effect)` — start/refresh an effect.
- `tick(delta) -> {"damage": float, "slow": float}` — call each frame; apply the result to HP and movement.
- `active() -> Array`, `time_left(effect) -> float`.
- signals `effect_applied(effect)`, `effect_expired(effect)`.

**Integrate**
1. Define a catalog and `var fx := StatusEffectStack.new(catalog)`.
2. Apply from traps/abilities: `fx.apply("poison")`.
3. Each frame: `var r := fx.tick(delta); hp -= r.damage; speed_mult = r.slow`.

**Notes**
- `class_name StatusEffectStack` is global — rename if it collides.
- The stack aggregates `dps` (summed) and `slow` (min). For other modifiers (defense, damage-boost) add keys to the catalog and aggregate them in your own `tick` wrapper, or extend the return dictionary.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Dictionary` | Stores active effects and their remaining durations |
| `Dictionary.keys()` | Iterate over active effect names |
| `Dictionary.erase(key)` | Remove expired effect |
| `Signal.bind(args...)` | Capture extra arguments per signal connection |
| `Area2D.body_entered` | Fires when a physics body enters the area |
| `Node.get_meta(key)` | Read metadata stored per-node in the scene |
| `Node.has_method(name)` | Duck-type check before calling a method |

## Controls

| Input | Action |
|-------|--------|
| Arrow keys | Move (speed reduced while frozen) |
| Walk into green zone | Apply poison (10 DPS, 5 s) |
| Walk into red zone | Apply burn (22 DPS, 3 s) |
| Walk into blue zone | Apply freeze (0 DPS, 35% speed, 4 s) |

## Key Constants

```gdscript
const SPEED    := 200.0    # base pixels per second
const JUMP_VEL := -400.0   # initial jump velocity
const GRAVITY  := 900.0    # pixels per second squared
const MAX_HP   := 100.0
```

## Effects Reference

| Zone | Effect | DPS | Speed Multiplier | Duration |
|------|--------|-----|-----------------|----------|
| Green | Poison | 10/s | 100% | 5 s |
| Red | Burn | 22/s | 100% | 3 s |
| Blue | Freeze | 0 | 35% | 4 s |

## Files

| File | Purpose |
|------|---------|
| `scripts/status_effect_stack.gd` | **`StatusEffectStack`** — reusable timing/stacking (`apply`/`tick`) |
| `scripts/player.gd` | Effect catalog, movement, visual feedback; owns a `StatusEffectStack` |
| `scripts/main.gd` | Zone setup, meta reads, body_entered connections, world drawing |
| `scenes/main.tscn` | Scene tree with Player, PoisonZone, BurnZone, FreezeZone |

## Related demos

- [knockback](../knockback) — Velocity-based hit recoil that decays exponentially, with i-frames.
- [simple-ai](../simple-ai) — An enemy that always moves directly toward the player.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

