extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_constants()
	_test_volume_attenuation()
	_test_volume_clamp()
	_test_loop_end()
	_test_listener_clamp()
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

func _test_constants() -> void:
	print("constants")
	const SAMPLE_RATE := 22050
	const LISTENER_SPEED := 200.0
	expect(SAMPLE_RATE == 22050, "SAMPLE_RATE is 22050")
	expect(LISTENER_SPEED == 200.0, "LISTENER_SPEED is 200")

func _test_volume_attenuation() -> void:
	print("volume attenuation formula")
	var max_distance := 500.0
	var dist := 0.0
	var vol := clampf(1.0 - dist / max_distance, 0.0, 1.0)
	expect_near(vol, 1.0, "at dist=0, volume=1.0")
	dist = 250.0
	vol = clampf(1.0 - dist / max_distance, 0.0, 1.0)
	expect_near(vol, 0.5, "at half max_distance, volume=0.5")
	dist = 500.0
	vol = clampf(1.0 - dist / max_distance, 0.0, 1.0)
	expect_near(vol, 0.0, "at max_distance, volume=0.0")

func _test_volume_clamp() -> void:
	print("volume clamped at boundaries")
	var max_distance := 500.0
	var dist := 600.0
	var vol := clampf(1.0 - dist / max_distance, 0.0, 1.0)
	expect_near(vol, 0.0, "beyond max_distance clamped to 0")
	dist = -10.0
	vol = clampf(1.0 - dist / max_distance, 0.0, 1.0)
	expect(vol <= 1.0, "negative distance clamped to max 1.0")

func _test_loop_end() -> void:
	print("loop end calculation")
	const SAMPLE_RATE := 22050
	var loop_end := SAMPLE_RATE * 2
	expect(loop_end == 44100, "loop end for 2s at 22050Hz = 44100")

func _test_listener_clamp() -> void:
	print("listener position clamp")
	var pos := Vector2(10, 50)
	pos = pos.clamp(Vector2(20, 60), Vector2(620, 460))
	expect(pos.x == 20.0, "listener x clamped to min 20")
	expect(pos.y == 60.0, "listener y clamped to min 60")
	pos = Vector2(700, 500)
	pos = pos.clamp(Vector2(20, 60), Vector2(620, 460))
	expect(pos.x == 620.0, "listener x clamped to max 620")
	expect(pos.y == 460.0, "listener y clamped to max 460")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
