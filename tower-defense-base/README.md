# Tower Defense Base

A minimal Godot 4.2 demo showing the core tower defense loop: path enemies, tower placement, projectile targeting, gold economy, and wave scaling.

## Controls

| Input | Action |
|-------|--------|
| LMB on empty tile | Build a tower (costs 50 gold) |

## How It Works

### Grid and Path

The 16×12 grid (40px/cell = 640×480) has a pre-defined path that snakes across the map. Path tiles are marked `1` in `_grid`, preventing tower placement. The path is stored as `Vector2i` grid coordinates converted to world-space waypoints on startup.

### Tower Targeting

Each tower selects the enemy furthest along the path within its range:

```gdscript
if tpos.distance_to(e["pos"]) <= TOWER_RANGE and e["idx"] > best_idx:
    best_idx = e["idx"]
    best = e
```

This prioritizes enemies closest to the exit rather than closest to the tower — a common TD design choice.

### Enemy Movement

Enemies follow the path waypoint-by-waypoint. When close enough to the current target waypoint, they advance to the next index:

```gdscript
e["pos"] += direction * ENEMY_SPEED * delta
if e["pos"].distance_to(target) < 2.0:
    e["idx"] += 1
```

### Wave Scaling

Each successive wave spawns more enemies with higher HP:

```gdscript
_wave_size = 6 + (_wave - 1) * 2   # wave 1: 6, wave 2: 8, …
enemy_hp   = 3 + (_wave - 1)        # wave 1: 3 HP, wave 2: 4 HP, …
```

Killing an enemy rewards `ENEMY_REWARD` gold for more towers.

## Key Constants

```gdscript
const TOWER_COST  := 50      # gold to build one tower
const TOWER_RANGE := 100.0   # attack radius (px)
const FIRE_RATE   := 1.5     # shots per second
const ENEMY_SPEED := 80.0    # path travel speed (px/s)
const START_GOLD  := 150     # initial gold (buy 3 towers)
const START_LIVES := 10      # lives before game over
```

## Project Structure

```
tower-defense-base/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd         # grid, path, towers, enemies, bullets, wave system, HUD
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
