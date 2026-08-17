# TileMap

Builds a `TileSet` and `TileMapLayer` entirely in GDScript — generating a 3-tile atlas texture at runtime, registering physics collision on solid tiles, loading map data from a 2D array, and implementing keyboard tile-painting.

> **Godot 4.3+ note:** this demo uses `TileMapLayer`, the node that replaced the now-deprecated `TileMap`. Each `TileMapLayer` is a *single* layer, so `set_cell()` / `erase_cell()` no longer take a leading layer-index argument, and multiple layers are modelled as multiple `TileMapLayer` nodes rather than layers inside one `TileMap`.

## Purpose

Most TileMap tutorials configure everything in the Godot editor and leave developers unclear about what the engine actually stores internally. Understanding the programmatic API is essential for procedurally generated levels, data-driven map loading from JSON or CSV, and runtime tile modification during gameplay. Games like Terraria, Stardew Valley, and Celeste all manipulate tile data at runtime — understanding the underlying model is a prerequisite.

The programmatic API also reveals the exact mental model Godot uses: a `TileSet` is a database of tile definitions (textures, physics, terrain), while a `TileMapLayer` is a layer of coordinate-to-tile-ID mappings. The two are separate objects by design — one `TileSet` can serve multiple `TileMapLayer` instances with different layouts.

Physics collision on tiles requires explicitly authoring collision polygons per tile-type in the TileSet. This demo shows the complete flow from texture generation to player standing on solid tiles.

## How It Works

### Node Tree

```
Main (Node2D)           ← main.gd
├── TileMapLayer
└── Player (CharacterBody2D)
    └── CollisionShape2D
```

### Building the TileSet (`_build_tileset()`)

A single 96×32 atlas image is created in code — three 32×32 tiles side by side (grass, stone, water), each drawn as a solid color with a darkened border:

```gdscript
var img := Image.create(TILE_SIZE * 3, TILE_SIZE, false, Image.FORMAT_RGB8)
for ti in 3:
    var col := colors[ti]
    for y in TILE_SIZE:
        for x in TILE_SIZE:
            var border := x == 0 or y == 0 or x == TILE_SIZE-1 or y == TILE_SIZE-1
            img.set_pixel(ti * TILE_SIZE + x, y, col.darkened(0.2) if border else col)
source.texture = ImageTexture.create_from_image(img)
```

Three tiles are registered at atlas positions `(0,0)`, `(1,0)`, `(2,0)`:

```gdscript
for ax in 3:
    source.create_tile(Vector2i(ax, 0))
```

### Adding Physics Collision

Physics on tiles requires a two-step setup:

```gdscript
# Step 1: add a physics layer to the TileSet (like a collision layer slot)
tileset.add_physics_layer(0)

# Step 2: for each solid tile, add a collision polygon
var sq := PackedVector2Array([Vector2(-16,-16), Vector2(16,-16),
                              Vector2(16,16),  Vector2(-16,16)])
for ax in [0, 1]:  # grass (0) and stone (1) are solid; water (2) is not
    var td := source.get_tile_data(Vector2i(ax, 0), 0)
    td.add_collision_polygon(0)
    td.set_collision_polygon_points(0, 0, sq)
```

The first `0` in `set_collision_polygon_points` is the physics layer index; the second `0` is the polygon index within that layer. Coordinates are tile-local (centered at tile origin, ±16 for a 32px tile).

### Loading the Map (`_load_map()`)

The hardcoded `MAP_DATA` 2D array encodes tile IDs as integers:

```gdscript
const MAP_DATA := [
    [0,0,0,0,1,1,1,1,0,0,...],  # 1=grass, 2=stone, 3=water, 0=empty
    ...
    [1,1,1,1,1,1,1,1,1,1,...],  # solid ground row
]

func _load_map() -> void:
    for row in MAP_DATA.size():
        for col in MAP_DATA[row].size():
            var t := MAP_DATA[row][col]
            if t > 0:
                tilemap.set_cell(Vector2i(col, row), 0, Vector2i(t - 1, 0))
```

`set_cell(coord, source_id, atlas_coord)` — `source_id` `0` is the atlas source added via `add_source(source, 0)`, and `atlas_coord` is the tile's position in the atlas image. (On the old `TileMap` node this method took a leading layer-index argument; `TileMapLayer` is a single layer, so it's gone.)

### Tile Painting

Keyboard keys 1–4 select the active paint tile. Left-click paints, right-click erases:

```gdscript
var cell := tilemap.local_to_map(tilemap.to_local(event.position))
if event.button_index == MOUSE_BUTTON_LEFT:
    if _paint_tile > 0:
        tilemap.set_cell(cell, 0, Vector2i(_paint_tile - 1, 0))
    else:
        tilemap.erase_cell(cell)
```

`local_to_map` converts a pixel position (in layer-local space) to a tile coordinate. `to_local` converts from global viewport position to the `TileMapLayer`'s local space.

