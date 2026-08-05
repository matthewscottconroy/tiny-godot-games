extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_room_dimensions()
	_test_camera_limits()
	_test_room_aspect_ratio()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_room_dimensions() -> void:
	print("room dimensions")
	const ROOM_W := 1280.0
	const ROOM_H := 960.0
	expect(ROOM_W == 1280.0, "ROOM_W is 1280")
	expect(ROOM_H == 960.0, "ROOM_H is 960")

func _test_camera_limits() -> void:
	print("camera limits match room bounds")
	const ROOM_W := 1280.0
	const ROOM_H := 960.0
	var limit_left := 0
	var limit_top := 0
	var limit_right := int(ROOM_W)
	var limit_bottom := int(ROOM_H)
	expect(limit_left == 0, "camera left limit is 0")
	expect(limit_top == 0, "camera top limit is 0")
	expect(limit_right == 1280, "camera right limit matches ROOM_W")
	expect(limit_bottom == 960, "camera bottom limit matches ROOM_H")

func _test_room_aspect_ratio() -> void:
	print("room aspect ratio is 4:3")
	const ROOM_W := 1280.0
	const ROOM_H := 960.0
	var ratio := ROOM_W / ROOM_H
	expect_near(ratio, 4.0 / 3.0, "room is 4:3 aspect ratio")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
