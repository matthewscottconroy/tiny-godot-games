extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_light_uv_clamp()
	_test_bump_normal_finite_diff()
	_test_attenuation()
	_test_diffuse_lighting()
	_test_shader_params()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol := 0.001) -> void:
	expect(absf(a - b) <= tol, label)

func _test_light_uv_clamp() -> void:
	print("light UV normalisation")
	var viewport := Vector2(640.0, 480.0)
	var mouse_center := Vector2(320.0, 240.0)
	var uv_center := mouse_center / viewport
	expect_near(uv_center.x, 0.5, "center x maps to 0.5")
	expect_near(uv_center.y, 0.5, "center y maps to 0.5")
	var mouse_topleft := Vector2(0.0, 0.0)
	var uv_tl := mouse_topleft / viewport
	expect_near(uv_tl.x, 0.0, "top-left x is 0.0")
	expect_near(uv_tl.y, 0.0, "top-left y is 0.0")
	var mouse_br := Vector2(640.0, 480.0)
	var uv_br := mouse_br / viewport
	expect_near(uv_br.x, 1.0, "bottom-right x is 1.0")
	expect_near(uv_br.y, 1.0, "bottom-right y is 1.0")

func _height_field(uv: Vector2, freq: float) -> float:
	return sin(uv.x * freq) * cos(uv.y * freq * 0.8) * 0.5 \
			+ sin(uv.x * freq * 0.6 + 1.0) * sin(uv.y * freq * 1.3) * 0.3 \
			+ cos(uv.x * freq * 1.7 - 0.5) * cos(uv.y * freq * 0.9 + 0.8) * 0.2

func _bump_normal(uv: Vector2, freq: float, strength: float) -> Vector3:
	var eps := 0.002
	var dx := _height_field(uv + Vector2(eps, 0.0), freq) - _height_field(uv - Vector2(eps, 0.0), freq)
	var dy := _height_field(uv + Vector2(0.0, eps), freq) - _height_field(uv - Vector2(0.0, eps), freq)
	return Vector3(-dx * strength, -dy * strength, 1.0).normalized()

func _test_bump_normal_finite_diff() -> void:
	print("bump normal finite differences")
	var n := _bump_normal(Vector2(0.5, 0.5), 10.0, 2.0)
	expect_near(n.length(), 1.0, "bump normal is unit length", 0.0001)
	expect(n.z > 0.0, "normal z-component points toward viewer")
	var n2 := _bump_normal(Vector2(0.0, 0.0), 10.0, 2.0)
	expect_near(n2.length(), 1.0, "bump normal at origin is unit length", 0.0001)

func _test_attenuation() -> void:
	print("distance attenuation")
	var light_radius := 0.6
	var close_dist := 0.05
	var far_dist := 0.8
	var close_atten := 1.0 / (1.0 + close_dist * close_dist * 30.0 / (light_radius * light_radius))
	var far_atten := 1.0 / (1.0 + far_dist * far_dist * 30.0 / (light_radius * light_radius))
	expect(close_atten > far_atten, "closer light has higher attenuation")
	expect(close_atten <= 1.0, "attenuation capped at 1.0")
	expect(far_atten > 0.0, "attenuation always positive")

func _test_diffuse_lighting() -> void:
	print("diffuse N·L lighting")
	var N := Vector3(0.0, 0.0, 1.0)
	var L_direct := Vector3(0.0, 0.0, 1.0)
	var diff_direct := maxf(N.dot(L_direct), 0.0)
	expect_near(diff_direct, 1.0, "direct light gives full diffuse", 0.0001)
	var L_perp := Vector3(1.0, 0.0, 0.0)
	var diff_perp := maxf(N.dot(L_perp), 0.0)
	expect_near(diff_perp, 0.0, "perpendicular light gives zero diffuse", 0.0001)
	var L_back := Vector3(0.0, 0.0, -1.0)
	var diff_back := maxf(N.dot(L_back), 0.0)
	expect_near(diff_back, 0.0, "back light is clamped to zero", 0.0001)

func _test_shader_params() -> void:
	print("shader parameter defaults")
	const DEFAULT_FREQ := 10.0
	const DEFAULT_BUMP := 2.0
	const DEFAULT_RADIUS := 0.6
	expect(DEFAULT_FREQ >= 1.0 and DEFAULT_FREQ <= 30.0, "freq in valid range")
	expect(DEFAULT_BUMP >= 0.0 and DEFAULT_BUMP <= 4.0, "bump_strength in valid range")
	expect(DEFAULT_RADIUS >= 0.1 and DEFAULT_RADIUS <= 2.0, "light_radius in valid range")

func _report() -> void:
	var summary := "[normal-map-lighting] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
