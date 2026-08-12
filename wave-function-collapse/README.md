# Wave Function Collapse

A minimal Godot 4 demo implementing the Wave Function Collapse algorithm: constraint-propagation tile placement that generates locally consistent maps.

## Purpose

Wave function collapse generates layouts that are locally consistent everywhere, which is why it suits tilesets with strict adjacency rules. The loop is: pick the least-certain cell, collapse it to one option, then propagate that choice to its neighbours until nothing changes. This demo shows entropy selection, collapse, and propagation — including what a contradiction looks like.

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

## Files

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

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Array` of per-cell option masks | The superposition each cell collapses from |
| Adjacency rule table | Which tiles may neighbour which |
| Entropy (fewest remaining options) | Pick the next cell to collapse |
| Queue-driven propagation | Push constraint changes outward until stable |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- No project settings, autoloads, or input actions are required.

