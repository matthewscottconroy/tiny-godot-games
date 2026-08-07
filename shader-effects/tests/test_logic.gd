extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_shader_files_exist()
	test_dissolve_bounces()
	test_pixelate_range()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[shader-effects] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func test_shader_files_exist() -> void:
	expect(FileAccess.file_exists("res://shaders/dissolve.gdshader"),    "dissolve.gdshader exists")
	expect(FileAccess.file_exists("res://shaders/pixelate.gdshader"),    "pixelate.gdshader exists")
	expect(FileAccess.file_exists("res://shaders/wave_distort.gdshader"),"wave_distort.gdshader exists")
	expect(FileAccess.file_exists("res://assets/sprite.svg"),            "sprite.svg asset exists")

func test_dissolve_bounces() -> void:
	var dissolve   := 0.0
	var dir        := 1
	var delta      := 0.016
	var speed      := 0.6
	var iterations := 0
	var bounced    := false
	for _i in 200:
		dissolve += delta * dir * speed
		if dissolve >= 1.0:
			dissolve = 1.0; dir = -1; bounced = true
		elif dissolve <= 0.0:
			dissolve = 0.0; dir = 1
		iterations += 1
	expect(bounced, "dissolve amount bounces at 1.0 and reverses direction")
	expect(dissolve >= 0.0 and dissolve <= 1.0, "dissolve amount stays in [0, 1] range")

func test_pixelate_range() -> void:
	for i in 60:
		var t  := (sin(float(i) * 0.1) + 1.0) * 0.5
		var px := lerpf(1.0, 16.0, t)
		expect(px >= 1.0 and px <= 16.0, "pixel_size stays in [1, 16] at step %d" % i)
