# Gallery

Every demo, with a frame captured from its actual running scene. Click a demo to
open its README.

Screenshots are produced by `tools/screenshots.sh`, which runs each demo under a
virtual display and keeps one frame — so they show the real thing rather than
hand-picked marketing shots. A demo whose image is missing simply has not been
captured yet.

Looking for a route rather than a catalogue? See [learning paths](LEARNING_PATHS.md).


## 🎮 Movement & Platforming

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[arrow-sprite](../arrow-sprite)**<br><sub>Basic 2D movement with arrow keys, normalized direction, frame-rate-independent motion.</sub> | _(no screenshot yet)_<br>**[grid-movement](../grid-movement)**<br><sub>Tile-based movement one cell at a time with tween animation and wall blocking.</sub> | _(no screenshot yet)_<br>**[top-down-controller](../top-down-controller)**<br><sub>8-directional free movement with a facing indicator — the canonical top-down setup.</sub> |
| _(no screenshot yet)_<br>**[platformer-controller](../platformer-controller)**<br><sub>CharacterBody2D controller with coyote time and jump buffering for tight feel.</sub> | _(no screenshot yet)_<br>**[coyote-time](../coyote-time)**<br><sub>Coyote time and jump buffering, the two classic platformer feel improvements.</sub> | _(no screenshot yet)_<br>**[double-jump](../double-jump)**<br><sub>The double-jump mechanic.</sub> |
| _(no screenshot yet)_<br>**[variable-jump-height](../variable-jump-height)**<br><sub>Hold-to-jump-higher via a velocity cut on early button release.</sub> | _(no screenshot yet)_<br>**[wall-jump](../wall-jump)**<br><sub>Wall-sliding and wall-jumping mechanics.</sub> | _(no screenshot yet)_<br>**[wall-slide](../wall-slide)**<br><sub>Gravity reduction while pressing into a wall, terminal slide velocity, distance tracking.</sub> |
| _(no screenshot yet)_<br>**[ledge-grab](../ledge-grab)**<br><sub>Cling to walls mid-air and launch off diagonally using `get_wall_normal()`.</sub> | _(no screenshot yet)_<br>**[ledge-hang](../ledge-hang)**<br><sub>Auto-grab platform ledge corners when falling, hang, then pull up or drop.</sub> | _(no screenshot yet)_<br>**[dash-ability](../dash-ability)**<br><sub>Horizontal dash with cooldown, i-frames, and a ghost-image afterimage trail.</sub> |
| _(no screenshot yet)_<br>**[grapple-hook](../grapple-hook)**<br><sub>Fire a grapple and swing like a pendulum with a custom AABB-vs-circle collision system.</sub> | _(no screenshot yet)_<br>**[stamina-system](../stamina-system)**<br><sub>A depletable/regenerating resource that gates sprinting.</sub> | _(no screenshot yet)_<br>**[moving-platforms](../moving-platforms)**<br><sub>Oscillating platforms that correctly carry the player via `constant_linear_velocity`.</sub> |
| _(no screenshot yet)_<br>**[pushable-blocks](../pushable-blocks)**<br><sub>Shove blocks by walking into them, reading impulses from `move_and_slide()` collisions.</sub> |  |  |

## 🎥 Cameras & Viewports

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[camera-follow](../camera-follow)**<br><sub>Attach a `Camera2D` to the player with position smoothing and hard limits.</sub> | _(no screenshot yet)_<br>**[camera-deadzone](../camera-deadzone)**<br><sub>Camera stays still until the player exits a rectangular dead zone, then catches up.</sub> | _(no screenshot yet)_<br>**[camera-rooms](../camera-rooms)**<br><sub>Room-based camera transitions using `Area2D`, signals, and `Tween`.</sub> |
| _(no screenshot yet)_<br>**[camera-zoom](../camera-zoom)**<br><sub>Smooth scroll-wheel `Camera2D` zoom with lerp targeting and min/max limits.</sub> | _(no screenshot yet)_<br>**[pixel-art-camera](../pixel-art-camera)**<br><sub>Render at 160×120 and integer-scale 4× via `SubViewport` for crisp pixel art.</sub> | _(no screenshot yet)_<br>**[minimap](../minimap)**<br><sub>A real-time minimap drawn in code for a wide side-scrolling world.</sub> |
| _(no screenshot yet)_<br>**[subviewport](../subviewport)**<br><sub>Render one `World2D` through two cameras (main + minimap) via `SubViewport`.</sub> | _(no screenshot yet)_<br>**[split-screen](../split-screen)**<br><sub>Two-player split-screen, each with independent world, physics, and camera.</sub> | _(no screenshot yet)_<br>**[screen-shake](../screen-shake)**<br><sub>Camera shake by tweening `Camera2D.offset` through random displacements.</sub> |

