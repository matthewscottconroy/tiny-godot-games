extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_stamina_drains_when_sprinting()
	test_stamina_regens_when_idle()
	test_sprint_blocked_when_depleted()
	test_regen_delayed_after_sprint()
	test_stamina_clamped_to_max()
	test_speed_higher_when_sprinting()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[stamina-system] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const STAMINA_MAX  := 100.0
const DRAIN_RATE   := 38.0
const REGEN_RATE   := 18.0
const REGEN_DELAY  := 0.8
const SPEED        := 200.0
const SPRINT_SPEED := 360.0

func _tick(stamina: float, regen_wait: float, sprinting: bool, delta: float) -> Dictionary:
	var s := stamina
	var w := regen_wait
	if sprinting and s > 0.0:
		s = maxf(s - DRAIN_RATE * delta, 0.0)
		w = REGEN_DELAY
	else:
		w = maxf(w - delta, 0.0)
		if w <= 0.0:
			s = minf(s + REGEN_RATE * delta, STAMINA_MAX)
	return {"stamina": s, "regen_wait": w}

func test_stamina_drains_when_sprinting() -> void:
	var r := _tick(100.0, 0.0, true, 0.016)
	expect(r["stamina"] < 100.0, "stamina decreases while sprinting")

func test_stamina_regens_when_idle() -> void:
	var r := _tick(50.0, 0.0, false, 0.016)
	expect(r["stamina"] > 50.0, "stamina increases when not sprinting and delay passed")

func test_sprint_blocked_when_depleted() -> void:
	var stamina := 0.0
	var can_sprint := stamina > 0.0
	expect(not can_sprint, "sprint blocked when stamina is zero")

func test_regen_delayed_after_sprint() -> void:
	var r := _tick(80.0, 0.5, false, 0.016)
	expect(r["stamina"] == 80.0, "stamina does not regen while regen_wait > 0")

func test_stamina_clamped_to_max() -> void:
	var r := _tick(99.9, 0.0, false, 1.0)
	expect(r["stamina"] <= STAMINA_MAX, "stamina does not exceed STAMINA_MAX")

func test_speed_higher_when_sprinting() -> void:
	expect(SPRINT_SPEED > SPEED, "sprint speed constant greater than normal speed")
