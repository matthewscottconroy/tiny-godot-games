# Cellular Automata

A minimal Godot 4 demo implementing a falling-sand simulation: sand, water, and stone with simple per-cell update rules.

## Controls

| Input | Action |
|-------|--------|
| LMB drag | Paint selected material |
| RMB drag | Erase (paint empty) |
| 1 | Select Sand |
| 2 | Select Water |
| 3 | Select Stone |
| C | Clear the grid |

## How It Works

### Update Order

The grid is processed **bottom-to-top** each frame. This ensures a particle can only fall into already-processed cells below it — preventing double-movement.

The horizontal scan direction alternates each frame to avoid directional bias in diagonal slides.

### Sand Rules

```gdscript
if below is EMPTY:        move down
elif lower-left is EMPTY: move to lower-left
elif lower-right is EMPTY: move to lower-right
```

When both diagonals are free, one is chosen randomly, giving natural pile shapes.

### Water Rules

```gdscript
if below is EMPTY:    fall down
elif left is EMPTY:   flow left
elif right is EMPTY:  flow right
```

Water spreads horizontally before settling, simulating a liquid.

### Stone

Stone is immovable — the update function returns early for it. It acts as a permanent barrier.

## Key Constants

```gdscript
const GRID_W := 80    # columns (80 × 8 = 640px)
const GRID_H := 60    # rows    (60 × 8 = 480px)
const CELL   := 8     # pixels per cell
```

## Project Structure

```
cellular-automata/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd         # grid state + per-cell rules + _draw()
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