## ⚙️ Physics & Simulation

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[bouncing-ball](../bouncing-ball)**<br><sub>A ball bouncing via Godot's built-in rigid body physics — no manual velocity code.</sub> | _(no screenshot yet)_<br>**[rigid-body](../rigid-body)**<br><sub>`RigidBody2D` objects that fall, collide, and stack under gravity.</sub> | _(no screenshot yet)_<br>**[buoyancy](../buoyancy)**<br><sub>Custom 2D buoyancy of boxes floating/sinking by density, no physics engine.</sub> |
| _(no screenshot yet)_<br>**[joint-physics](../joint-physics)**<br><sub>A `PinJoint2D` pendulum chain and a `DampedSpringJoint2D` weight, built in code.</sub> | _(no screenshot yet)_<br>**[rope-physics](../rope-physics)**<br><sub>A 24-node Verlet rope with iterative distance-constraint relaxation.</sub> | _(no screenshot yet)_<br>**[verlet-integration](../verlet-integration)**<br><sub>Position-based Verlet rope physics with mouse drag interaction.</sub> |
| _(no screenshot yet)_<br>**[explosion-force](../explosion-force)**<br><sub>Detonations that fling nearby balls outward with distance-based falloff.</sub> | _(no screenshot yet)_<br>**[magnet](../magnet)**<br><sub>Inverse-square attraction/repulsion field from a draggable magnet.</sub> | _(no screenshot yet)_<br>**[portal](../portal)**<br><sub>Balls enter one portal and exit the other with velocity correctly transformed.</sub> |
| _(no screenshot yet)_<br>**[quadtree](../quadtree)**<br><sub>Quadtree spatial partitioning to cut collision checks from brute force.</sub> | _(no screenshot yet)_<br>**[boid-flocking](../boid-flocking)**<br><sub>35 agents flock via separation, alignment, and cohesion — emergent behavior.</sub> | _(no screenshot yet)_<br>**[steering-behaviors](../steering-behaviors)**<br><sub>Reynolds' Seek/Arrive, Flee, and Wander force-based steering.</sub> |
| _(no screenshot yet)_<br>**[destructibles](../destructibles)**<br><sub>Click boxes to shatter them into scattered `RigidBody2D` fragments.</sub> |  |  |

## 🧠 AI, Pathfinding & Targeting

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[simple-ai](../simple-ai)**<br><sub>An enemy that always moves directly toward the player.</sub> | _(no screenshot yet)_<br>**[patrol-ai](../patrol-ai)**<br><sub>A three-state FSM: patrol waypoints, chase on detection, return when escaped.</sub> | _(no screenshot yet)_<br>**[behavior-tree](../behavior-tree)**<br><sub>Enemy AI driven by a composable behavior tree (patrol/investigate/chase/attack).</sub> |
| _(no screenshot yet)_<br>**[line-of-sight](../line-of-sight)**<br><sub>Enemies go ALERT on unobstructed physics-raycast line of sight to the player.</sub> | _(no screenshot yet)_<br>**[vision-cone](../vision-cone)**<br><sub>A 120° FOV cone plus Liang-Barsky line-of-sight test against walls.</sub> | _(no screenshot yet)_<br>**[raycasting](../raycasting)**<br><sub>`RayCast2D` line-of-sight detection toward the mouse cursor.</sub> |
| _(no screenshot yet)_<br>**[pathfinding-astar](../pathfinding-astar)**<br><sub>Interactive A* on a grid, visualizing open/closed sets and the optimal path.</sub> | _(no screenshot yet)_<br>**[grid-pathfinding](../grid-pathfinding)**<br><sub>A* on a tile grid written from scratch, without `NavigationAgent2D`.</sub> | _(no screenshot yet)_<br>**[navigation-agent](../navigation-agent)**<br><sub>`NavigationAgent2D` with a code-built `NavigationPolygon` and obstacle avoidance.</sub> |
| _(no screenshot yet)_<br>**[homing-projectile](../homing-projectile)**<br><sub>A missile that steers toward a moving target with `lerp_angle`.</sub> | _(no screenshot yet)_<br>**[path-follow](../path-follow)**<br><sub>`PathFollow2D` constant-speed movement along a `Path2D` curve.</sub> | _(no screenshot yet)_<br>**[bezier-path](../bezier-path)**<br><sub>Interactive cubic Bézier editor with an animated dot and tangent arrow.</sub> |

