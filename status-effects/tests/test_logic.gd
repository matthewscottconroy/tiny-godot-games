extends Node

# Drives the real StatusEffectStack from scripts/status_effect_stack.gd rather
# than a copy of its tick loop, so the signals are covered too.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_effect_applied()
	test_effect_refreshes_on_reapply()
	test_effect_expires()
	test_dps_reduces_hp()
	test_slow_multiplier_applied()
	test_strongest_slow_wins()
	test_multiple_effects_stack()
	test_signals()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[status-effects] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const EFFECT_CFG := {
	"poison": {"dps": 10.0, "slow": 1.00, "duration": 5.0},
	"burn":   {"dps": 22.0, "slow": 1.00, "duration": 3.0},
	"freeze": {"dps":  0.0, "slow": 0.35, "duration": 4.0},
	"chill":  {"dps":  0.0, "slow": 0.70, "duration": 4.0},
}

func _make() -> StatusEffectStack:
	return StatusEffectStack.new(EFFECT_CFG)

# `tick` reports damage per frame; the caller subtracts it from its own hp.
func _tick_for(stack: StatusEffectStack, seconds: float, delta: float = 0.5) -> Dictionary:
	var damage := 0.0
	var slow := 1.0
	var elapsed := 0.0
	while elapsed < seconds:
		var r := stack.tick(delta)
		damage += r["damage"]
		slow = minf(slow, r["slow"])
		elapsed += delta
	return {"damage": damage, "slow": slow}

func test_effect_applied() -> void:
	var stack := _make()
	stack.apply("poison")
	var r := stack.tick(0.1)
	expect(r["damage"] > 0.0, "poison is active and deals damage on tick")

func test_effect_refreshes_on_reapply() -> void:
	var stack := _make()
	stack.apply("burn")            # 3s
	_tick_for(stack, 2.5)
	stack.apply("burn")            # refreshed back to 3s
	var r := _tick_for(stack, 2.0)
	expect(r["damage"] > 0.0, "reapply refreshes the timer instead of stacking a second copy")

func test_effect_expires() -> void:
	var stack := _make()
	stack.apply("burn")            # burn duration is 3s
	_tick_for(stack, 3.5)
	var after := stack.tick(0.5)
	expect(is_zero_approx(after["damage"]), "burn deals no damage once expired")

func test_dps_reduces_hp() -> void:
	var stack := _make()
	stack.apply("poison")          # 10 dps
	var hp := 100.0
	hp -= _tick_for(stack, 1.0)["damage"]
	expect(hp < 100.0, "poison DPS reduces HP over time")
	expect(is_equal_approx(hp, 90.0), "1s of 10 dps removes 10 hp")

func test_slow_multiplier_applied() -> void:
	var stack := _make()
	stack.apply("freeze")
	expect(stack.tick(0.016)["slow"] < 1.0, "freeze reduces the movement multiplier")

func test_strongest_slow_wins() -> void:
	var stack := _make()
	stack.apply("chill")           # 0.70
	stack.apply("freeze")          # 0.35 — stronger
	expect(is_equal_approx(stack.tick(0.016)["slow"], 0.35),
		"the smallest (strongest) slow wins rather than multiplying")

func test_multiple_effects_stack() -> void:
	var stack := _make()
	stack.apply("poison")          # 10 dps
	stack.apply("burn")            # 22 dps
	var r := stack.tick(1.0)
	expect(is_equal_approx(r["damage"], 32.0), "damage from both effects is summed")

func test_signals() -> void:
	var stack := _make()
	var events: Array[String] = []
	stack.effect_applied.connect(func(fx: String) -> void: events.append("applied:" + fx))
	stack.effect_expired.connect(func(fx: String) -> void: events.append("expired:" + fx))
	stack.apply("burn")
	expect(events == ["applied:burn"], "effect_applied fires on apply")
	_tick_for(stack, 3.5)
	expect(events.has("expired:burn"), "effect_expired fires when the timer runs out")
