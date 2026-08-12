extends Node2D

const TILE      := 40
const GRID_W    := 16
const GRID_H    := 12

const TOWER_COST    := 50
const TOWER_RANGE   := 100.0
const FIRE_RATE     := 1.5
const BULLET_SPEED  := 320.0
const TOWER_DAMAGE  := 1

const ENEMY_SPEED   := 80.0
const ENEMY_REWARD  := 20
const SPAWN_GAP     := 1.8

const START_LIVES   := 10
const START_GOLD    := 150

# Path as grid coordinates — snakes across the map
const PATH := [
	Vector2i(0,6),  Vector2i(1,6),  Vector2i(2,6),  Vector2i(3,6),
	Vector2i(3,5),  Vector2i(3,4),  Vector2i(3,3),
	Vector2i(4,3),  Vector2i(5,3),  Vector2i(6,3),  Vector2i(7,3),
	Vector2i(7,4),  Vector2i(7,5),  Vector2i(7,6),  Vector2i(7,7),  Vector2i(7,8),
	Vector2i(8,8),  Vector2i(9,8),  Vector2i(10,8), Vector2i(11,8), Vector2i(12,8),
	Vector2i(12,7), Vector2i(12,6), Vector2i(12,5), Vector2i(12,4),
	Vector2i(13,4), Vector2i(14,4), Vector2i(15,4),
]

var _grid:    Array = []
var _towers:  Array[Dictionary] = []
var _enemies: Array[Dictionary] = []
var _bullets: Array[Dictionary] = []
var _path_w:  Array[Vector2]    = []   # world-space path waypoints

var _lives := START_LIVES
var _gold  := START_GOLD
var _wave  := 1
var _spawned   := 0
var _spawn_t   := 0.0
var _wave_size := 6
var _game_over := false

func _ready() -> void:
	_grid.clear()
	for _y in GRID_H:
		var row: Array = []
		row.resize(GRID_W)
		row.fill(0)
		_grid.append(row)
	for p in PATH:
		_grid[p.y][p.x] = 1
	_path_w.clear()
	for p in PATH:
		_path_w.append(Vector2(p.x * TILE + TILE * 0.5, p.y * TILE + TILE * 0.5))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_tower(event.position)

func _place_tower(mpos: Vector2) -> void:
	if _game_over or _gold < TOWER_COST:
		return
	var gx := int(mpos.x / TILE)
	var gy := int(mpos.y / TILE)
	if gx < 0 or gx >= GRID_W or gy < 0 or gy >= GRID_H:
		return
	if _grid[gy][gx] != 0:
		return
	_gold -= TOWER_COST
	_grid[gy][gx] = 2
	_towers.append({
		"pos": Vector2(gx * TILE + TILE * 0.5, gy * TILE + TILE * 0.5),
		"cd": 0.0,
	})

func _process(delta: float) -> void:
	if _game_over:
		queue_redraw()
		return

	# Spawn enemies
	if _spawned < _wave_size:
		_spawn_t -= delta
		if _spawn_t <= 0.0:
			_spawn_t = SPAWN_GAP
			_spawn_enemy()

	# Next wave when cleared
	if _spawned >= _wave_size and _enemies.is_empty():
		_wave += 1
		_wave_size = 6 + (_wave - 1) * 2
		_spawned = 0
		_spawn_t = 1.0

	# Move enemies
	var dead: Array = []
	for e in _enemies:
		_advance(e, delta)
		if e["idx"] >= _path_w.size():
			_lives -= 1
			dead.append(e)
			if _lives <= 0:
				_game_over = true
		elif e["hp"] <= 0:
			_gold += ENEMY_REWARD
			dead.append(e)
	for e in dead:
		_enemies.erase(e)

	# Tower fire
	for t in _towers:
		t["cd"] -= delta
		if t["cd"] <= 0.0:
			var tgt := _best_target(t["pos"])
			if tgt != null:
				t["cd"] = 1.0 / FIRE_RATE
				_bullets.append({"pos": t["pos"], "tgt": tgt, "vel": Vector2.ZERO})

	# Move bullets
	var spent: Array = []
	for b in _bullets:
		if not _enemies.has(b["tgt"]) or b["tgt"]["hp"] <= 0:
			spent.append(b)
			continue
		var d: Vector2 = (b["tgt"]["pos"] - b["pos"]).normalized()
		b["pos"] += d * BULLET_SPEED * delta
		if b["pos"].distance_to(b["tgt"]["pos"]) < 6.0:
			b["tgt"]["hp"] -= TOWER_DAMAGE
			spent.append(b)
	for b in spent:
		_bullets.erase(b)

	queue_redraw()

func _spawn_enemy() -> void:
	_spawned += 1
	var hp := 3 + (_wave - 1)
	_enemies.append({"pos": _path_w[0], "idx": 0, "hp": hp, "max_hp": hp})

func _advance(e: Dictionary, delta: float) -> void:
	if e["idx"] >= _path_w.size() - 1:
		e["idx"] = _path_w.size()
		return
	var tgt: Vector2 = _path_w[e["idx"] + 1]
	var d: Vector2 = (tgt - e["pos"]).normalized()
	e["pos"] += d * ENEMY_SPEED * delta
	if e["pos"].distance_to(tgt) < 2.0:
		e["pos"] = tgt
		e["idx"] += 1

func _best_target(tpos: Vector2) -> Dictionary:
	var best := {}
	var best_idx := -1
	for e in _enemies:
		if e["hp"] <= 0:
			continue
		if tpos.distance_to(e["pos"]) <= TOWER_RANGE and e["idx"] > best_idx:
			best_idx = e["idx"]
			best = e
	return best

func _draw() -> void:
	for y in GRID_H:
		for x in GRID_W:
			var c: int = _grid[y][x]
			var col := Color(0.20, 0.35, 0.14) if c == 0 else \
						Color(0.60, 0.55, 0.38) if c == 1 else \
						Color(0.22, 0.48, 0.80)
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), col)
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), Color(0,0,0,0.08), false, 1)

	for t in _towers:
		draw_arc(t["pos"], TOWER_RANGE, 0, TAU, 32, Color(0.5, 0.7, 1.0, 0.12))
		draw_circle(t["pos"], 10.0, Color(0.15, 0.35, 0.65))

	for e in _enemies:
		if e["hp"] <= 0:
			continue
		draw_circle(e["pos"], 11.0, Color.TOMATO)
		var ratio := float(e["hp"]) / float(e["max_hp"])
		draw_rect(Rect2(e["pos"].x - 11, e["pos"].y - 17, 22, 4), Color(0.3,0,0))
		draw_rect(Rect2(e["pos"].x - 11, e["pos"].y - 17, 22 * ratio, 4), Color.LIME_GREEN)

	for b in _bullets:
		draw_circle(b["pos"], 3.5, Color.YELLOW)

	draw_rect(Rect2(0, 460, 640, 20), Color(0,0,0,0.6))
	draw_string(ThemeDB.fallback_font, Vector2(6, 474),
		"Gold: %d  Lives: %d  Wave: %d  Tower cost: %d  Click empty tile to build" % \
		[_gold, _lives, _wave, TOWER_COST],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	if _game_over:
		draw_rect(Rect2(0, 0, 640, 480), Color(0,0,0,0.5))
		draw_string(ThemeDB.fallback_font, Vector2(240, 240),
			"GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.TOMATO)
