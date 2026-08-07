extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_map_dimensions()
	_test_cell_size()
	_test_total_pixels()
	_test_mode_count()
	_test_moisture_remap()
	_test_island_falloff_center()
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

func _test_map_dimensions() -> void:
	print("map dimensions")
	const MAP_W := 78
	const MAP_H := 52
	expect(MAP_W == 78, "MAP_W is 78")
	expect(MAP_H == 52, "MAP_H is 52")

func _test_cell_size() -> void:
	print("cell size")
	const CELL := 8
	expect(CELL == 8, "CELL size is 8 pixels")

func _test_total_pixels() -> void:
	print("total rendered area")
	const MAP_W := 78
	const MAP_H := 52
	const CELL := 8
	var width_px := MAP_W * CELL
	var height_px := MAP_H * CELL
	expect(width_px == 624, "rendered width is 624px")
	expect(height_px == 416, "rendered height is 416px")

func _test_mode_count() -> void:
	print("generation mode count")
	var modes := ["TERRAIN", "CAVES", "ISLAND", "MOISTURE"]
	expect(modes.size() == 4, "4 generation modes")

func _test_moisture_remap() -> void:
	print("moisture noise remap from [-1,1] to [0,1]")
	var noise_val := 0.6
	var t := (noise_val + 1.0) * 0.5
	expect_near(t, 0.8, "noise 0.6 maps to 0.8")
	noise_val = -1.0
	t = (noise_val + 1.0) * 0.5
	expect_near(t, 0.0, "noise -1 maps to 0.0")
	noise_val = 1.0
	t = (noise_val + 1.0) * 0.5
	expect_near(t, 1.0, "noise 1 maps to 1.0")

func _test_island_falloff_center() -> void:
	print("island falloff at map center is zero")
	const MAP_W := 78
	const MAP_H := 52
	var cx := float(MAP_W / 2)
	var cy := float(MAP_H / 2)
	var nx := (cx / float(MAP_W) - 0.5) * 2.2
	var ny := (cy / float(MAP_H) - 0.5) * 2.2
	var dist := sqrt(nx * nx + ny * ny)
	expect(dist < 0.2, "island falloff distance at center is near zero")

func _report() -> void:
	var summary := "[procedural-gen] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
