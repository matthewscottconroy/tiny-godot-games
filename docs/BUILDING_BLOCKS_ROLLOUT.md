# Building-Block Rollout Plan

Goal: make each demo more useful as a **drop-in building block** for real projects, **without** sacrificing its value as a discrete, self-contained teaching unit. No shared library — improvements are applied per-demo so each folder stays copy-and-go.

Status: **Phase 0 pilot complete**; **Phase 1 in progress**.
- ✅ Pilot: `object-pool`, `steering-behaviors`, `state-machine`
- ✅ Category 1 — Data & Architecture: `data-tables`, `save-load`, `config-file` (docs-only), `object-factory`, `entity-component-system`
- ✅ Category 2 — Combat & Abilities: `health-bar` (→ `Health`), `knockback` (→ `Knockback`), `status-effects` (→ `StatusEffectStack`), `input-buffer` (→ `InputBuffer`), `hitbox-hurtbox` (docs-only)
- ✅ Category 3 — Enemy AI: `vision-cone` (→ `VisionCone`), `line-of-sight` (→ `LineOfSight`), `patrol-ai` (package), `homing-projectile` (→ `HomingProjectile`), `simple-ai` (docs-only)
- ✅ Category 4 — Game Systems (RPG core): `crafting-system` (→ `CraftingSystem`), `experience-leveling` (→ `LevelSystem`), `inventory` (→ `Inventory`), `quest-system` (→ `QuestSystem`), `drop-table` (docs-only)
- ✅ Category 5 — Content & flow: `wave-spawner` (→ `WaveSpawner`), `dialogue-tree` (→ `DialogueTree`), `skill-tree` (→ `SkillTree`), `dialogue-box` (package), `notification-queue` (package)
- **Tier A: 28 of ~40 done.** Remaining: spatial/algorithms (`quadtree`, `boid-flocking`, `grid-pathfinding`, `pathfinding-astar`, `dungeon-generator`, `wave-function-collapse`), UI/feel (`tooltip`, `floating-text`, `trail-effect`, `screen-shake`), systems (`ability-system`, `combo-system`, `checkpoint-system`, `interaction-system`, `stamina-system`, `behavior-tree`, `state-machine-hfsm`).
- ✅ Docs: the `Godot 4.2 → Godot 4` prose fix is done across all 24 affected READMEs.
- ⏳ Then Phase 2 (Tier B) and Phase 3 (remaining docs)

## Guiding principle (overrides the tiering)

**An example must first stand on its own as a readable illustration of one feature.** If turning a demo into a reusable component would make the file harder to read for learning, stop at packaging (`class_name`/`@export`/signal/doc) or docs-only — do **not** split or genericize. Readability wins ties.

Pilot evidence of this rule: `state-machine` was slated as Tier A "split," but its whole lesson is a *derived FSM read top-to-bottom in one file*. It was **kept as one file** and only packaged (`@export` tuning + `state_changed` signal + reuse doc). `object-pool` and `steering-behaviors` took genuine clean splits because their mechanism (a generic pool, framework-agnostic steering math) is separable without hurting clarity.

---

## The four levers

1. **Split** — move the reusable mechanism out of the god-script into its own `scripts/<mechanism>.gd`; leave `main.gd` as a thin demo driver (spawns the component, wires labels/`_draw`/input). Only where the mechanism is currently fused into one file.
2. **`class_name`** — give the reusable type a descriptive global name so adopters reference the type instead of a `preload` path.
3. **`@export`** — promote tuning `const`s (speeds, sizes, cooldowns, capacities, colors, counts) to `@export` with today's values as defaults. Keep structural/mathematical constants as `const`.
4. **Reuse doc** — a standardized README section: *files to copy · public API & signals · required project settings (autoloads, input actions) · integration notes.*

## Tiers

- **Tier A — Componentize** (~40): the mechanism *is* a reusable system/algorithm. All four levers.
- **Tier B — Package** (no structural split needed): already isolated or single cohesive script → `class_name` + `@export` + reuse doc.
- **Tier C — Docs-only**: engine-feature showcases, scene/shader-coupled effects, and intentionally-tiny concept demos where componentizing would *hurt* clarity. Reuse doc + input/global-deps note only.

---

## Conventions (apply everywhere)

