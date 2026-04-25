# TileMap

Builds a `TileSet` and `TileMap` entirely in code — generating a 3-tile atlas texture, registering physics collision on solid tiles, loading map data from a 2D array, and implementing click-to-paint tile editing.

## Purpose

Most TileMap tutorials configure everything in the Godot editor. This demo shows the programmatic equivalent — which is essential for procedurally generated levels, data-driven map loading (from JSON/CSV), and understanding what the editor stores internally.

## Controls

- **Arrow keys / WASD**: Move the player
- **Left-click on a tile**: Paint a grass tile
- **Right-click on a tile**: Paint a water tile (non-solid)

## How It Works

### Node Tree

```
Main (Node2D)           ← main.gd
├── TileMap
└── Player (CharacterBody2D)
    └── CollisionShape2D
```

### `scripts/main.gd`

- **`_build_tileset()`** — Creates a `TileSet` with `tile_size = Vector2i(32, 32)`. Builds a `TileSetAtlasSource` with a hand-painted 3-tile atlas image (grass, stone, water). Calls `source.create_tile()` for each tile. Adds a physics layer to the TileSet, then calls `TileData.add_collision_polygon()` on the solid tiles (grass, stone).
- **`_load_map()`** — Iterates `MAP_DATA` (a 2D `int` array) and calls `tilemap.set_cell(layer, coord, source_id, atlas_coord)` for each non-zero tile.
- **Click-to-paint** — `_input()` converts mouse position to tile coordinates with `tilemap.local_to_map(tilemap.to_local(pos))` and calls `set_cell()` with the selected tile index.
- **Player physics** — Standard `CharacterBody2D` with `move_and_slide()`. Collides with the tiles because the TileSet has a physics layer with collision polygons assigned.

### TileSet Physics Layers

Physics collision on tiles requires two steps:
1. `tileset.add_physics_layer(0)` — Create a physics layer (index 0).
2. For each solid tile: `tile_data.add_collision_polygon(0)` + `tile_data.set_collision_polygon_points(0, 0, square_verts)`.

The first `0` is the physics layer index (from step 1). The second `0` is the polygon index within that layer. `square_verts` is a `PackedVector2Array` of the tile's corners (in tile-local coordinates, 0 to 32).

### Atlas Source vs Scenes Source

`TileSetAtlasSource` maps grid positions in a texture atlas to individual tiles. Alternative: `TileSetScenesCollectionSource` for tiles that are full scene instances (with scripts). Atlas sources are faster and simpler; scene sources allow per-tile scripted behavior.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `TileSet.tile_size` | Pixel size of each tile |
| `TileSetAtlasSource` | Atlas-based tile source |
| `TileSetAtlasSource.texture_region_size` | Size of one tile in the atlas |
| `TileSetAtlasSource.create_tile(atlas_coord)` | Register a tile at atlas position |
| `TileSetAtlasSource.get_tile_data(coord, alt)` | Get the TileData for a tile |
| `TileData.add_collision_polygon(physics_layer)` | Add a collision shape |
| `TileData.set_collision_polygon_points(layer, polygon, verts)` | Set shape vertices |
| `TileMap.set_cell(layer, coord, source_id, atlas_coord)` | Place a tile |
| `TileMap.local_to_map(local_pos)` | Convert pixel position to tile coordinate |
