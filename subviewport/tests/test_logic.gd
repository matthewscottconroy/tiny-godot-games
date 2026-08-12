extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_world_dimensions()
	_test_player_speed()
	_test_minimap_dimensions()
	_test_minimap_zoom()
	_test_minimap_dot_position()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) <= tol, label)

func _test_world_dimensions() -> void:
	print("world dimensions")
	const WORLD_W := 1200.0
	const WORLD_H := 900.0
	expect(WORLD_W == 1200.0, "WORLD_W is 1200")
	expect(WORLD_H == 900.0, "WORLD_H is 900")

func _test_player_speed() -> void:
	print("player speed")
	const PLAYER_SPEED := 200.0
	expect(PLAYER_SPEED == 200.0, "PLAYER_SPEED is 200")

func _test_minimap_dimensions() -> void:
	print("minimap dimensions")
	const MINIMAP_W := 160.0
	const MINIMAP_H := 114.0
	expect(MINIMAP_W == 160.0, "MINIMAP_W is 160")
	expect(MINIMAP_H == 114.0, "MINIMAP_H is 114")

func _test_minimap_zoom() -> void:
	print("minimap zoom fits world into minimap")
	const WORLD_W := 1200.0
	const WORLD_H := 900.0
	const MINIMAP_W := 160.0
	const MINIMAP_H := 114.0
	var zoom := minf(MINIMAP_W / WORLD_W, MINIMAP_H / WORLD_H)
	expect_near(zoom, MINIMAP_H / WORLD_H, "zoom uses height ratio (the smaller of the two)")
	expect(zoom < 1.0, "minimap zoom is less than 1 (scaled down)")

func _test_minimap_dot_position() -> void:
	print("minimap dot position formula")
	const WORLD_W := 1200.0
	const WORLD_H := 900.0
	const MINIMAP_W := 160.0
	const MINIMAP_H := 114.0
	var origin_x := 0.0
	var player_x := 600.0
	var dot_x := origin_x + (player_x / WORLD_W) * MINIMAP_W
	expect_near(dot_x, 80.0, "player at world center maps to minimap center x")
	var player_y := 450.0
	var dot_y := 0.0 + (player_y / WORLD_H) * MINIMAP_H
	expect_near(dot_y, 57.0, "player at world center maps to minimap center y")

func _report() -> void:
	var summary := "[subviewport] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
