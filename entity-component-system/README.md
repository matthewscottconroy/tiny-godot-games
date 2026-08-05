# Entity Component System

A minimal Godot 4.2 demo showing a pure GDScript ECS: entities as integer IDs, components as data dictionaries, and systems as functions that query and mutate component data.

## How It Works

### Core Types

| Concept | Representation |
|---------|----------------|
| Entity | `int` (unique auto-increment ID) |
| Component | `Dictionary` of data fields |
| World | `ECSWorld` — stores all component tables |
| System | Free function that calls `world.query()` |

### Component Storage

The `ECSWorld` stores a nested dictionary: `type → entity_id → data`. This allows O(1) component access and efficient iteration over all entities with a given type:

```gdscript
_components[&"Position"][entity_id] = {"x": 100.0, "y": 200.0}
```

### Query

`world.query([&"Position", &"Velocity"])` returns all entity IDs that have **every** listed component type. Systems use this to find their relevant entities:

```gdscript
for e in _world.query([&"Position", &"Velocity"]):
    var pos := _world.get_component(e, &"Position")
    var vel := _world.get_component(e, &"Velocity")
    pos["x"] += vel["x"] * delta
```

### Systems in This Demo

| System | Components Used | Behavior |
|--------|-----------------|----------|
| Movement | Position, Velocity | Moves entities, bounces off viewport edges |
| Damage | Health | Slowly drains HP over time |
| Render | Position, Render, Health | Draws circle + HP arc |

### Component Types

Each entity has `Position`, `Velocity`, `Health`, and `Render` components. The arc drawn around each circle shows remaining HP — green when above 50%, red below.

## Project Structure

```
entity-component-system/
├── project.godot
├── icon.svg
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── ecs_world.gd    # ECSWorld: create_entity, add/get/remove component, query
│   └── main.gd         # spawns 12 entities, runs movement + damage + render systems
├── tests/
│   ├── test.tscn
│   └── test_logic.gd
└── README.md
```
