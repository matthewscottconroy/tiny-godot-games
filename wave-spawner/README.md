# Wave Spawner

Demonstrates a phase-based wave system with intermission countdowns, difficulty scaling, and click-to-damage enemies — the standard pattern for horde/tower-defense games.

## Purpose

Wave spawning is one of the most common game systems: it appears in tower defense, bullet hells, arena shooters, and survival games. The key design problem is managing state across three phases (waiting, intermission, active wave) without spaghetti conditionals. This demo implements that clearly with a `Phase` enum and a single float timer.

## Controls

- **Start Wave button**: Begin the wave sequence
- **Click enemies**: Deal 1 damage (enemies have 2+ HP)
- Watch: enemies spawn at the edges, move toward center, die when HP reaches 0

## How It Works

### Node Tree

```
Main (Node2D)         ← main.gd
├── WaveLabel
├── StatusLabel
├── EnemyCountLabel
├── Enemies (Node2D)  ← enemy nodes added here
└── HUD (CanvasLayer)
    └── StartButton
```

### Phase State Machine

```gdscript
enum Phase { IDLE, INTERMISSION, WAVE }
```

- **IDLE**: Before the first wave starts. Waits for button press.
- **INTERMISSION**: Countdown timer between waves. Displays "Wave X in N…".
- **WAVE**: Enemies are alive. Transitions to INTERMISSION when all defeated.

### Difficulty Scaling

```
enemy_count = 3 + (wave - 1) * 2   # 3, 5, 7, 9, 11 enemies
enemy_speed = 40 + wave * 12        # 52, 64, 76, 88, 100 px/s
enemy_hp    = 2 + wave              # 3, 4, 5, 6, 7 hits
```

Each wave spawns enemies from random screen edges. The escalation curve keeps early waves easy while later waves require faster clicking.

### Enemy Nodes

Enemies are plain `Node2D` nodes with metadata:
- `hp`: current hit points
- `speed`: movement speed
- `dir`: normalized direction toward center

They're dynamically added to the `Enemies` container and removed via `queue_free()` on death. The `_draw()` signal connection draws each enemy as a colored circle with an HP arc overlay.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Node2D` as data container | Physics-free objects using metadata |
| `node.set_meta(key, value)` | Store per-node gameplay data |
| `node.get_meta(key)` | Read per-node data |
| `node.draw.connect(callable)` | Custom drawing per node |
| `node.queue_redraw()` | Trigger redraw of a specific node |
| `queue_free()` | Safely remove a node at end of frame |
