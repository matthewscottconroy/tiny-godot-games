extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_damage_clamps_at_zero()
	test_heal_clamps_at_max()
	test_damage_reduces_hp()
	test_heal_increases_hp()
	test_hp_ratio_full()
	test_hp_ratio_empty()
	test_hp_ratio_partial()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[health-bar] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Replicate HP logic from main.gd
const MAX_HP := 100

func _apply_damage(hp: int, amount: int) -> int:
	return max(0, hp - amount)

func _apply_heal(hp: int, amount: int) -> int:
	return min(MAX_HP, hp + amount)

func _hp_ratio(hp: int) -> float:
	return float(hp) / MAX_HP

# --- tests ---

func test_damage_reduces_hp() -> void:
	expect(_apply_damage(100, 10) == 90, "100 hp - 10 damage = 90")
	expect(_apply_damage(50, 30)  == 20, "50 hp - 30 damage = 20")

func test_damage_clamps_at_zero() -> void:
	expect(_apply_damage(5, 10) == 0,  "damage beyond zero clamps to 0")
	expect(_apply_damage(0, 10) == 0,  "damage at 0 stays at 0")

func test_heal_increases_hp() -> void:
	expect(_apply_heal(50, 10) == 60,  "50 hp + 10 heal = 60")
	expect(_apply_heal(80, 15) == 95,  "80 hp + 15 heal = 95")

func test_heal_clamps_at_max() -> void:
	expect(_apply_heal(95, 10) == 100, "heal beyond max clamps to 100")
	expect(_apply_heal(100, 10) == 100, "heal at max stays at max")

func test_hp_ratio_full() -> void:
	expect(is_equal_approx(_hp_ratio(100), 1.0), "full HP ratio is 1.0")

func test_hp_ratio_empty() -> void:
	expect(is_equal_approx(_hp_ratio(0), 0.0), "zero HP ratio is 0.0")

func test_hp_ratio_partial() -> void:
	expect(is_equal_approx(_hp_ratio(50), 0.5), "50/100 HP ratio is 0.5")
	expect(is_equal_approx(_hp_ratio(25), 0.25), "25/100 HP ratio is 0.25")
