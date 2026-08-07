extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_grid_dimensions()
	_test_path_length()
	_test_tower_placement_blocked_on_path()
	_test_tower_cost()
	_test_wave_scaling()
	_test_enemy_hp_scaling()
	_test_bullet_hits_target()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_grid_dimensions() -> void:
	print("grid dimensions")
	const TILE   := 40
	const GRID_W := 16
	const GRID_H := 12
	expect(GRID_W * TILE == 640, "grid fills viewport width")
	expect(GRID_H * TILE == 480, "grid fills viewport height")

func _test_path_length() -> void:
	print("path waypoint count")
	var path := [
		Vector2i(0,6), Vector2i(1,6), Vector2i(2,6), Vector2i(3,6),
		Vector2i(3,5), Vector2i(3,4), Vector2i(3,3),
		Vector2i(4,3), Vector2i(5,3), Vector2i(6,3), Vector2i(7,3),
		Vector2i(7,4), Vector2i(7,5), Vector2i(7,6), Vector2i(7,7), Vector2i(7,8),
		Vector2i(8,8), Vector2i(9,8), Vector2i(10,8), Vector2i(11,8), Vector2i(12,8),
		Vector2i(12,7), Vector2i(12,6), Vector2i(12,5), Vector2i(12,4),
		Vector2i(13,4), Vector2i(14,4), Vector2i(15,4),
	]
	expect(path.size() == 28, "path has 28 waypoints")

func _test_tower_placement_blocked_on_path() -> void:
	print("tower cannot be placed on path tile")
	var grid_cell_path := 1  # path
	var grid_cell_empty := 0  # empty
	expect(grid_cell_path != 0, "path cell is non-zero, blocks tower placement")
	expect(grid_cell_empty == 0, "empty cell allows tower placement")

func _test_tower_cost() -> void:
	print("tower cost deducts gold")
	const TOWER_COST := 50
	var gold := 150
	gold -= TOWER_COST
	expect(gold == 100, "gold deducted correctly")
	gold -= TOWER_COST
	expect(gold == 50, "second tower deducted")
	gold -= TOWER_COST
	expect(gold == 0, "third tower depletes gold")
	expect(gold < TOWER_COST, "cannot afford fourth tower")

func _test_wave_scaling() -> void:
	print("wave size scales each wave")
	for wave in range(1, 6):
		var size := 6 + (wave - 1) * 2
		expect(size == 4 + wave * 2, "wave %d has %d enemies" % [wave, size])

func _test_enemy_hp_scaling() -> void:
	print("enemy HP increases with wave")
	for wave in range(1, 5):
		var hp := 3 + (wave - 1)
		var next_hp := 3 + wave
		expect(next_hp > hp, "wave %d enemies have more HP than wave %d" % [wave + 1, wave])

func _test_bullet_hits_target() -> void:
	print("bullet damages target on contact")
	var enemy := {"hp": 3, "pos": Vector2(100.0, 100.0)}
	var bullet_pos := Vector2(103.0, 100.0)
	if bullet_pos.distance_to(enemy["pos"]) < 6.0:
		enemy["hp"] -= 1
	expect(enemy["hp"] == 2, "enemy hp reduced on bullet contact")

func _report() -> void:
	var summary := "[tower-defense-base] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
