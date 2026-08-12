# Dungeon Generator

A minimal Godot 4 demo showing procedural dungeon generation via random room placement and L-shaped corridor carving.

## Controls

| Key | Action |
|-----|--------|
| Space | Generate a new dungeon |

## How It Works

### Algorithm

1. **Room Placement** — Attempt to place `NUM_ROOMS` rooms at random positions. Each candidate is rejected if it (grown by 1 cell) intersects any already-placed room, ensuring walls between rooms.
2. **Room Sorting** — Rooms are sorted left-to-right by x position so corridors flow naturally across the map.
3. **Corridor Carving** — Each room connects to the next via an L-shaped corridor: walk horizontally from center A to center B's x, then vertically to center B's y.

```gdscript
var cx := ax
while cx != bx:
    _grid[ay][cx] = Tile.CORRIDOR
    cx += 1 if bx > cx else -1
var cy := ay
while cy != by:
    _grid[cy][bx] = Tile.CORRIDOR
    cy += 1 if by > cy else -1
```

### Tile Types

| Value | Meaning |
|-------|---------|
| `WALL` | Impassable dark cell |
| `FLOOR` | Room interior |
| `CORRIDOR` | Connecting passage |

### Extending It

- **BSP splitting**: Replace random placement with Binary Space Partitioning for more uniform coverage.
- **Minimum spanning tree corridors**: Connect rooms by MST edge weight instead of sequential order to avoid long detour corridors.
- **Extra connections**: Add `rand()` extra edges to create loops rather than a purely linear layout.

## Key Constants

```gdscript
const MAP_W    := 80     # grid columns
const MAP_H    := 56     # grid rows
const CELL     := 8      # pixels per cell
const NUM_ROOMS := 14    # rooms to attempt
const MIN_W    := 5      # minimum room width (cells)
const MAX_W    := 14     # maximum room width
const MIN_H    := 4      # minimum room height
const MAX_H    := 10     # maximum room height
```

## Project Structure

```
dungeon-generator/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd         # room placement + corridor carving + _draw()
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
