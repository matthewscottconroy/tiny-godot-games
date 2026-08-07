# Hitbox / Hurtbox

Demonstrates the hitbox/hurtbox pattern: a combat system where attack collision (hitbox) is separate from the vulnerable area (hurtbox), enabling precise frame-by-frame control over when damage can be dealt or received.

## Purpose

Virtually every action game uses the hitbox/hurtbox distinction. A **hitbox** is the region an attack occupies — active only during the attack animation. A **hurtbox** is the vulnerable region of a character — usually always active. Separating them enables:
- Attacks that don't damage the attacker
- Invincibility frames (disable hurtbox temporarily)
- Parry windows (disable hurtbox, enable the parry hitbox)
- Visual attack indicators

## Controls

- **Arrow keys / WASD**: Move the player (blue)
- **Space / Enter** (`ui_accept`): Player attacks (hitbox activates briefly on the right side)
- The red enemy auto-attacks every 2.2 seconds
- Watch both characters flash red when hit

## How It Works

### Node Tree

```
Main (Node2D)
├── Player (CharacterBody2D)  ← player.gd
│   ├── Hitbox (Area2D)       (right side of player — only active during attack)
│   ├── Hurtbox (Area2D)      (player's vulnerable area — always active)
│   ├── HealthLabel (Label)
│   └── CollisionShape2D
└── Enemy (CharacterBody2D)   ← enemy.gd
    ├── Hitbox (Area2D)       (left side of enemy — activates every 2.2s)
    ├── Hurtbox (Area2D)
    ├── HealthLabel (Label)
    └── CollisionShape2D
```

### Collision Layer Architecture

| Layer | Contents |
|---|---|
| 1 | World/walls (unused in this demo) |
| 2 | Character bodies (Player, Enemy) |
| 3 | Hitboxes (active during attacks) |
| 4 | Hurtboxes (always active) |

Hitboxes are on layer 3, with mask set to layer 4 (they detect hurtboxes). Hurtboxes are on layer 4, with mask set to layer 3 (they are detected by hitboxes). This prevents hitboxes from triggering other hitboxes and hurtboxes from triggering other hurtboxes.

### `scripts/player.gd`

**Setup:**
```gdscript
func _ready() -> void:
    $Hurtbox.add_to_group("hurtbox")
    hitbox.monitoring = false    # starts inactive
    hitbox.area_entered.connect(_on_hitbox_area_entered)
    $Hurtbox.area_entered.connect(_on_hurtbox_area_entered)
```

`hitbox.monitoring = false` means the hitbox is invisible to the physics system until explicitly activated. Setting `monitoring = true` "turns on" the attack.

**Attack:**
```gdscript
func _attack() -> void:
    hitbox.monitoring = true
    attack_cooldown = 0.6
    get_tree().create_timer(0.15).timeout.connect(func(): hitbox.monitoring = false; queue_redraw())
```

The hitbox is active for exactly 0.15 seconds (9 frames at 60 fps). After that timer fires, it turns off. This is the **active hitbox window** — a concept from fighting games where an attack only deals damage during a specific frame range.

**Hit detection:**
```gdscript
func _on_hitbox_area_entered(area: Area2D) -> void:
    if area.is_in_group("hurtbox"):
        area.get_parent().take_damage(1)
```

When the player's hitbox overlaps an area in the `"hurtbox"` group, it calls `take_damage()` on the hurtbox's parent (the enemy). Using a group check prevents the hitbox from accidentally damaging invalid area types.

### `scripts/enemy.gd`

The enemy follows the same pattern but auto-attacks on a timer (`ATTACK_INTERVAL = 2.2` seconds). `_draw()` shows a semi-transparent orange rectangle when the hitbox is active, making the attack window visible.

### `take_damage(amount)`

```gdscript
func take_damage(amount: int) -> void:
    health -= amount
    health_label.text = "❤ %d" % max(health, 0)
    modulate = Color.RED
    get_tree().create_timer(0.1).timeout.connect(func(): modulate = Color.WHITE)
    if health <= 0:
        health_label.text = "Enemy KO!"
```

The flash (modulate → RED → WHITE) gives hit confirmation feedback. `modulate` multiplies over all of the node's rendered pixels — a quick, zero-cost hit effect.

## Hitbox/Hurtbox Theory

### Why Not Use the Character's Main Collision Shape?

If attacks were detected by the character's `CollisionShape2D`, every frame of contact would trigger damage. A sword swing that takes 10 frames would deal 10 hits. Hitboxes are separate, independently controllable `Area2D` nodes that you activate and deactivate precisely.

### Monitoring vs Monitorable

- `monitoring = true` — This area actively detects overlaps with other areas/bodies
- `monitorable = true` — Other areas can detect overlaps with this area

A hurtbox should be `monitorable = true` (attackers detect it) but not necessarily `monitoring = true` (it doesn't need to detect others). A hitbox should be `monitoring = true` (it detects hurtboxes) but setting `monitorable = false` prevents other hitboxes from detecting it, avoiding mutual hits.

### Group-Based Filtering

Using `is_in_group("hurtbox")` in the `area_entered` handler is more flexible than checking `area.get_parent() == $Enemy` (which hardcodes a specific target). Any hurtbox from any enemy — including ones not yet in the scene — will correctly receive the damage call.

### Invincibility Frames (I-frames)

To add I-frames after being hit:
```gdscript
func take_damage(amount: int) -> void:
    $Hurtbox.monitorable = false   # temporarily immune
    health -= amount
    await get_tree().create_timer(0.5).timeout
    $Hurtbox.monitorable = true    # vulnerable again
```

## Use as a building block

This demo is kept as **direct, scene-authored `Area2D` nodes** rather than
extracted into `HitBox` / `HurtBox` classes — on purpose. The lesson here *is*
the collision-layer wiring (`Bodies=2`, `Hitboxes=4`, `Hurtboxes=8`) and the
`monitoring` / `monitorable` flags, and those are clearest read straight off the
scene. A wrapper would hide exactly what the demo is teaching, and a mis-set
layer or flag fails silently (no hits register).

When you're ready to package it for reuse, promote the two areas to typed nodes:

```gdscript
# hurt_box.gd
class_name HurtBox
extends Area2D                 # scene sets it to the Hurtbox layer
signal took_hit(damage: int)

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
    if area is HitBox:
        took_hit.emit(area.damage)
```

```gdscript
# hit_box.gd
class_name HitBox
extends Area2D                 # scene sets it to the Hitbox layer
@export var damage := 1        # active only while `monitoring` is true
```

The owner then connects `$HurtBox.took_hit` to its own `take_damage()` — the
same flow this demo wires by hand, but reusable and type-checked. Keep the
**layer assignments in the scene** either way; that separation is the actual
pattern.

**Notes**
- Keep bodies, hitboxes, and hurtboxes on separate layers so world collision never interferes with hit detection.
- `class_name HitBox` / `HurtBox` are global — rename if they collide.
- Demo input uses the built-in `ui_*` actions; define your own in a real project.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Area2D.monitoring` | Whether this area detects overlaps |
| `Area2D.monitorable` | Whether other areas detect this one |
| `Area2D.area_entered` | Signal — another Area2D overlapped |
| `CollisionObject2D.collision_layer` | Physics layers this body belongs to |
| `CollisionObject2D.collision_mask` | Layers this body detects |
| `add_to_group(name)` | Tag nodes for group-based filtering |
| `Node.modulate` | Color multiplier for hit flash |
