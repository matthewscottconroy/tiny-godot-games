# Learning paths

The index in the root README is a reference: 157 demos, alphabetical inside
categories, all equal. That is the right shape when you already know what you
are looking for and the wrong shape when you don't.

These are ordered routes through the same demos. Each one builds toward a
recognisable kind of game, and each step assumes the ones before it. Work
through a path in order and the later demos will keep referring to things you
have already seen.

**Difficulty** is marked per step, and means how much is going on in the file,
not how clever it is:

- 🟢 **Starter** — one idea, nothing assumed.
- 🟡 **Working** — several pieces interacting; assumes you can read a
  `CharacterBody2D` script without looking things up.
- 🔴 **Deep** — an algorithm or an architecture, worth reading twice.

---

## 1. Build a platformer

The most-travelled route. By the end you have a character that feels good to
control, a camera that follows well, and progress that survives a restart.

| # | Demo | | What it adds |
|---|------|---|--------------|
| 1 | [arrow-sprite](../arrow-sprite) | 🟢 | Reading input, moving something, frame-rate independence |
| 2 | [platformer-controller](../platformer-controller) | 🟡 | Gravity, jumping, `move_and_slide()` |
| 3 | [coyote-time](../coyote-time) | 🟡 | The two forgiveness windows that make jumping feel fair |
| 4 | [variable-jump-height](../variable-jump-height) | 🟢 | Hold-to-jump-higher — three lines, big difference |
| 5 | [double-jump](../double-jump) | 🟢 | A counted ability that an event refills |
| 6 | [wall-slide](../wall-slide) | 🟡 | Gravity modifiers and terminal velocity |
| 7 | [wall-jump](../wall-jump) | 🟡 | Launching off `get_wall_normal()`, and the input lock |
| 8 | [dash-ability](../dash-ability) | 🟡 | Cooldowns, i-frames, an afterimage trail |
| 9 | [moving-platforms](../moving-platforms) | 🟡 | Carrying the player without parenting |
| 10 | [camera-follow](../camera-follow) | 🟢 | Smoothing and limits |
| 11 | [camera-deadzone](../camera-deadzone) | 🟡 | Why good platformer cameras don't track exactly |
| 12 | [checkpoint-system](../checkpoint-system) | 🟡 | Respawn points via `Area2D` and signals |
| 13 | [save-load](../save-load) | 🟡 | Persisting progress as JSON under `user://` |

**Then:** [screen-shake](../screen-shake), [tween-juice](../tween-juice) and
[particle-effects](../particle-effects) for feel; [tilemap](../tilemap) and
[parallax-scroll](../parallax-scroll) to build real levels.

---

## 2. Build a top-down action game

| # | Demo | | What it adds |
|---|------|---|--------------|
| 1 | [top-down-controller](../top-down-controller) | 🟢 | 8-directional movement with facing |
| 2 | [cooldown-shoot](../cooldown-shoot) | 🟢 | Firing on a timer |
| 3 | [spread-shot](../spread-shot) | 🟢 | Aiming several projectiles at once |
| 4 | [object-pool](../object-pool) | 🟡 | Recycling projectiles instead of allocating |
| 5 | [hitbox-hurtbox](../hitbox-hurtbox) | 🟡 | Separating "what hits" from "what can be hit" |
| 6 | [health-bar](../health-bar) | 🟡 | A hit-point model with signals, no UI baked in |
| 7 | [knockback](../knockback) | 🟡 | Recoil that layers on top of normal control |
| 8 | [status-effects](../status-effects) | 🔴 | Timed, stacking modifiers |
| 9 | [simple-ai](../simple-ai) | 🟢 | The simplest possible enemy |
| 10 | [patrol-ai](../patrol-ai) | 🟡 | A three-state enemy FSM |
| 11 | [vision-cone](../vision-cone) | 🔴 | FOV, range, and occlusion as pure geometry |
| 12 | [wave-spawner](../wave-spawner) | 🟡 | The phase machine behind horde modes |

**Then:** [behavior-tree](../behavior-tree) when the FSM stops scaling,
[quadtree](../quadtree) when collision checks get expensive.

---

## 3. Build an RPG's systems

The parts that are all data and rules rather than movement.

| # | Demo | | What it adds |
|---|------|---|--------------|
| 1 | [custom-resource](../custom-resource) | 🟢 | Designer-editable data as a `Resource` |
| 2 | [data-tables](../data-tables) | 🟡 | A queryable item database |
| 3 | [inventory](../inventory) | 🟡 | Slots, the held-item cursor, swap semantics |
| 4 | [drop-table](../drop-table) | 🟡 | Weighted random loot |
| 5 | [crafting-system](../crafting-system) | 🟢 | Order-independent recipe lookup |
| 6 | [experience-leveling](../experience-leveling) | 🟡 | XP curves and overflow on level-up |
| 7 | [skill-tree](../skill-tree) | 🔴 | Prerequisite gating over a graph |
| 8 | [quest-system](../quest-system) | 🟡 | Objectives, progress, completion signals |
| 9 | [dialogue-box](../dialogue-box) | 🟡 | Typewriter reveal and advancing |
| 10 | [dialogue-tree](../dialogue-tree) | 🔴 | Branching, with the condition check left to your game |
| 11 | [save-load](../save-load) | 🟡 | Writing all of it to disk |
| 12 | [save-migration](../save-migration) | 🔴 | Loading saves written by an older version of your game |

---

## 4. Architecture: how to stop the spaghetti

Read this path when a project has grown past one script and started to tangle.

