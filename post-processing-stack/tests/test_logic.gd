extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_vignette_formula()
	_test_chromatic_aberration()
	_test_color_grading()
	_test_effect_toggling()
	_test_corner_vignette()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol := 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _vignette(uv: Vector2, strength: float) -> float:
	var center := uv - Vector2(0.5, 0.5)
	var vig := 1.0 - center.dot(center) * strength * 3.8
	return clampf(vig, 0.0, 1.0)

func _test_vignette_formula() -> void:
	print("vignette formula")
	var center_vig := _vignette(Vector2(0.5, 0.5), 1.4)
	expect_near(center_vig, 1.0, "vignette is 1.0 at screen center", 0.001)
	var edge_vig := _vignette(Vector2(0.0, 0.5), 1.4)
	expect(edge_vig < center_vig, "vignette darker at edge than center")
	expect(edge_vig >= 0.0, "vignette non-negative at edge")

func _test_corner_vignette() -> void:
	print("vignette at corners")
	var corner := _vignette(Vector2(0.0, 0.0), 1.4)
	expect(corner < 0.5, "corner heavily vignetted")
	var opposite := _vignette(Vector2(1.0, 1.0), 1.4)
	expect_near(corner, opposite, "vignette symmetric at opposite corners", 0.001)

func _test_chromatic_aberration() -> void:
	print("chromatic aberration offset")
	var uv := Vector2(0.8, 0.3)
	var chroma_str := 0.006
	var offset := (uv - Vector2(0.5, 0.5)) * chroma_str
	expect(offset.length() > 0.0, "offset non-zero away from center")
	var center_offset := (Vector2(0.5, 0.5) - Vector2(0.5, 0.5)) * chroma_str
	expect_near(center_offset.length(), 0.0, "no offset at screen center")
	var r_uv := uv + offset
	var b_uv := uv - offset
	expect(r_uv.distance_to(b_uv) > 0.0, "red and blue channels sample different positions")

func _test_color_grading() -> void:
	print("color grading")
	var grade_tint := Vector3(1.05, 0.95, 0.88)
	var gamma := 0.94
	var col := Vector3(0.5, 0.5, 0.5)
	col = Vector3(col.x * grade_tint.x, col.y * grade_tint.y, col.z * grade_tint.z)
	col = Vector3(pow(col.x, gamma), pow(col.y, gamma), pow(col.z, gamma))
	expect(col.x > col.y, "warm tint: red channel boosted above green")
	expect(col.y > col.z, "warm tint: green channel above blue")
	expect(col.x <= 1.0 and col.y <= 1.0 and col.z <= 1.0, "graded values within range")

func _test_effect_toggling() -> void:
	print("effect toggling")
	var effects := {"vignette": true, "chroma": true, "grade": true}
	effects["vignette"] = not effects["vignette"]
	expect(not effects["vignette"], "vignette toggled off")
	effects["vignette"] = not effects["vignette"]
	expect(effects["vignette"], "vignette toggled back on")
	effects["chroma"] = false
	effects["grade"] = false
	expect(not effects["chroma"] and not effects["grade"], "both effects off simultaneously")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
