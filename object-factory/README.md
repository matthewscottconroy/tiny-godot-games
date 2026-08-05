# Object Factory

A minimal Godot 4.2 demo showing the factory pattern: a type registry that decouples entity creation from caller code.

## Controls

| Key | Action |
|-----|--------|
| 1 | Spawn Enemy Basic |
| 2 | Spawn Enemy Fast |
| 3 | Spawn Enemy Tank |
| 4 | Spawn Item Coin |
| 5 | Spawn Item Health |
| C | Clear all entities |

## How It Works

### Type Registry

The `EntityFactory` stores a `Dictionary` mapping type names to builder `Callable`s. Registration and creation are decoupled:

```gdscript
# Registration (happens once at startup)
factory.register(&"enemy_tank", func(_p):
    return {"type": "enemy_tank", "hp": 10, "speed": 40.0, "radius": 22.0})

# Creation (can happen anywhere, with no knowledge of the builder)
var e := factory.create(&"enemy_tank")
```

### Benefits

- **Open/Closed**: add new entity types without modifying the factory or caller code
- **Parameterizable**: pass a `params` dict to builders for runtime configuration
- **Self-describing**: `registered_types()` returns all known types for UIs, editors, or AI

### Entity Data Format

Each entity is a plain `Dictionary`. No base class, no inheritance. Fields are type-specific — callers use `.get(key, default)` for optional fields.

## Project Structure

```
object-factory/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── factory.gd      # EntityFactory class with register/create/query
│   └── main.gd         # registers 5 types, spawns on keypress, draws with _draw()
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
