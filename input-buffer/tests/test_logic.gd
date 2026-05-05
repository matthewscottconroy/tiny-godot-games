extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_attack_fires_when_ready()
	test_attack_blocked_during_cooldown()
	test_buffer_queues_during_cooldown()
	test_buffer_fires_when_cooldown_clears()
	test_buffer_expires_without_firing()
	test_cooldown_decrements()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[input-buffer] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const ATTACK_COOLDOWN := 0.5
const BUFFER_WINDOW   := 0.18

func _tick(cooldown: float, buffer: float, pressed: bool, delta: float) -> Dictionary:
	var cd := maxf(cooldown - delta, 0.0)
	var buf := maxf(buffer  - delta, 0.0)
	if pressed:
		buf = BUFFER_WINDOW
	var fired := false
	if buf > 0.0 and cd == 0.0:
		fired = true
		cd    = ATTACK_COOLDOWN
		buf   = 0.0
	return {"cooldown": cd, "buffer": buf, "fired": fired}

func test_attack_fires_when_ready() -> void:
	var r := _tick(0.0, 0.0, true, 0.016)
	expect(r["fired"], "attack fires immediately when cooldown is 0 and pressed")

func test_attack_blocked_during_cooldown() -> void:
	var r := _tick(0.3, 0.0, true, 0.016)
	# buffer set, but cooldown not clear yet
	expect(not r["fired"], "attack doesn't fire during cooldown even with press")
	expect(r["buffer"] > 0.0, "press sets buffer even during cooldown")

func test_buffer_queues_during_cooldown() -> void:
	var r := _tick(0.3, 0.0, true, 0.016)
	expect(r["buffer"] > 0.0, "buffer accumulates when pressed during cooldown")

func test_buffer_fires_when_cooldown_clears() -> void:
	# Frame 1: press during cooldown
	var r1 := _tick(0.016, 0.0, true, 0.016)
	expect(not r1["fired"], "doesn't fire on frame cooldown expires (cd tick before check)")
	# Frame 2: cooldown now 0, buffer still active
	var r2 := _tick(r1["cooldown"], r1["buffer"], false, 0.016)
	expect(r2["fired"], "fires on next frame when cooldown clears with buffer active")

func test_buffer_expires_without_firing() -> void:
	# Press during long cooldown, wait for buffer to expire
	var r := _tick(0.5, 0.0, true, 0.016)   # press; buffer = 0.18
	var buf := r["buffer"]
	# Drain buffer without clearing cooldown
	var cd := r["cooldown"]
	for i in 15:
		var s := _tick(cd, buf, false, 0.016)
		cd = s["cooldown"]
		buf = s["buffer"]
	expect(buf == 0.0, "buffer expires after enough frames")
	# Cooldown still active, no fire
	expect(cd > 0.0, "cooldown still running when buffer expired")

func test_cooldown_decrements() -> void:
	var r := _tick(0.5, 0.0, false, 0.1)
	expect(absf(r["cooldown"] - 0.4) < 0.001, "cooldown decrements by delta each tick")