## ⚔️ Combat & Abilities

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[ability-system](../ability-system)**<br><sub>Four hotkey abilities with independent cooldowns and a shared mana pool.</sub> | _(no screenshot yet)_<br>**[combo-system](../combo-system)**<br><sub>Timed attack chains where inputs expire and longer patterns take priority.</sub> | _(no screenshot yet)_<br>**[cooldown-shoot](../cooldown-shoot)**<br><sub>Projectile instantiation with a cooldown timer and `ProgressBar` indicator.</sub> |
| _(no screenshot yet)_<br>**[spread-shot](../spread-shot)**<br><sub>Fire N bullets distributed evenly across a fixed angle.</sub> | _(no screenshot yet)_<br>**[hitbox-hurtbox](../hitbox-hurtbox)**<br><sub>The hitbox/hurtbox pattern — attack area separate from vulnerable area.</sub> | _(no screenshot yet)_<br>**[health-bar](../health-bar)**<br><sub>A complete HP system with animated bar, feedback flashes, and game-over.</sub> |
| _(no screenshot yet)_<br>**[status-effects](../status-effects)**<br><sub>Poison/burn/freeze as timed, stackable, data-driven modifiers.</sub> | _(no screenshot yet)_<br>**[input-buffer](../input-buffer)**<br><sub>Queue an early attack press during cooldown and fire it when it clears.</sub> | _(no screenshot yet)_<br>**[knockback](../knockback)**<br><sub>Velocity-based hit recoil that decays exponentially, with i-frames.</sub> |

## 🏛️ Architecture & Patterns

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[state-machine](../state-machine)**<br><sub>A four-state FSM (idle/walk/jump/fall) derived from physics state.</sub> | _(no screenshot yet)_<br>**[state-machine-hfsm](../state-machine-hfsm)**<br><sub>A hierarchical FSM tree with enter/exit callbacks and cascading transitions.</sub> | _(no screenshot yet)_<br>**[autoload-score](../autoload-score)**<br><sub>The Autoload/Singleton pattern: global state that emits change signals.</sub> |
| _(no screenshot yet)_<br>**[event-bus](../event-bus)**<br><sub>An Autoload event bus so nodes broadcast/listen without direct references.</sub> | _(no screenshot yet)_<br>**[typed-event-bus](../typed-event-bus)**<br><sub>A pub/sub bus with string-keyed events carrying typed `Dictionary` payloads.</sub> | _(no screenshot yet)_<br>**[signal-relay](../signal-relay)**<br><sub>The signal system: a transmitter emits, a receiver handles, main wires them.</sub> |
| _(no screenshot yet)_<br>**[groups](../groups)**<br><sub>Broadcast a method call to every node in a named group in one line.</sub> | _(no screenshot yet)_<br>**[object-pool](../object-pool)**<br><sub>Pre-allocate and recycle objects instead of creating/destroying them.</sub> | _(no screenshot yet)_<br>**[object-factory](../object-factory)**<br><sub>The factory pattern: a type registry decoupling creation from callers.</sub> |
| _(no screenshot yet)_<br>**[entity-component-system](../entity-component-system)**<br><sub>A pure-GDScript ECS: entity IDs, component dicts, system functions.</sub> | _(no screenshot yet)_<br>**[custom-resource](../custom-resource)**<br><sub>`class_name` resources with `@export` vars as typed data containers.</sub> | _(no screenshot yet)_<br>**[scene-instancing](../scene-instancing)**<br><sub>Instantiate scenes at runtime with `preload()` and a self-destruct `Timer`.</sub> |
| _(no screenshot yet)_<br>**[checkpoint-system](../checkpoint-system)**<br><sub>One-way checkpoints that update respawn position; press R to die and respawn.</sub> | _(no screenshot yet)_<br>**[export-vars](../export-vars)**<br><sub>`@export` variables exposed to the Inspector without touching code.</sub> | _(no screenshot yet)_<br>**[area-trigger](../area-trigger)**<br><sub>`Area2D` invisible trigger zones firing signals on body enter/exit.</sub> |