- **`class_name` collisions:** `class_name` is global in Godot. Use descriptive, project-agnostic names; the reuse doc must warn "rename if your project already defines this." Avoid shadowing engine types (e.g. use `GridPathfinder`, **not** `AStarGrid` — Godot ships `AStarGrid2D`).
- **`@export` vs `const`:** export what an adopter would reasonably tune; leave invariants (`enum` values, atlas math, physics-layer indices) as `const`.
- **Split policy:** the reusable script must not reference demo-only nodes (labels, hint text). Communication goes demo → component via method/`@export`, component → demo via **signal**.
- **Input:** every demo uses built-in `ui_*` actions. Add a standard reuse-doc line: *"Uses `ui_*` for zero-setup; in a real project define named actions (`move_left`, `jump`, …) and swap them."* Do **not** add `[input]` maps (keeps demos zero-config).
- **Globals:** the 3 autoload demos (`EventBus`, `ScoreManager`, `Transition`) get a doc note: how to register + rename to avoid collisions.
- **Tests:** once a demo has a `class_name`, its suite must drive that type rather than replicate the logic inline. Inline copies stayed green while the real scripts failed to parse, which is exactly the failure componentization is supposed to make impossible. `./run-tests.sh` also boots each demo's real main scene as a smoke check, so a split that breaks the scene fails immediately.

---

## Tier A — Componentize (~40)

`class_name` marked ✓ already exists; otherwise proposed name is given. "Split" = mechanism currently fused into `main.gd`/single script.

| Demo | Proposed `class_name` | Split? | Notable `@export` |
|------|----------------------|--------|-------------------|
| object-pool | `ObjectPool` | yes | pool size, scene |
| quadtree | `QuadTree` (+ ✓`QTNode`) | yes | node capacity, bounds |
| boid-flocking | `Boid`, `Flock` | yes | sep/align/cohesion weights, radius |
| steering-behaviors | `SteeringAgent` | yes | max speed/force, wander |
| grid-pathfinding | `GridPathfinder` | yes | grid size, diagonal toggle |
| pathfinding-astar | `AStarPathfinder` | yes | grid size, heuristic |
| behavior-tree | ✓`BTNode` (+ `BehaviorTree`) | no | — |
| state-machine | `StateMachine` | yes | walk threshold |
| state-machine-hfsm | ✓`HFSMState` (+ `HFSM`) | no | — |
| object-factory | ✓`EntityFactory` | no | — |
| entity-component-system | ✓`ECSWorld` | no | — |
| ability-system | `AbilitySystem`, `Ability` | yes | costs, cooldowns, regen |
| combo-system | ✓`ComboSystem` | no | input window |
| status-effects | `StatusEffectStack`, `StatusEffect` | yes | durations |
| health-bar | `Health` (+ `HealthBar`) | yes | max hp, flash color |
| hitbox-hurtbox | `HitBox`, `HurtBox` | yes | damage, knockback |
| knockback | `Knockback` | yes | force, decay |
| input-buffer | `InputBuffer` | yes | buffer window |
| checkpoint-system | ✓`Checkpoint` (+ manager) | no | — |
| interaction-system | ✓`Interactable` | no | prompt text, radius |
| notification-queue | `NotificationQueue` | yes | hold time, slide speed |
| tooltip | `Tooltip` | yes | delay, colors |
| floating-text | ✓`FloatingText` | no | rise dist, lifetime |
| trail-effect | `Trail` | yes | length, gradient |
| screen-shake | `CameraShake` | yes | trauma, decay, max offset |
| save-load | `SaveSystem` | yes | save path |
| config-file | `GameSettings` | yes | defaults |
| data-tables | ✓`ItemDB`, ✓`ItemData` | no | — |
| inventory | `Inventory` | yes | slot count |
| crafting-system | `CraftingSystem`, `Recipe` | yes | — |
| drop-table | ✓`DropTable` | no | — |
| quest-system | `QuestSystem`, `Quest` | yes | — |
| dialogue-box | `DialogueBox` | yes | char speed |
| dialogue-tree | `DialogueTree` | yes | — |
| skill-tree | `SkillTree`, `Skill` | yes | — |
| experience-leveling | `LevelSystem` | yes | curve exponent, base xp |
| wave-spawner | `WaveSpawner` | yes | wave scaling, intermission |
| stamina-system | `Stamina` | yes | max, drain, regen, delay |
| dungeon-generator | `DungeonGenerator` | yes | room count, size range |
| wave-function-collapse | `WaveFunctionCollapse` | yes | grid size |

