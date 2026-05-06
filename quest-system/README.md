# Quest System

A multi-quest tracker with three distinct objective types — kill enemies, collect items, and reach a location — each with a progress bar, XP reward, and a shared victory condition.

## Purpose

Quest systems are the narrative scaffolding of open-world games, action-RPGs, and even mobile puzzle titles. Their mechanical job is to chunk the player's activity into legible goals with visible progress and clear rewards. The design challenge is keeping quest data separate from world logic: the quest Dictionary doesn't move enemies or coins — it just observes world state and records a count. This decoupling means quest completion logic is testable in isolation and quests can be added or removed without changing any gameplay code.

This demo shows all three fundamental quest objective archetypes: **kill** (count discrete events), **collect** (count persistent world state), and **reach** (proximity trigger). Every quest in any RPG is a variation of one of these, sometimes combined (kill 5 enemies *in zone X* = reach + kill).

## How It Works

### Quest Data Model

```gdscript
{
    "id":            "kill",
    "title":         "Slay the Beasts",
    "description":   "Defeat 5 enemies",
    "type":          "kill",
    "target_count":  5,
    "current_count": 0,    # recomputed each frame from world state
    "completed":     false,
    "reward_xp":     100
}
```

`current_count` is not an accumulator — it is recalculated from scratch every frame in `_update_quest_progress()`. This means quest progress is always consistent with world state even if enemies respawn or coins are reset.

### Progress Recomputation

```gdscript
func _update_quest_progress() -> void:
    # Kill quest: count dead enemies
    var dead_count := 0
    for e in _enemies:
        if not e.alive: dead_count += 1
    kill_quest.current_count = dead_count
    if kill_quest.current_count >= kill_quest.target_count:
        kill_quest.completed = true

    # Collect quest: count collected coins
    var collected_count := 0
    for c in _coins:
        if c.collected: collected_count += 1
    collect_quest.current_count = collected_count
    if collect_quest.current_count >= collect_quest.target_count:
        collect_quest.completed = true

    # Reach quest: distance check
    if _player_pos.distance_to(_beacon_pos) <= BEACON_RANGE:
        reach_quest.current_count = 1
        reach_quest.completed = true
```

Once `completed` is `true` it stays `true` — the check is wrapped in `if not quest.completed`. The full-scan approach here is fine for small counts; for larger worlds, use event signals to increment a counter rather than scanning arrays.

### Victory Condition

```gdscript
_all_complete = true
for quest in _quests:
    if not quest.completed:
        _all_complete = false
        break
```

A single pass over the Array. Adding more quests doesn't change this code.

### Enemy Respawn

When all enemies are dead and the kill quest is still incomplete, `_respawn_enemies()` restores them. This prevents a softlock where the player killed enemies before the quest was active (or overshoot during multi-session play):

```gdscript
var kill_quest = _quests[0]
if not kill_quest.completed:
    var all_dead := _enemies.all(func(e): return not e.alive)
    if all_dead:
        _respawn_enemies()
```

## Quest Objective Design

**Event-driven vs. polling**: This demo polls world state every frame. For larger games, prefer signals: an `enemy_died` signal increments the kill counter directly, avoiding per-frame scanning. Polling is simpler to implement and sufficient when the world population is small.

**Idempotent completion**: Setting `completed = true` and never unsetting it (within a run) means the quest panel never flickers even if the kill count drops (e.g., enemy respawns). For quests that can fail (escort target dies), add a `failed: bool` field and a separate failure condition check.

**Reward delivery**: `reward_xp` is shown in the UI but not yet applied. In a real game, call a `player.gain_xp(quest.reward_xp)` inside the block that transitions `completed` from false to true — check `if quest.current_count >= quest.target_count and not quest.completed` to fire rewards exactly once.

## How to Adapt This in Your Project

- **Quest log / journal**: Store quests in an Autoload so any scene can read them. Emit a `quest_updated(quest_id)` signal whenever `current_count` or `completed` changes; the UI subscribes to redraw only when needed.
- **Sequential quest chains**: Add a `"requires_quest": "kill"` field. Filter the active quest list to only show quests whose `requires_quest` is in the completed set.
- **Time-limited quests**: Add `"time_limit": 60.0` and a `_time_remaining` field. Tick it down in `_process`; if it hits zero before `completed`, set `failed = true`.
- **Branching rewards**: Replace `reward_xp: int` with a `rewards: Array[Dictionary]` that can include items, gold, and ability unlocks, processed through a reward dispatch function.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `Vector2.distance_to(other)` | Proximity check for coin, beacon, and attack range |
| `Input.is_key_pressed(KEY_W)` | Held-key polling for player movement |
| `Array.all(callable)` | Check if every element satisfies a condition |
| `clamp(value, 0.0, 1.0)` | Clamp progress bar fill fraction |
| `draw_rect(rect, color, filled, width)` | Progress bar and card backgrounds |

## Controls

| Input | Action |
|-------|--------|
| WASD | Move the player |
| Left-click | Attack an enemy within 30 px |
| Walk over coin | Automatically collect it (within 15 px) |
| Walk to beacon | Activates reach quest (within 30 px) |

## Key Constants / Data

```gdscript
const ATTACK_RANGE := 30.0   # px — left-click kill radius
const COIN_RANGE   := 15.0   # px — auto-collect radius
const BEACON_RANGE := 30.0   # px — reach-quest trigger radius

# Quest IDs: "kill" (5 enemies), "collect" (3 coins), "reach" (beacon)
# Rewards: kill=100 XP, collect=75 XP, reach=50 XP
```

## Files

| File | Purpose |
|------|---------|
| `scripts/main.gd` | Quest data, progress tracking, world entities, rendering |
| `tests/test_logic.gd` | Unit tests for progress computation and completion gating |
| `scenes/main.tscn` | Scene root (Node2D with script) |
| `tests/test.tscn` | Test runner scene |
