extends Node

var _pass := 0
var _fail := 0

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[pixel-art-camera] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# --- Constants ---
const WORLD_W := 160.0
const WORLD_H := 120.0
const TILE_SIZE := 8.0
const DISPLAY_W := 640.0
const DISPLAY_H := 480.0

# --- Logic helpers ---

func _wrap_pos(pos: Vector2) -> Vector2:
	return Vector2(fposmod(pos.x, WORLD_W), fposmod(pos.y, WORLD_H))

func _checkerboard_color(col: int, row: int) -> int:
	# Returns 0 or 1 for the two tile colors
	return (col + row) % 2

# --- Tests ---

func _test_pixel_scale() -> void:
	var scale_x: int = int(DISPLAY_W / WORLD_W)
	var scale_y: int = int(DISPLAY_H / WORLD_H)
	expect(scale_x == 4, "pixel_scale: 640 / 160 = 4x scale factor")
	expect(scale_y == 4, "pixel_scale: 480 / 120 = 4x scale factor")

func _test_world_wrap() -> void:
	var pos := Vector2(165.0, 130.0)
	var wrapped := _wrap_pos(pos)
	expect(abs(wrapped.x - 5.0) < 0.001, "world_wrap: x=165 wraps to x=5")
	expect(abs(wrapped.y - 10.0) < 0.001, "world_wrap: y=130 wraps to y=10")

func _test_world_wrap_negative() -> void:
	var pos := Vector2(-5.0, -10.0)
	var wrapped := _wrap_pos(pos)
	expect(abs(wrapped.x - 155.0) < 0.001, "world_wrap: x=-5 wraps to x=155")
	expect(abs(wrapped.y - 110.0) < 0.001, "world_wrap: y=-10 wraps to y=110")

func _test_checkerboard() -> void:
	# (0,0): (0+0)%2 = 0 → color A
	expect(_checkerboard_color(0, 0) == 0, "checkerboard: (0,0) → color index 0")
	# (1,0): (1+0)%2 = 1 → color B
	expect(_checkerboard_color(1, 0) == 1, "checkerboard: (1,0) → color index 1")
	# (1,1): (1+1)%2 = 0 → color A
	expect(_checkerboard_color(1, 1) == 0, "checkerboard: (1,1) → color index 0")

func _test_tile_count() -> void:
	var cols: int = int(WORLD_W / TILE_SIZE)
	var rows: int = int(WORLD_H / TILE_SIZE)
	expect(cols == 20, "tile_count: 160 / 8 = 20 columns")
	expect(rows == 15, "tile_count: 120 / 8 = 15 rows")
	expect(cols * rows == 300, "tile_count: 20 * 15 = 300 total tiles")

func _ready() -> void:
	print("=== Pixel Art Camera Tests ===")
	_test_pixel_scale()
	_test_world_wrap()
	_test_world_wrap_negative()
	_test_checkerboard()
	_test_tile_count()
	_report()
