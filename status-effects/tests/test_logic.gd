extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_effect_applied()
	test_effect_refreshes_on_reapply()
	test_effect_expires()
	test_dps_reduces_hp()
	test_slow_multiplier_applied()
	test_multiple_effects_stack()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[status-effects] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const EFFECT_CFG := {
	"poison": {"dps": 10.0, "slow": 1.00, "duration": 5.0},
	"burn":   {"dps": 22.0, "slow": 1.00, "duration": 3.0},
	"freeze": {"dps":  0.0, "slow": 0.35, "duration": 4.0},
}

func _apply(active: Dictionary, name: String) -> Dictionary:
	active = active.duplicate()
	active[name] = EFFECT_CFG[name]["duration"]
	return active

func _tick(active: Dictionary, hp: float, delta: float) -> Dictionary:
	active = active.duplicate()
	var slow := 1.0
	var remove: Array[String] = []
	for fx in active.keys():
		active[fx] -= delta
		hp  -= EFFECT_CFG[fx]["dps"] * delta
		slow = minf(slow, EFFECT_CFG[fx]["slow"])
		if active[fx] <= 0.0: remove.append(fx)
	for fx in remove: active.erase(fx)
	return {"active": active, "hp": maxf(hp, 0.0), "slow": slow}

func test_effect_applied() -> void:
	var active := _apply({}, "poison")
	expect(active.has("poison"), "poison added to active effects")

func test_effect_refreshes_on_reapply() -> void:
	var active := _apply({}, "poison")
	active["poison"] = 1.0  # nearly expired
	active = _apply(active, "poison")
	expect(active["poison"] == EFFECT_CFG["poison"]["duration"], "reapply refreshes timer")

func test_effect_expires() -> void:
	var active := _apply({}, "burn")
	var result := _tick(active, 100.0, 4.0)  # burn duration is 3s
	expect(not result["active"].has("burn"), "burn expires after its duration")

func test_dps_reduces_hp() -> void:
	var active := _apply({}, "poison")
	var result := _tick(active, 100.0, 1.0)
	expect(result["hp"] < 100.0, "poison DPS reduces HP over time")

func test_slow_multiplier_applied() -> void:
	var active := _apply({}, "freeze")
	var result := _tick(active, 100.0, 0.016)
	expect(result["slow"] < 1.0, "freeze effect reduces movement speed multiplier")

func test_multiple_effects_stack() -> void:
	var active := _apply({}, "poison")
	active = _apply(active, "burn")
	expect(active.has("poison") and active.has("burn"), "two effects coexist in active dict")