## Tier B — Package (`class_name` + `@export` + reuse doc; no split)

Movement/controllers: `platformer-controller`, `coyote-time`, `double-jump`, `variable-jump-height`, `wall-jump`, `wall-slide`, `ledge-grab`, `ledge-hang`, `dash-ability`, `grapple-hook`, `grid-movement`, `top-down-controller`, `moving-platforms`, `pushable-blocks`
Cameras: `camera-follow`, `camera-deadzone`, `camera-zoom`, `camera-rooms`
AI: `patrol-ai`, `simple-ai`, `line-of-sight`, `vision-cone`, `homing-projectile`, `path-follow`, `bezier-path`
Combat: `cooldown-shoot`, `spread-shot`
Physics: `rope-physics`, `verlet-integration`, `explosion-force`, `portal`, `destructibles`
UI: `radial-menu`, `context-menu`, `circle-buttons`, `drag-drop`, `virtual-joystick`, `pause-menu`, `settings-menu`, `debug-overlay`
Systems/patterns: `event-bus`, `typed-event-bus`, `scene-transition`, `custom-resource`
Input: `gamepad-input`, `input-remapping`
Procedural: `l-system`, `marching-squares`
Audio: `footstep-audio`
Effects: `trail-effect` (if not promoted), `screen-flash`, `particle-effects`

## Tier C — Docs-only (reuse note + input/global deps)

Concept/teaching micro-demos: `export-vars`, `signal-relay`, `groups`, `area-trigger`, `scene-instancing`, `autoload-score`, `arrow-sprite`, `coin-collector`, `undo-redo`, `localization`, `http-request`, `lock-picking`, `rhythm-minigame`, `tower-defense-base`, `local-multiplayer`, `minimap`, `split-screen`, `subviewport`, `pixel-art-camera`
Engine-feature showcases: `bouncing-ball`, `rigid-body`, `joint-physics`, `buoyancy`, `magnet`, `navigation-agent`, `raycasting`, `thread-loading`, `visible-notifier`, `line-drawing`, `polygon-clip`, `multiline-text`, `canvas-layer`, `tilemap`, `tilemap-room`, `parallax-scroll`
Animation: `animated-sprite`, `animated-walk`, `animation-tree`, `procedural-animation`, `tween-juice`
Audio synthesis: `audio-demo`, `audio-bus-effects`, `audio-positional`, `procedural-sfx`, `dynamic-music`, `music-sequencer`
Shaders/visual (scene-coupled): `2d-water`, `2d-lighting`, `light-shadow`, `day-night-cycle`, `dissolve-effect`, `palette-swap`, `palette-cycling`, `sprite-outline`, `normal-map-lighting`, `gpu-particles-custom`, `post-processing-stack`, `screen-distortion`, `screen-warp`, `shader-effects`, `shader-intro`, `wind-effect`
Procedural showcases: `procedural-gen`, `noise-terrain`, `cellular-automata`

---

## Sequencing

- **Phase 0 — Pilot (3 demos):** `object-pool`, `state-machine`, `steering-behaviors`. Establish the exact split layout, `class_name`/`@export` conventions, and the reuse-doc template. **Review gate before Phase 1.**
- **Phase 1 — Tier A** by category (systems → combat → AI → game-systems → procedural). ~40 demos.
- **Phase 2 — Tier B** packaging pass.
- **Phase 3 — Docs pass:** add the standardized "Use as a building block" section + input/global notes to every demo still missing it (~74), including all of Tier C.

Each phase ends with `./run-tests.sh` (once Godot 4.7.1 is available) and a diff review.

## Effort estimate (rough)

| Phase | Demos | Nature |
|-------|-------|--------|
| 0 Pilot | 3 | code + docs, sets template |
| 1 Tier A | ~40 | code + docs (split/`class_name`/`@export`) |
| 2 Tier B | ~50 | light code + docs |
| 3 Docs | ~74 (all remaining) | docs only |