### Player Physics

The player is a `CharacterBody2D` with a `CapsuleShape2D`. Gravity and jumping follow the standard pattern:

```gdscript
if not player.is_on_floor():
    player.velocity.y += 900.0 * delta
if player.is_on_floor() and Input.is_action_just_pressed("ui_up"):
    player.velocity.y = -420.0
player.velocity.x = Input.get_axis("ui_left", "ui_right") * 180.0
player.move_and_slide()
```

The player collides with grass and stone tiles (physics layer 0 with polygon) but passes through water tiles (no collision polygon assigned).

## TileSet Architecture

| Concept | What it is |
|---------|-----------|
| `TileSet` | Database of tile definitions: textures, physics, terrain, custom data |
| `TileSetAtlasSource` | Tile source backed by an atlas texture — maps grid positions to tiles |
| `TileSetScenesCollectionSource` | Alternative: tiles are full scene instances (for scripted per-tile behavior) |
| `TileData` | Per-tile properties: collision polygons, terrain info, custom data layers |
| `TileMapLayer` | A single grid layer of tile placements referencing a TileSet (replaces the deprecated `TileMap`) |

`TileSetAtlasSource` is the right choice for most tilemaps — fast, memory-efficient, and the editor's tile painter uses it natively. Use `TileSetScenesCollectionSource` only when individual tiles need scripts (e.g. animated traps, interactive switches).

## How to Adapt This in Your Project

- **Load from JSON/CSV**: replace `MAP_DATA` with a parsed file. Map integer IDs to atlas coords with a `Dictionary`.
- **Multiple layers**: add a second `TileMapLayer` node (e.g., decoration above solid tiles) — each node is one layer and can share the same `TileSet`. Order is set by tree/`z_index`.
- **Runtime destruction**: call `tilemap.erase_cell(coord)` to remove a tile. Since the TileSet physics layer is per-tile-type, removal automatically removes its collision.
- **Autotiling / terrain**: use `TileSet`'s terrain system (`set_cells_terrain_connect`) to auto-select tile variants based on neighbors — eliminates manual tile variant selection.
- **Chunk loading**: store chunks as `Dictionary[Vector2i, int]` and call `set_cell` only for visible chunks. Call `erase_cell` when chunks unload.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `TileSet.tile_size` | Pixel dimensions of each tile |
| `TileSetAtlasSource` | Atlas-backed tile source |
| `TileSetAtlasSource.texture_region_size` | Pixel size of one tile in the atlas |
| `TileSetAtlasSource.create_tile(atlas_coord)` | Register a tile at an atlas position |
| `TileSetAtlasSource.get_tile_data(coord, alt)` | Get the `TileData` object for a tile |
| `TileSet.add_physics_layer(idx)` | Create a physics layer slot on the TileSet |
| `TileData.add_collision_polygon(layer)` | Attach a collision polygon to a tile |
| `TileData.set_collision_polygon_points(layer, poly, verts)` | Define shape vertices |
| `TileMapLayer.set_cell(coord, source_id, atlas_coord)` | Place a tile |
| `TileMapLayer.erase_cell(coord)` | Remove a tile |
| `TileMapLayer.local_to_map(local_pos)` | Convert pixel position to tile coordinate |
| `ImageTexture.create_from_image(img)` | Upload a procedural image as a GPU texture |

## Controls

| Input | Action |
|-------|--------|
| **Arrow keys** | Move player |
| **Up** | Jump |
| **1** | Select grass tile |
| **2** | Select stone tile |
| **3** | Select water tile |
| **4** | Select eraser |
| **Left-click** | Paint selected tile |
| **Right-click** | Erase tile |

## Key Constants

```gdscript
const TILE_SIZE := 32  # pixels per tile (width and height)

# MAP_DATA values:
# 0 = empty, 1 = grass (solid), 2 = stone (solid), 3 = water (non-solid)
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | TileSet construction, map loading, player physics, tile painting |
| `scenes/main.tscn` | Root scene with TileMapLayer and Player nodes |

## Use as a building block

**Copy:** `scripts/main.gd`. Everything happens in one file, and it is a worked example of an engine feature rather than a drop-in component — so the useful move is to lift the technique (the specific calls, and the order they happen in) into your own node rather than to copy the file wholesale.

**Notes**
- Input uses the built-in `ui_*` actions so the demo needs zero setup. Godot binds those to the arrow keys and Enter/Space only; in a real project define your own actions (`move_left`, `jump`, …) and swap them in.

## Related demos

- [animated-sprite](../animated-sprite) — A sprite sheet generated entirely in code — no image files or imports.
- [light-shadow](../light-shadow) — `PointLight2D` with a procedural radial gradient and `CanvasModulate`.
- [palette-swap](../palette-swap) — A shader replacing source colors with destination colors by RGB distance.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