## 💾 Data & Persistence

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[data-tables](../data-tables)**<br><sub>A Resource-based item database with a filter-and-detail UI.</sub> | _(no screenshot yet)_<br>**[save-load](../save-load)**<br><sub>Persist structured game state to JSON in the user data dir, across sessions.</sub> | _(no screenshot yet)_<br>**[save-migration](../save-migration)**<br><sub>Upgrading saves written by older versions of your game, one step per version bump.</sub> |
| _(no screenshot yet)_<br>**[config-file](../config-file)**<br><sub>A settings panel persisted to `user://settings.cfg` via `ConfigFile`.</sub> | _(no screenshot yet)_<br>**[undo-redo](../undo-redo)**<br><sub>A drawing canvas using Godot 4's built-in `UndoRedo` (Ctrl+Z / Ctrl+Y).</sub> | _(no screenshot yet)_<br>**[localization](../localization)**<br><sub>`TranslationServer` string tables switched at runtime across EN/ES/FR.</sub> |

## 🎯 Game Systems

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[inventory](../inventory)**<br><sub>A grid inventory: pick up, place, swap slots, and drop back to the world.</sub> | _(no screenshot yet)_<br>**[crafting-system](../crafting-system)**<br><sub>Combine two ingredients into a result via a commutative recipe dictionary.</sub> | _(no screenshot yet)_<br>**[drop-table](../drop-table)**<br><sub>Weighted random loot; watch observed rates converge on expected probabilities.</sub> |
| _(no screenshot yet)_<br>**[quest-system](../quest-system)**<br><sub>A multi-quest tracker with kill/collect/reach objectives and XP rewards.</sub> | _(no screenshot yet)_<br>**[dialogue-box](../dialogue-box)**<br><sub>Typewriter text reveal, speaker labels, multi-line progression, skip.</sub> | _(no screenshot yet)_<br>**[dialogue-tree](../dialogue-tree)**<br><sub>Branching conversations with conditional choices that mutate game state.</sub> |
| _(no screenshot yet)_<br>**[skill-tree](../skill-tree)**<br><sub>A node-graph skill tree with prerequisites, costs, tooltips, and unlock states.</sub> | _(no screenshot yet)_<br>**[experience-leveling](../experience-leveling)**<br><sub>XP collection and leveling on an exponential curve with stat gains.</sub> | _(no screenshot yet)_<br>**[interaction-system](../interaction-system)**<br><sub>A reusable "press E to interact" system using `Area2D` proximity.</sub> |
| _(no screenshot yet)_<br>**[wave-spawner](../wave-spawner)**<br><sub>Phase-based waves with intermission countdowns and difficulty scaling.</sub> | _(no screenshot yet)_<br>**[tower-defense-base](../tower-defense-base)**<br><sub>The core TD loop: path enemies, tower placement, targeting, gold, waves.</sub> | _(no screenshot yet)_<br>**[coin-collector](../coin-collector)**<br><sub>Scene instancing, custom signals, and `Area2D` pickups for a collect-all goal.</sub> |

