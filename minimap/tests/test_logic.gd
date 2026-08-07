extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_world_to_map_origin()
	_test_world_to_map_corner()
	_test_world_to_map_midpoint()
	_test_camera_clamp_low()
	_test_camera_clamp_high()
	_test_camera_clamp_middle()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx(a: float, b: float, label: String, tol: float = 0.5) -> void:
	expect(absf(a - b) < tol, label)

# --- minimap coordinate scaling ---

const WORLD_W := 2000.0
const WORLD_H := 480.0
const MAP_RECT := Rect2(460, 10, 170, 100)

func world_to_map(world_pos: Vector2) -> Vector2:
	return MAP_RECT.position + world_pos / Vector2(WORLD_W, WORLD_H) * MAP_RECT.size

func _test_world_to_map_origin() -> void:
	print("world_to_map: origin maps to MAP_RECT.position")
	var result := world_to_map(Vector2.ZERO)
	expect_approx(result.x, MAP_RECT.position.x, "origin x = MAP_RECT.position.x")
	expect_approx(result.y, MAP_RECT.position.y, "origin y = MAP_RECT.position.y")

func _test_world_to_map_corner() -> void:
	print("world_to_map: world corner maps to MAP_RECT corner")
	var result := world_to_map(Vector2(WORLD_W, WORLD_H))
	var expected := MAP_RECT.position + MAP_RECT.size
	expect_approx(result.x, expected.x, "world corner x = MAP_RECT end.x")
	expect_approx(result.y, expected.y, "world corner y = MAP_RECT end.y")

func _test_world_to_map_midpoint() -> void:
	print("world_to_map: world midpoint maps to MAP_RECT center")
	var result := world_to_map(Vector2(WORLD_W * 0.5, WORLD_H * 0.5))
	var expected := MAP_RECT.position + MAP_RECT.size * 0.5
	expect_approx(result.x, expected.x, "midpoint x maps to map center x")
	expect_approx(result.y, expected.y, "midpoint y maps to map center y")

# --- camera clamp logic ---

func camera_clamp_x(player_x: float) -> float:
	return clampf(player_x, 320.0, WORLD_W - 320.0)

func _test_camera_clamp_low() -> void:
	print("camera clamp: player near left edge")
	expect_approx(camera_clamp_x(0.0), 320.0, "clamped to 320 at left edge")

func _test_camera_clamp_high() -> void:
	print("camera clamp: player near right edge")
	expect_approx(camera_clamp_x(WORLD_W), WORLD_W - 320.0, "clamped at right edge")

func _test_camera_clamp_middle() -> void:
	print("camera clamp: player in middle passes through")
	var mid := WORLD_W * 0.5
	expect_approx(camera_clamp_x(mid), mid, "midpoint passes through unmodified")

func _report() -> void:
	var summary := "[minimap] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
