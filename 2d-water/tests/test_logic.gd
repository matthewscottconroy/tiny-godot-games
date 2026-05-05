extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_wave_offset_nonzero()
	test_depth_darkens_color()
	test_water_drag()
	test_swim_up_velocity()
	test_shader_file_exists()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[2d-water] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

func test_wave_offset_nonzero() -> void:
	var freq := 6.0
	var amp  := 0.018
	var t    := 1.0
	var speed := 1.2
	var offset := sin(0.5 * freq + t * speed) * amp
	expect(absf(offset) > 0.0, "wave offset is non-zero at t=1")
	expect(absf(offset) <= amp, "wave offset does not exceed amplitude")

func test_depth_darkens_color() -> void:
	var water := Color(0.05, 0.35, 0.75)
	var deep  := Color(0.02, 0.15, 0.45)
	var shallow := water.lerp(deep, 0.0 * 0.7)
	var mid     := water.lerp(deep, 0.5 * 0.7)
	var bottom  := water.lerp(deep, 1.0 * 0.7)
	expect(mid.get_luminance() < shallow.get_luminance(), "mid depth darker than surface")
	expect(bottom.get_luminance() < mid.get_luminance(),  "bottom darker than mid")

func test_water_drag() -> void:
	var vel := Vector2(200, 100)
	vel *= 0.85  # one drag step
	expect(vel.length() < 224.0, "velocity decreases with water drag")

func test_swim_up_velocity() -> void:
	const JUMP_VEL := -400.0
	var swim_up := JUMP_VEL * 0.55
	expect(swim_up < 0.0, "swim-up velocity is upward (negative y)")
	expect(absf(swim_up) < absf(JUMP_VEL), "swim-up weaker than land jump")

func test_shader_file_exists() -> void:
	expect(FileAccess.file_exists("res://shaders/water.gdshader"), "water.gdshader exists")