## 🖱️ UI & Menus

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[pause-menu](../pause-menu)**<br><sub>`get_tree().paused` with a `PROCESS_MODE_ALWAYS` `CanvasLayer` menu.</sub> | _(no screenshot yet)_<br>**[settings-menu](../settings-menu)**<br><sub>A settings panel with volume slider, fullscreen toggle, and player color.</sub> | _(no screenshot yet)_<br>**[accessibility-options](../accessibility-options)**<br><sub>Colourblind-safe palettes, reduced motion, text scaling, and shape cues.</sub> |
| _(no screenshot yet)_<br>**[subtitle-system](../subtitle-system)**<br><sub>A caption queue for speech and non-speech audio, timed by reading speed.</sub> | _(no screenshot yet)_<br>**[radial-menu](../radial-menu)**<br><sub>Hold Tab to open a six-item radial action menu.</sub> | _(no screenshot yet)_<br>**[context-menu](../context-menu)**<br><sub>A right-click menu built entirely in `_draw()`/`_input()` — no Control nodes.</sub> |
| _(no screenshot yet)_<br>**[circle-buttons](../circle-buttons)**<br><sub>A reusable component rendering a data array as clickable circles.</sub> | _(no screenshot yet)_<br>**[tooltip](../tooltip)**<br><sub>Hover tooltips with delay, alpha fade, accent colors, and edge clamping.</sub> | _(no screenshot yet)_<br>**[drag-drop](../drag-drop)**<br><sub>Mouse drag-and-drop with snap-back when dropped outside a valid target.</sub> |
| _(no screenshot yet)_<br>**[virtual-joystick](../virtual-joystick)**<br><sub>An on-screen click-and-drag joystick for touch-style movement.</sub> | _(no screenshot yet)_<br>**[floating-text](../floating-text)**<br><sub>Self-managing damage/pickup labels that rise, fade, and free themselves.</sub> | _(no screenshot yet)_<br>**[multiline-text](../multiline-text)**<br><sub>`RichTextLabel` BBCode: bold, color, tables, animated effects.</sub> |
| _(no screenshot yet)_<br>**[canvas-layer](../canvas-layer)**<br><sub>`CanvasLayer` screen-space overlays for HUDs and persistent UI.</sub> | _(no screenshot yet)_<br>**[debug-overlay](../debug-overlay)**<br><sub>A toggleable always-on-top HUD showing FPS, position, velocity, state.</sub> | _(no screenshot yet)_<br>**[notification-queue](../notification-queue)**<br><sub>A FIFO notification system sliding messages in one at a time.</sub> |

## 🎛️ Input

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[gamepad-input](../gamepad-input)**<br><sub>Joystick detection, analog axes with deadzone, buttons, and vibration.</sub> | _(no screenshot yet)_<br>**[input-remapping](../input-remapping)**<br><sub>Runtime key rebinding via the `InputMap` singleton.</sub> | _(no screenshot yet)_<br>**[input-recording](../input-recording)**<br><sub>Capturing input per frame and replaying it deterministically.</sub> |
| _(no screenshot yet)_<br>**[local-multiplayer](../local-multiplayer)**<br><sub>Two players on one keyboard via per-instance input schemes.</sub> |  |  |

## 🔊 Audio

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[audio-demo](../audio-demo)**<br><sub>Generate SFX in code via raw PCM synthesis, routed through audio buses.</sub> | _(no screenshot yet)_<br>**[audio-bus-effects](../audio-bus-effects)**<br><sub>Dynamic reverb, echo, and compression routed through an `AudioBus`.</sub> | _(no screenshot yet)_<br>**[audio-positional](../audio-positional)**<br><sub>`AudioStreamPlayer2D` spatial attenuation with a synthesized tone.</sub> |
| _(no screenshot yet)_<br>**[footstep-audio](../footstep-audio)**<br><sub>Surface-sensitive footsteps synthesized per surface on a step signal.</sub> | _(no screenshot yet)_<br>**[procedural-sfx](../procedural-sfx)**<br><sub>Real-time SFX synthesis via `AudioStreamGeneratorPlayback.push_frame()`.</sub> | _(no screenshot yet)_<br>**[dynamic-music](../dynamic-music)**<br><sub>Real-time synthesis and crossfading between two music layers.</sub> |
| _(no screenshot yet)_<br>**[music-sequencer](../music-sequencer)**<br><sub>A 16-step × 8-note step sequencer with real-time sine synthesis.</sub> |  |  |

