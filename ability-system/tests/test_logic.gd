extends Node

# Drives the real ability bar from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_starts_ready()
	_test_using_an_ability_spends_mana_and_starts_its_cooldown()
	_test_an_ability_on_cooldown_cannot_be_used()
	_test_a_cooldown_runs_down_and_frees_the_ability()
	_test_an_ability_you_cannot_afford_is_refused()
	_test_a_refused_ability_costs_nothing()
	_test_mana_regenerates_up_to_the_cap()
	_test_each_key_uses_its_own_ability()
	_test_other_keys_do_nothing()
	_test_cooldowns_are_independent()
	_test_the_log_keeps_the_last_few_lines()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[ability-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _press(m: Node2D, code: Key, echo: bool = false) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	e.echo = echo
	m._input(e)

func _run(m: Node2D, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		m._process(STEP)
		elapsed += STEP

## The cheapest ability, so tests can use it repeatedly.
func _cheapest(m: Node2D) -> int:
	var best := 0
	for i in m._abilities.size():
		if m._abilities[i]["cost"] < m._abilities[best]["cost"]:
			best = i
	return best

func _test_it_starts_ready() -> void:
	print("the bar")
	var m := _make()
	expect(m._abilities.size() > 1, "there are several abilities")
	expect(is_equal_approx(m._mana, m.MAX_MANA), "with a full mana bar")
	var ready := true
	var keys := {}
	for ability in m._abilities:
		if ability["timer"] > 0.0:
			ready = false
		keys[ability["key"]] = true
	expect(ready, "and none of them on cooldown")
	expect(keys.size() == m._abilities.size(), "each bound to its own key")

func _test_using_an_ability_spends_mana_and_starts_its_cooldown() -> void:
	print("using one")
	var m := _make()
	var i := _cheapest(m)
	var cost: float = float(m._abilities[i]["cost"])
	m._try_use_ability(i)
	expect(is_equal_approx(m._mana, m.MAX_MANA - cost), "the ability costs its mana")
	expect(m._abilities[i]["timer"] > 0.0, "and goes on cooldown")
	expect(m._abilities[i]["effect_timer"] > 0.0, "with an effect to draw")

	# The effect is a ring that expands and fades, so its timer has to run down.
	var flash: float = m._abilities[i]["effect_timer"]
	_run(m, 0.1)
	expect(m._abilities[i]["effect_timer"] < flash, "which fades rather than growing")
	_run(m, 2.0)
	expect(is_zero_approx(m._abilities[i]["effect_timer"]), "and is gone shortly after")

func _test_an_ability_on_cooldown_cannot_be_used() -> void:
	print("cooldown")
	var m := _make()
	var i := _cheapest(m)
	m._try_use_ability(i)
	var mana_after: float = m._mana
	var timer_after: float = m._abilities[i]["timer"]
	m._try_use_ability(i)
	expect(is_equal_approx(m._mana, mana_after), "a second use costs nothing")
	expect(is_equal_approx(m._abilities[i]["timer"], timer_after), "and does not restart the cooldown")

func _test_a_cooldown_runs_down_and_frees_the_ability() -> void:
	print("waiting it out")
	var m := _make()
	var i := _cheapest(m)
	m._try_use_ability(i)
	_run(m, float(m._abilities[i]["cooldown"]) + 0.2)
	expect(is_zero_approx(m._abilities[i]["timer"]), "the cooldown expires")
	var before: float = m._mana
	m._try_use_ability(i)
	expect(m._mana < before, "and the ability can be used again")

func _test_an_ability_you_cannot_afford_is_refused() -> void:
	print("running dry")
	var m := _make()
	var i := _cheapest(m)
	m._mana = float(m._abilities[i]["cost"]) - 1.0
	m._try_use_ability(i)
	expect(m._abilities[i]["timer"] == 0.0, "one point of mana short means no ability")

func _test_a_refused_ability_costs_nothing() -> void:
	print("refusals are free")
	var m := _make()
	var i := _cheapest(m)
	m._mana = 1.0
	m._try_use_ability(i)
	expect(is_equal_approx(m._mana, 1.0), "a refused ability does not drain the bar anyway")
	expect(m._log[m._log.size() - 1].contains("mana"), "and says why")

func _test_mana_regenerates_up_to_the_cap() -> void:
	print("regenerating")
	var m := _make()
	m._mana = 10.0
	_run(m, 1.0)
	expect(m._mana > 10.0, "mana comes back over time")
	expect(is_equal_approx(m._mana, 10.0 + m.MANA_REGEN), "at the regen rate")
	_run(m, 60.0)
	expect(m._mana <= m.MAX_MANA, "and stops at the maximum rather than growing forever")

func _test_each_key_uses_its_own_ability() -> void:
	print("the keys")
	for i in _make()._abilities.size():
		var m := _make()
		m._mana = m.MAX_MANA
		_press(m, m._abilities[i]["key"])
		expect(m._abilities[i]["timer"] > 0.0, "%s fires on its own key" % m._abilities[i]["name"])
		var others_idle := true
		for j in m._abilities.size():
			if j != i and m._abilities[j]["timer"] > 0.0:
				others_idle = false
		expect(others_idle, "and nothing else fires with it")

func _test_other_keys_do_nothing() -> void:
	print("unbound keys")
	var m := _make()
	_press(m, KEY_Z)
	expect(is_equal_approx(m._mana, m.MAX_MANA), "an unbound key spends no mana")

	var held := _make()
	_press(held, held._abilities[0]["key"], true)
	expect(held._abilities[0]["timer"] == 0.0, "and a held key does not repeat-fire through echoes")

func _test_cooldowns_are_independent() -> void:
	print("separate cooldowns")
	var m := _make()
	m._try_use_ability(0)
	expect(m._abilities[0]["timer"] > 0.0, "the first ability is cooling down")
	expect(m._abilities[1]["timer"] == 0.0, "the second is not — each has its own timer")

	# And the timers run down at their own rates, not together.
	var short_one := 0
	var long_one := 0
	for i in m._abilities.size():
		if float(m._abilities[i]["cooldown"]) < float(m._abilities[short_one]["cooldown"]):
			short_one = i
		if float(m._abilities[i]["cooldown"]) > float(m._abilities[long_one]["cooldown"]):
			long_one = i
	var both := _make()
	both._try_use_ability(short_one)
	both._try_use_ability(long_one)
	_run(both, float(both._abilities[short_one]["cooldown"]) + 0.2)
	expect(is_zero_approx(both._abilities[short_one]["timer"]), "the short cooldown has expired")
	expect(both._abilities[long_one]["timer"] > 0.0, "while the long one is still running")

func _test_the_log_keeps_the_last_few_lines() -> void:
	print("the log")
	var m := _make()
	for i in 12:
		m._add_log("line %d" % i)
	expect(m._log.size() == 5, "the log keeps exactly the last five lines")
	expect(m._log[m._log.size() - 1] == "line 11", "keeping the most recent line")
	expect(not m._log.has("line 0"), "and dropping the oldest")
