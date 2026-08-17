extends Node

# Drives the real game from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_board_is_laid_out()
	_test_a_tower_costs_gold_and_takes_a_tile()
	_test_towers_cannot_be_built_on_the_path()
	_test_towers_cannot_be_stacked()
	_test_you_cannot_build_what_you_cannot_afford()
	_test_clicks_off_the_board_are_ignored()
	_test_enemies_walk_the_path()
	_test_an_enemy_reaching_the_end_costs_a_life()
	_test_losing_every_life_ends_the_game()
	_test_killing_an_enemy_pays_out()
	_test_a_tower_shoots_the_enemy_furthest_along()
	_test_a_tower_ignores_enemies_out_of_range()
	_test_an_idle_tower_holds_its_fire()
	_test_bullets_wear_an_enemy_down()
	_test_clearing_a_wave_starts_a_harder_one()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[tower-defense-base] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _centre_of(m: Node2D, cell: Vector2i) -> Vector2:
	return Vector2(cell.x * m.TILE + m.TILE * 0.5, cell.y * m.TILE + m.TILE * 0.5)

## A buildable tile: on the board, off the path.
func _free_tile(m: Node2D) -> Vector2i:
	for y in m.GRID_H:
		for x in m.GRID_W:
			if m._grid[y][x] == 0:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _enemy_at(m: Node2D, pos: Vector2, idx: int, hp: int) -> Dictionary:
	var e := {"pos": pos, "idx": idx, "hp": hp, "max_hp": hp}
	m._enemies.append(e)
	return e

func _test_the_board_is_laid_out() -> void:
	print("the board")
	var m := _make()
	expect(m._lives == m.START_LIVES and m._gold == m.START_GOLD, "lives and gold start where they should")
	expect(m._wave == 1, "on the first wave")
	expect(m._path_w.size() == m.PATH.size(), "the walking path has a waypoint per path tile")
	var marked := true
	for p: Vector2i in m.PATH:
		if m._grid[p.y][p.x] != 1:
			marked = false
	expect(marked, "and every path tile is marked as path on the grid")

func _test_a_tower_costs_gold_and_takes_a_tile() -> void:
	print("building")
	var m := _make()
	var tile := _free_tile(m)
	m._place_tower(_centre_of(m, tile))
	expect(m._towers.size() == 1, "a click on open ground builds a tower")
	expect(m._gold == m.START_GOLD - m.TOWER_COST, "and pays for it")
	expect(m._grid[tile.y][tile.x] == 2, "the tile is now occupied")

func _test_towers_cannot_be_built_on_the_path() -> void:
	print("keeping the path clear")
	var m := _make()
	m._place_tower(_centre_of(m, m.PATH[3]))
	expect(m._towers.is_empty(), "the path cannot be built on — it would block the route")
	expect(m._gold == m.START_GOLD, "and a refused build costs nothing")

func _test_towers_cannot_be_stacked() -> void:
	print("one per tile")
	var m := _make()
	var tile := _free_tile(m)
	m._place_tower(_centre_of(m, tile))
	m._place_tower(_centre_of(m, tile))
	expect(m._towers.size() == 1, "a second tower cannot go on an occupied tile")
	expect(m._gold == m.START_GOLD - m.TOWER_COST, "and is not charged for")

func _test_you_cannot_build_what_you_cannot_afford() -> void:
	print("going broke")
	var m := _make()
	m._gold = m.TOWER_COST - 1
	m._place_tower(_centre_of(m, _free_tile(m)))
	expect(m._towers.is_empty(), "one gold short is still short")
	expect(m._gold == m.TOWER_COST - 1, "and the gold is untouched")

	var over := _make()
	over._game_over = true
	over._place_tower(_centre_of(over, _free_tile(over)))
	expect(over._towers.is_empty(), "and nothing can be built after the game is lost")

func _test_clicks_off_the_board_are_ignored() -> void:
	print("off the board")
	var m := _make()
	m._place_tower(Vector2(-50.0, 100.0))
	m._place_tower(Vector2(100.0, m.GRID_H * m.TILE + 50.0))
	expect(m._towers.is_empty(), "clicks outside the grid build nothing")
	expect(m._gold == m.START_GOLD, "and cost nothing")