## ✨ Shaders & Visual Effects

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[shader-intro](../shader-intro)**<br><sub>Intro to `ShaderMaterial`: tint, hit-flash, and outline swapped at runtime.</sub> | _(no screenshot yet)_<br>**[shader-effects](../shader-effects)**<br><sub>Applied shaders: dissolve, pixelate, and wave-warp.</sub> | _(no screenshot yet)_<br>**[post-processing-stack](../post-processing-stack)**<br><sub>A composable pipeline: vignette, chromatic aberration, color grading.</sub> |
| _(no screenshot yet)_<br>**[screen-distortion](../screen-distortion)**<br><sub>Full-screen heat-haze via `SubViewport` + UV-displacing shader.</sub> | _(no screenshot yet)_<br>**[screen-warp](../screen-warp)**<br><sub>Sinusoidal UV displacement of the whole world via `SubViewportContainer`.</sub> | _(no screenshot yet)_<br>**[screen-flash](../screen-flash)**<br><sub>Full-screen color flash feedback via a `ColorRect` + Tween.</sub> |
| _(no screenshot yet)_<br>**[dissolve-effect](../dissolve-effect)**<br><sub>Noise-threshold dissolve/appear transition on a grid — no shader.</sub> | _(no screenshot yet)_<br>**[palette-swap](../palette-swap)**<br><sub>A shader replacing source colors with destination colors by RGB distance.</sub> | _(no screenshot yet)_<br>**[palette-cycling](../palette-cycling)**<br><sub>Classic indexed-color palette rotation for animated water/lava/rainbow.</sub> |
| _(no screenshot yet)_<br>**[sprite-outline](../sprite-outline)**<br><sub>Hover/selection outlines via procedural `_draw()` — no sprites or shaders.</sub> | _(no screenshot yet)_<br>**[normal-map-lighting](../normal-map-lighting)**<br><sub>Procedural bump-map Phong lighting from a finite-difference height field.</sub> | _(no screenshot yet)_<br>**[gpu-particles-custom](../gpu-particles-custom)**<br><sub>80 particles simulated analytically in a fragment shader — no CPU state.</sub> |
| _(no screenshot yet)_<br>**[particle-effects](../particle-effects)**<br><sub>`CPUParticles2D` fire, smoke, sparkle, and explosion on one emitter.</sub> | _(no screenshot yet)_<br>**[trail-effect](../trail-effect)**<br><sub>A `Line2D` gradient trail following a moving object.</sub> | _(no screenshot yet)_<br>**[2d-water](../2d-water)**<br><sub>An animated water surface shader with distortion, foam, and shimmer.</sub> |
| _(no screenshot yet)_<br>**[2d-lighting](../2d-lighting)**<br><sub>Runtime `GradientTexture2D` point lights under a global `CanvasModulate`.</sub> | _(no screenshot yet)_<br>**[light-shadow](../light-shadow)**<br><sub>`PointLight2D` with a procedural radial gradient and `CanvasModulate`.</sub> | _(no screenshot yet)_<br>**[day-night-cycle](../day-night-cycle)**<br><sub>A 24-hour cycle via `CanvasModulate` with sun/moon arcs and stars.</sub> |
| _(no screenshot yet)_<br>**[wind-effect](../wind-effect)**<br><sub>80 wind-blown leaves with gusts, damping, lifetime fade, and motion blur.</sub> |  |  |

## 🎞️ Animation

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[animated-sprite](../animated-sprite)**<br><sub>A sprite sheet generated entirely in code — no image files or imports.</sub> | _(no screenshot yet)_<br>**[animated-walk](../animated-walk)**<br><sub>Character animation in code via `AnimationPlayer` and `AnimationLibrary`.</sub> | _(no screenshot yet)_<br>**[animation-tree](../animation-tree)**<br><sub>`AnimationTree` + `AnimationNodeStateMachine` driving squash-and-stretch.</sub> |
| _(no screenshot yet)_<br>**[procedural-animation](../procedural-animation)**<br><sub>FABRIK inverse kinematics on an 8-joint chain following the mouse.</sub> | _(no screenshot yet)_<br>**[tween-juice](../tween-juice)**<br><sub>"Game feel" via Tween: button squish and a floating score label.</sub> |  |

