# Wave Function Collapse

A minimal Godot 4.2 demo implementing the Wave Function Collapse algorithm: constraint-propagation tile placement that generates locally consistent maps.

## Controls

| Key | Action |
|-----|--------|
| Space | Generate a new map |

## Tile Types

| Tile | Color | Allowed Neighbors |
|------|-------|-------------------|
| Deep water | Dark blue | Deep, Shallow |
| Shallow water | Light blue | Deep, Shallow, Sand |
| Sand | Yellow | Shallow, Sand, Grass |
| Grass | Green | Sand, Grass |

Rules are symmetric — if A can border B, then B can border A.

## How It Works

### 1. Initialization

Every cell starts with all 4 tiles possible (entropy = 4).

### 2. Minimum Entropy Heuristic

The cell with the fewest remaining possibilities is chosen for collapse. Ties broken randomly. This tends to prevent contradictions.

### 3. Weighted Collapse

The chosen cell is assigned one of its remaining tiles using weighted random selection (Grass is most common, Deep is least), simulating natural terrain distributions.

### 4. Constraint Propagation

After a cell collapses, each neighbor's possibilities are filtered: any tile that can't be adjacent to any of the collapsed cell's possibilities is removed. If a neighbor's possibilities change, its neighbors are queued for re-evaluation. Propagation continues until the queue empties.

### 5. Contradiction Recovery

If any cell's possibilities reach 0, the attempt fails and the algorithm restarts from scratch (up to 100 attempts).

## Key Constants

```gdscript
const GRID_W    := 40    # columns (40 × 16 = 640px)
const GRID_H    := 30    # rows    (30 × 16 = 480px)
const NUM_TILES := 4
const WEIGHTS   := [1.0, 2.0, 2.0, 3.0]  # Deep, Shallow, Sand, Grass
```

## Project Structure

```
wave-function-collapse/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd         # WFC algorithm + constraint propagation + _draw()
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
