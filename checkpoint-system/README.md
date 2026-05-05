# Checkpoint System

Demonstrates a one-way checkpoint system with respawn using Area2D signals.

## How it works

- Three flag checkpoints are placed on a platformer level.
- Walking through a flag activates it (turns green, glows) and updates the player's respawn point.
- Checkpoints are one-way: once activated they stay active and emit `activated` only once.
- Press **R** to respawn at the most recently activated checkpoint.
- If no checkpoint has been reached, the player respawns at their starting position.

## Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move and jump |
| R | Respawn at last checkpoint |

## Key concepts

- `Area2D.body_entered` detects when the player walks through a flag zone.
- `signal activated(id: int)` is emitted once per checkpoint; `main.gd` connects it via `signal.bind(cp)` to pass the node reference.
- `player.set_checkpoint(pos)` stores the new spawn position offset above the flag base.
- `CharacterBody2D._draw()` and `Area2D._draw()` render all visuals without sprites.

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Connects checkpoint signals, draws terrain |
| `scripts/player.gd` | Movement, jump, respawn, spawn-point storage |
| `scripts/checkpoint.gd` | Flag drawing, one-shot activation signal |
| `scenes/main.tscn` | Full scene: player, 3 checkpoints, floor, 2 platforms |
| `tests/test_logic.gd` | Pure-GDScript unit tests for spawn/respawn logic |