## 🌍 Procedural Generation

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[procedural-gen](../procedural-gen)**<br><sub>`FastNoiseLite` generating terrain, caves, islands, and moisture maps.</sub> | _(no screenshot yet)_<br>**[noise-terrain](../noise-terrain)**<br><sub>1D terrain from `get_noise_1d()`, redrawing live as you tune parameters.</sub> | _(no screenshot yet)_<br>**[dungeon-generator](../dungeon-generator)**<br><sub>Random room placement with L-shaped corridor carving.</sub> |
| _(no screenshot yet)_<br>**[wave-function-collapse](../wave-function-collapse)**<br><sub>Constraint-propagation tile placement for locally consistent maps.</sub> | _(no screenshot yet)_<br>**[l-system](../l-system)**<br><sub>Lindenmayer string-rewriting generating fractal geometry via turtle graphics.</sub> | _(no screenshot yet)_<br>**[marching-squares](../marching-squares)**<br><sub>Contour line extraction from a 2D scalar field.</sub> |
| _(no screenshot yet)_<br>**[cellular-automata](../cellular-automata)**<br><sub>A falling-sand sim: sand, water, and stone with per-cell rules.</sub> |  |  |

## 🖼️ Rendering & Scene Management

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[parallax-scroll](../parallax-scroll)**<br><sub>Multiple background layers scrolling at different speeds for depth.</sub> | _(no screenshot yet)_<br>**[tilemap](../tilemap)**<br><sub>Build a `TileSet` and `TileMapLayer` in code with a runtime-generated atlas.</sub> | _(no screenshot yet)_<br>**[tilemap-room](../tilemap-room)**<br><sub>A scrollable room larger than the viewport with `Camera2D` limits.</sub> |
| _(no screenshot yet)_<br>**[scene-transition](../scene-transition)**<br><sub>Fade-to-black scene changes via a persistent Autoload `CanvasLayer`.</sub> | _(no screenshot yet)_<br>**[thread-loading](../thread-loading)**<br><sub>`load_threaded_request()` background loading with a progress UI.</sub> | _(no screenshot yet)_<br>**[visible-notifier](../visible-notifier)**<br><sub>`VisibleOnScreenNotifier2D` signals for zero-poll CPU culling.</sub> |
| _(no screenshot yet)_<br>**[line-drawing](../line-drawing)**<br><sub>Freehand stroke drawing via immediate-mode `_draw()`.</sub> | _(no screenshot yet)_<br>**[polygon-clip](../polygon-clip)**<br><sub>An interactive `Polygon2D` vertex editor with convex hull via `Geometry2D`.</sub> |  |

## 🧰 Editor Tooling

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[tool-script](../tool-script)**<br><sub>`@tool`: a layout helper that arranges its children in the editor, before the game runs.</sub> | _(no screenshot yet)_<br>**[editor-plugin](../editor-plugin)**<br><sub>An `EditorPlugin` adding a dock and a custom node type, with symmetric teardown.</sub> |  |

## 🌐 Networking & Misc

| | | |
|---|---|---|
| _(no screenshot yet)_<br>**[multiplayer-rpc](../multiplayer-rpc)**<br><sub>High-level multiplayer over ENet: host/join, a server-authoritative roster, and `@rpc`.</sub> | _(no screenshot yet)_<br>**[multiplayer-prediction](../multiplayer-prediction)**<br><sub>Applying input locally, then reconciling when the authoritative server disagrees.</sub> | _(no screenshot yet)_<br>**[performance-profiling](../performance-profiling)**<br><sub>Measuring where a frame's time goes, against the budget the target rate gives you.</sub> |
| _(no screenshot yet)_<br>**[http-request](../http-request)**<br><sub>Fetch and parse JSON from a public API with the `HTTPRequest` node.</sub> | _(no screenshot yet)_<br>**[lock-picking](../lock-picking)**<br><sub>Rotate a lock cylinder to find a hidden angle; tension builds when close.</sub> | _(no screenshot yet)_<br>**[rhythm-minigame](../rhythm-minigame)**<br><sub>Timed-input rhythm mechanics with a scoring judgment window.</sub> |

---

_165 demos, 0 with screenshots._
