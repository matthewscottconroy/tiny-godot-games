# Known gaps

What the collection does not cover yet. Check here before opening a demo
request — and treat anything on this list as fair game to contribute.

The categories with the fewest demos are the honest signal about where the
collection is thin. Right now that is input, data, animation, and editor
tooling; shaders and movement are well covered.

## 2D

**Input**
- Touch gestures — pinch, swipe, long-press
- Gamepad rumble patterns as feedback, not just on/off
- Simultaneous keyboard and gamepad, with the prompt glyphs switching to match

**Data & persistence**
- Binary saves with `FileAccess.store_var`, and when that beats JSON
- Save-file integrity — checksums, and detecting a truncated write
- Cloud-save conflict resolution

**Animation**
- Blend spaces in `AnimationTree` (only the state machine is covered)
- Root motion
- Cutscene sequencing — several actors on a shared timeline

**UI**
- Focus and keyboard/gamepad navigation through a menu — badly under-covered
  everywhere, and the thing that makes a UI usable without a mouse
- Responsive layouts that survive a window resize
- Rich text with clickable `meta` links

**Systems**
- Achievements — conditions, persistence, and notification
- Time-of-day scheduling and simulated NPC routines
- Difficulty scaling that touches several systems at once

**Engine**
- Custom `Resource` importers
- Signals across scene changes without a global bus
- Memory profiling and finding leaked nodes

## 3D — [tiny-godot-3d](../../tiny-godot-3d)

Nearly everything. The seed covers a character controller, an orbit camera, and
procedural mesh building. The most valuable next additions:

- `RigidBody3D` and joints; character-vs-rigid interaction
- Raycast picking and object selection
- `GridMap` level building; CSG blockouts
- `NavigationRegion3D` pathfinding
- Lighting, shadows, environment and fog
- `SpringArm3D` — a camera that actually collides, versus the maths-only rig
- First-person controller with head bob and view-model separation

## Deliberately out of scope

- **C# and GDExtension.** The collection is GDScript so that every demo can be
  read without a build step.
- **Full games.** One concept per demo is the constraint that makes the whole
  thing browsable.
- **Anything needing paid or large assets.** Every demo generates its art in
  code or ships a small SVG, so a clone is fast and nothing has a licence
  question attached.

## How to claim one

Open an issue with the demo-request template saying which you are taking, then
`tools/new-demo.sh <name>`. See [CONTRIBUTING.md](../CONTRIBUTING.md).
