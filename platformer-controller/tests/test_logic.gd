extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_coyote_resets_on_floor()
	test_coyote_decrements_in_air()
	test_coyote_clamps_to_zero()
	test_buffer_set_on_press()
	test_buffer_clamps_to_zero()
	test_jump_consumes_both_timers()
	test_no_jump_without_coyote()
	test_no_jump_without_buffer()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[platformer-controller] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.10

func _tick_coyote(c: float, on_floor: bool, delta: float) -> float:
	return COYOTE_TIME if on_floor else maxf(c - delta, 0.0)

func _tick_buffer(b: float, pressed: bool, delta: float) -> float:
	var nb := JUMP_BUFFER if pressed else b
	return maxf(nb - delta, 0.0)

func _try_jump(coyote: float, buffer: float) -> Dictionary:
	if buffer > 0.0 and coyote > 0.0:
		return {"jumped": true, "coyote": 0.0, "buffer": 0.0}
	return {"jumped": false, "coyote": coyote, "buffer": buffer}

func test_coyote_resets_on_floor() -> void:
	var c := _tick_coyote(0.0, true, 0.016)
	expect(c == COYOTE_TIME, "coyote resets to full when on floor")

func test_coyote_decrements_in_air() -> void:
	var c := _tick_coyote(0.12, false, 0.016)
	expect(c < 0.12 and c > 0.0, "coyote decrements in air")

func test_coyote_clamps_to_zero() -> void:
	var c := _tick_coyote(0.01, false, 1.0)
	expect(c == 0.0, "coyote clamps to 0 when expired")

func test_buffer_set_on_press() -> void:
	var b := _tick_buffer(0.0, true, 0.0)
	expect(b == JUMP_BUFFER, "buffer set to full on press")

func test_buffer_clamps_to_zero() -> void:
	var b := _tick_buffer(0.01, false, 1.0)
	expect(b == 0.0, "buffer clamps to 0 when expired")

func test_jump_consumes_both_timers() -> void:
	var r := _try_jump(0.1, 0.05)
	expect(r["jumped"], "jump fires when coyote+buffer both active")
	expect(r["coyote"] == 0.0, "coyote cleared after jump")
	expect(r["buffer"] == 0.0, "buffer cleared after jump")

func test_no_jump_without_coyote() -> void:
	var r := _try_jump(0.0, 0.08)
	expect(not r["jumped"], "no jump when coyote expired")

func test_no_jump_without_buffer() -> void:
	var r := _try_jump(0.10, 0.0)
	expect(not r["jumped"], "no jump when buffer expired")