func _test_enemies_walk_the_path() -> void:
	print("marching")
	var m := _make()
	var e := _enemy_at(m, m._path_w[0], 0, 5)
	for i in 120:
		m._advance(e, STEP)
	expect(e["idx"] > 0, "the enemy works its way along the waypoints")
	expect(e["pos"] != m._path_w[0], "moving as it goes")

func _test_an_enemy_reaching_the_end_costs_a_life() -> void:
	print("a leak")
	var m := _make()
	var last: int = m._path_w.size() - 1
	var e := _enemy_at(m, m._path_w[last], last, 5)
	m._process(STEP)
	expect(m._lives == m.START_LIVES - 1, "an enemy off the end of the path costs a life")
	# Not "the list is empty" — the same frame also spawns the next enemy.
	expect(not m._enemies.has(e), "and is removed")

func _test_losing_every_life_ends_the_game() -> void:
	print("game over")
	var m := _make()
	m._lives = 1
	var last: int = m._path_w.size() - 1
	_enemy_at(m, m._path_w[last], last, 5)
	m._process(STEP)
	expect(m._game_over, "the last life lost ends the game")

	var lives_before: int = m._lives
	m._process(STEP)
	expect(m._lives == lives_before, "after which nothing carries on running")

func _test_killing_an_enemy_pays_out() -> void:
	print("bounty")
	var m := _make()
	var e := _enemy_at(m, m._path_w[2], 2, 0)
	var gold: int = m._gold
	m._process(STEP)
	expect(m._gold == gold + m.ENEMY_REWARD, "a dead enemy pays its reward")
	expect(not m._enemies.has(e), "and is cleared away")

func _test_a_tower_shoots_the_enemy_furthest_along() -> void:
	print("choosing a target")
	var m := _make()
	var here: Vector2 = m._path_w[5]
	# Two enemies on top of each other, one further along the path than the
	# other: shooting the leader is what stops leaks.
	var behind := _enemy_at(m, here, 3, 5)
	var ahead := _enemy_at(m, here, 9, 5)
	var target: Dictionary = m._best_target(here)
	expect(target == ahead, "the tower shoots whichever enemy is nearer the end")
	expect(target != behind, "not the one behind it")

	m._enemies.clear()
	var dying := _enemy_at(m, here, 9, 0)
	expect(m._best_target(here) != dying, "an enemy already at zero health is not worth a shot")

func _test_a_tower_ignores_enemies_out_of_range() -> void:
	print("range")
	var m := _make()
	var tower := Vector2(100.0, 100.0)
	_enemy_at(m, tower + Vector2(m.TOWER_RANGE + 40.0, 0.0), 4, 5)
	expect(m._best_target(tower).is_empty(), "an enemy beyond the tower's range is no target")
	_enemy_at(m, tower + Vector2(m.TOWER_RANGE - 10.0, 0.0), 4, 5)
	expect(not m._best_target(tower).is_empty(), "one inside it is")

func _test_an_idle_tower_holds_its_fire() -> void:
	print("holding fire")
	var m := _make()
	var tile := _free_tile(m)
	m._place_tower(_centre_of(m, tile))
	m._process(STEP)
	expect(m._bullets.is_empty(), "a tower with nothing in range does not shoot")
	expect(m._towers[0]["cd"] <= 0.0, "and keeps its cooldown ready for when something arrives")

func _test_bullets_wear_an_enemy_down() -> void:
	print("shooting")
	var m := _make()
	var tile := _free_tile(m)
	var tower_pos := _centre_of(m, tile)
	m._place_tower(tower_pos)
	var e := _enemy_at(m, tower_pos + Vector2(30.0, 0.0), 5, 3)
	var hp: int = e["hp"]
	for i in 60:
		m._process(STEP)
	expect(e["hp"] < hp, "a tower whittles down an enemy standing in range")
	expect(m._towers[0]["cd"] > 0.0, "and its cooldown is running between shots")

func _test_clearing_a_wave_starts_a_harder_one() -> void:
	print("waves")
	var m := _make()
	m._spawned = m._wave_size
	var size: int = m._wave_size
	m._process(STEP)
	expect(m._wave == 2, "clearing the field starts the next wave")
	expect(m._wave_size > size, "with more enemies in it")
	expect(m._spawned == 0, "and none of them spawned yet")

	m._spawn_enemy()
	expect(m._enemies[0]["hp"] > 3, "later waves send tougher enemies")