| # | Demo | | What it adds |
|---|------|---|--------------|
| 1 | [signal-relay](../signal-relay) | 🟢 | Two nodes that don't know about each other |
| 2 | [groups](../groups) | 🟢 | Addressing many nodes at once |
| 3 | [state-machine](../state-machine) | 🟡 | Making states explicit instead of boolean soup |
| 4 | [state-machine-hfsm](../state-machine-hfsm) | 🔴 | Nesting states when the flat FSM stops scaling |
| 5 | [autoload-score](../autoload-score) | 🟢 | Global state, and its cost |
| 6 | [event-bus](../event-bus) | 🟡 | Decoupling via a global signal hub |
| 7 | [typed-event-bus](../typed-event-bus) | 🔴 | The same idea with the type safety back |
| 8 | [object-factory](../object-factory) | 🟡 | Creation without the caller knowing the type |
| 9 | [entity-component-system](../entity-component-system) | 🔴 | Composition when inheritance runs out |
| 10 | [undo-redo](../undo-redo) | 🟡 | Reversible actions via `UndoRedo` |

---

## 5. Procedural generation

| # | Demo | | What it adds |
|---|------|---|--------------|
| 1 | [noise-terrain](../noise-terrain) | 🟢 | What `FastNoiseLite`'s parameters actually do |
| 2 | [procedural-gen](../procedural-gen) | 🟡 | Noise into terrain, caves, islands, moisture |
| 3 | [dungeon-generator](../dungeon-generator) | 🟡 | Rooms and corridors, the dumb-and-effective way |
| 4 | [cellular-automata](../cellular-automata) | 🟡 | Per-cell rules producing emergent behaviour |
| 5 | [marching-squares](../marching-squares) | 🔴 | Turning a scalar field into smooth contours |
| 6 | [l-system](../l-system) | 🔴 | Rewrite rules into fractal geometry |
| 7 | [wave-function-collapse](../wave-function-collapse) | 🔴 | Constraint propagation over a tile grid |

---

## 6. Shaders, from nothing

| # | Demo | | What it adds |
|---|------|---|--------------|
| 1 | [shader-intro](../shader-intro) | 🟢 | `COLOR`, `UV`, and what a fragment shader is |
| 2 | [shader-effects](../shader-effects) | 🟡 | Dissolve, pixelate, wave — three self-contained shaders |
| 3 | [sprite-outline](../sprite-outline) | 🟢 | The same effect without a shader, for comparison |
| 4 | [palette-swap](../palette-swap) | 🟡 | Recolouring by distance in RGB |
| 5 | [screen-warp](../screen-warp) | 🟡 | Displacing the whole screen through a `SubViewport` |
| 6 | [post-processing-stack](../post-processing-stack) | 🔴 | Composing vignette, aberration and grading in one pass |
| 7 | [normal-map-lighting](../normal-map-lighting) | 🔴 | Deriving normals and shading them |
| 8 | [gpu-particles-custom](../gpu-particles-custom) | 🔴 | Simulating with no CPU state at all |

---

## 7. Multiplayer

| # | Demo | | What it adds |
|---|------|---|--------------|
| 1 | [local-multiplayer](../local-multiplayer) | 🟢 | Two players, one keyboard — no networking yet |
| 2 | [split-screen](../split-screen) | 🟡 | Independent viewports, worlds and cameras |
| 3 | [multiplayer-rpc](../multiplayer-rpc) | 🔴 | ENet, `@rpc`, and server authority |
| 4 | [multiplayer-prediction](../multiplayer-prediction) | 🔴 | Predicting locally, then reconciling when the server disagrees |

---

## 8. Ship it

The unglamorous parts that decide whether anyone finishes your game.

| # | Demo | | What it adds |
|---|------|---|--------------|
| 1 | [pause-menu](../pause-menu) | 🟢 | `SceneTree.paused` and process modes |
| 2 | [settings-menu](../settings-menu) | 🟡 | Audio buses, fullscreen, and persistence |
| 3 | [input-remapping](../input-remapping) | 🟡 | Rebinding at runtime |
| 4 | [accessibility-options](../accessibility-options) | 🟡 | Colourblind palettes, reduced motion, text scale |
| 5 | [subtitle-system](../subtitle-system) | 🟡 | Captions for speech and important sounds |
| 6 | [localization](../localization) | 🟡 | Runtime locale switching |
| 7 | [scene-transition](../scene-transition) | 🟢 | Not cutting hard between scenes |
| 8 | [thread-loading](../thread-loading) | 🔴 | Loading without freezing |
| 9 | [performance-profiling](../performance-profiling) | 🔴 | Finding out why it is slow, with numbers |
| 10 | [debug-overlay](../debug-overlay) | 🟢 | Seeing your own game's state while it runs |

---

## Working in the editor

Not a game, but the thing you build the game with.

| # | Demo | | What it adds |
|---|------|---|--------------|
| 1 | [tool-script](../tool-script) | 🟡 | `@tool`: scripts that run in the editor |
| 2 | [editor-plugin](../editor-plugin) | 🔴 | A dock, a custom node type, and viewport handles |

---

## If you are brand new

Do these five in order first, whichever path you are heading for:

1. [arrow-sprite](../arrow-sprite) — input and movement
2. [scene-instancing](../scene-instancing) — spawning things
3. [signal-relay](../signal-relay) — how nodes talk
4. [area-trigger](../area-trigger) — detecting overlap
5. [export-vars](../export-vars) — exposing values to the Inspector

Those five cover most of what every other demo assumes you already know.
