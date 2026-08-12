extends Node

# Drives the real Health node from scripts/health.gd rather than a copy of its
# clamping rules, so the signals and the dead-state guard are covered too.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_damage_reduces_hp()
	test_damage_clamps_at_zero()
	test_heal_increases_hp()
	test_heal_clamps_at_max()
	test_hp_ratio()
	test_health_changed_signal()
	test_died_signal_fires_once()
	test_heal_revives_from_zero()
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

const MAX_HP := 100

# Health sets hp from max_hp in _ready(), so the node has to enter the tree.
func _make(max_hp: int = MAX_HP) -> Health:
	var health := Health.new()
	health.max_hp = max_hp
	add_child(health)
	return health

# --- tests ---

func test_damage_reduces_hp() -> void:
	var h := _make()
	h.damage(10)
	expect(h.hp == 90, "100 hp - 10 damage = 90")
	h.damage(30)
	expect(h.hp == 60, "90 hp - 30 damage = 60")

func test_damage_clamps_at_zero() -> void:
	var h := _make(5)
	h.damage(10)
	expect(h.hp == 0, "damage beyond zero clamps to 0")
	h.damage(10)
	expect(h.hp == 0, "damage at 0 stays at 0")

func test_heal_increases_hp() -> void:
	var h := _make()
	h.damage(50)
	h.heal(10)
	expect(h.hp == 60, "50 hp + 10 heal = 60")

func test_heal_clamps_at_max() -> void:
	var h := _make()
	h.damage(5)
	h.heal(10)
	expect(h.hp == MAX_HP, "heal beyond max clamps to 100")
	h.heal(10)
	expect(h.hp == MAX_HP, "heal at max stays at max")

func test_hp_ratio() -> void:
	var h := _make()
	expect(is_equal_approx(float(h.hp) / h.max_hp, 1.0), "full HP ratio is 1.0")
	h.damage(50)
	expect(is_equal_approx(float(h.hp) / h.max_hp, 0.5), "50/100 HP ratio is 0.5")
	h.damage(50)
	expect(is_equal_approx(float(h.hp) / h.max_hp, 0.0), "zero HP ratio is 0.0")

func test_health_changed_signal() -> void:
	var h := _make()
	var seen := {"hp": -1, "max_hp": -1, "count": 0}
	h.health_changed.connect(func(hp: int, max_hp: int) -> void:
		seen["hp"] = hp
		seen["max_hp"] = max_hp
		seen["count"] += 1)
	h.damage(25)
	expect(seen["count"] == 1, "health_changed fires once per damage call")
	expect(seen["hp"] == 75 and seen["max_hp"] == MAX_HP, "health_changed carries hp and max_hp")

func test_died_signal_fires_once() -> void:
	var h := _make(30)
	var deaths := {"count": 0}
	h.died.connect(func() -> void: deaths["count"] += 1)
	h.damage(10)
	expect(deaths["count"] == 0, "died does not fire while hp remains")
	h.damage(50)
	expect(deaths["count"] == 1, "died fires when hp reaches 0")
	# damage() returns early once dead, so no second death and no extra signal.
	h.damage(50)
	expect(deaths["count"] == 1, "died does not fire again on further damage")

func test_heal_revives_from_zero() -> void:
	var h := _make()
	h.damage(MAX_HP)
	expect(h.hp == 0, "hp is 0 after lethal damage")
	h.heal(20)
	expect(h.hp == 20, "heal can bring hp back from 0")
