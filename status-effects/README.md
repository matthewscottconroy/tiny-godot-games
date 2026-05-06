# Status Effects

Poison, burn, and freeze effects applied by walking into colored floor zones. Each effect is a timed modifier stored in a dictionary; multiple effects can be active simultaneously. Demonstrates a clean, data-driven effect stack pattern.

## Purpose

Status effects appear in virtually every RPG, action game, and roguelike. The naive implementation — a boolean `is_poisoned`, a separate timer, a separate damage routine for each effect — becomes unmanageable as the effect count grows. Adding a fourth effect means adding a fourth boolean, timer, damage function, and rendering case.

The data-driven dictionary approach used here scales to dozens of effects without adding new code paths: adding a new effect means adding one entry to `EFFECT_CFG`. The tick loop, the slow multiplier, and the HUD update all handle it automatically. This is the pattern used in production RPGs where designers need to add new effects without touching gameplay code.

This demo also shows stacking: all active effects run simultaneously, and the most restrictive slow multiplier wins — walking into both a burn zone and a freeze zone applies both damage-per-second values while capping speed at freeze's 35%.

## How It Works

### Data-Driven Config

```gdscript
# scripts/player.gd
const EFFECT_CFG := {
    "poison": {"color": Color(0.20, 0.90, 0.20), "dps": 10.0, "slow": 1.00, "duration": 5.0},
    "burn":   {"color": Color(1.00, 0.30, 0.10), "dps": 22.0, "slow": 1.00, "duration": 3.0},
    "freeze": {"color": Color(0.30, 0.70, 1.00), "dps":  0.0, "slow": 0.35, "duration": 4.0},
}

var _active: Dictionary = {}   # {effect_name: time_remaining}
```

Each effect is fully described by its config entry. `_active` stores only the remaining duration — no per-effect state beyond time.

### Applying Effects

```gdscript
func apply_effect(name: String) -> void:
    _active[name] = EFFECT_CFG[name]["duration"]
```

Re-entering a zone refreshes the duration (overwrites the existing entry). This is the standard "refresh on reapply" behavior. An alternative design would `maxf` the existing and new duration to prevent refresh exploitation.

### Ticking All Active Effects

```gdscript
func _physics_process(delta: float) -> void:
    var slow: float          = 1.0
    var to_remove: Array[String] = []
    for fx in _active.keys():
        _active[fx] -= delta
        var cfg := EFFECT_CFG[fx]
        _hp  -= cfg["dps"] * delta
        slow  = minf(slow, cfg["slow"])
        if _active[fx] <= 0.0:
            to_remove.append(fx)
    for fx in to_remove:
        _active.erase(fx)
    _hp = maxf(_hp, 0.0)
    velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED * slow
```

The `slow` multiplier uses `minf` (takes the minimum) so the most restrictive active effect always wins. Expired effects are collected in `to_remove` and erased after the loop — modifying a dictionary while iterating over it is unsafe.

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
    for fx in _active.keys():
        col = col.lerp(EFFECT_CFG[fx]["color"], 0.65)
    draw_rect(Rect2(-12, -24, 24, 48), col)
```

The player's color blends toward each active effect's color. With both poison and freeze active, the player turns a cyan-green mix, giving intuitive multi-effect feedback.

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
- **UI icons**: Iterate `_active.keys()` in a HUD script and show/hide icon nodes by effect name — the data is already there.

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
| Arrow keys / WASD | Move (speed reduced while frozen) |
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
| `scripts/player.gd` | Effect config, apply/tick/expire logic, movement, visual feedback |
| `scripts/main.gd` | Zone setup, meta reads, body_entered connections, world drawing |
| `scenes/main.tscn` | Scene tree with Player, PoisonZone, BurnZone, FreezeZone |
