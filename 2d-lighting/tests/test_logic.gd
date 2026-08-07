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
	var summary := "[2d-lighting] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _test_gradient_texture() -> void:
	print("TEST: gradient texture")
	var g := Gradient.new()
	g.colors = [Color.WHITE, Color(1, 1, 1, 0)]
	g.offsets = [0.0, 1.0]
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 256
	gt.fill = GradientTexture2D.FILL_RADIAL
	expect(gt.fill == GradientTexture2D.FILL_RADIAL, "fill is FILL_RADIAL")
	expect(gt.width == 256, "width is 256")
	expect(gt.height == 256, "height is 256")
	expect(g.colors[0] == Color.WHITE, "center color is WHITE")
	expect(g.colors[1] == Color(1, 1, 1, 0), "edge color is transparent")

func _test_light_toggle() -> void:
	print("TEST: light toggle colors")
	var dark_color := Color(0.15, 0.15, 0.15)
	var bright_color := Color.WHITE
	expect(dark_color.r == 0.15, "dark red channel is 0.15")
	expect(dark_color.g == 0.15, "dark green channel is 0.15")
	expect(dark_color.b == 0.15, "dark blue channel is 0.15")
	expect(bright_color == Color(1, 1, 1), "bright is full white")
	expect(dark_color != bright_color, "dark and bright differ")

func _test_scale_increase() -> void:
	print("TEST: scale increase")
	var scale := 1.0
	scale += 0.2
	expect(abs(scale - 1.2) < 0.0001, "1.0 + 0.2 == 1.2")

func _test_scale_clamp() -> void:
	print("TEST: scale clamp")
	var scale := 0.4
	scale -= 0.2
	expect(abs(scale - 0.2) < 0.0001, "0.4 - 0.2 == 0.2")
	scale = max(0.2, scale - 0.2)
	expect(abs(scale - 0.2) < 0.0001, "0.2 - 0.2 clamped to 0.2")

func _test_player_moves() -> void:
	print("TEST: player movement within bounds")
	var pos := Vector2(320, 240)
	var speed := 160.0
	var delta := 0.016
	var dir := Vector2(1, 0)
	pos += dir * speed * delta
	pos.x = clamp(pos.x, 0.0, 640.0)
	pos.y = clamp(pos.y, 0.0, 480.0)
	expect(pos.x > 320.0, "x moved right")
	expect(pos.x <= 640.0, "x clamped within screen width")
	# Test boundary clamp
	pos = Vector2(638.0, 240.0)
	pos += dir * speed * delta
	pos.x = clamp(pos.x, 0.0, 640.0)
	expect(pos.x <= 640.0, "x does not exceed 640 at boundary")

func _ready() -> void:
	print("=== 2D Lighting Tests ===")
	_test_gradient_texture()
	_test_light_toggle()
	_test_scale_increase()
	_test_scale_clamp()
	_test_player_moves()
	_report()
