extends Node

const MANA_REGEN := 8.0
const MAX_MANA := 100.0

var _pass_count := 0
var _fail_count := 0


func _ready() -> void:
	_test_ability_costs_mana()
	_test_cooldown_prevents_use()
	_test_mana_prevents_use()
	_test_cooldown_ticks_down()
	_test_mana_regen()
	_report()


func expect(condition: bool, label: String) -> void:
	if condition:
		_pass_count += 1
		print("[PASS] ", label)
	else:
		_fail_count += 1
		print("[FAIL] ", label)


func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass_count, _fail_count])


func _test_ability_costs_mana() -> void:
	var mana := 100.0
	var cost := 20
	var timer := 0.0
	var cooldown := 2.0
	# Use ability
	if timer <= 0.0 and mana >= cost:
		mana -= float(cost)
		timer = cooldown
	expect(mana == 80.0, "Mana costs: mana=80 after using ability with cost=20")
	expect(timer == cooldown, "Mana costs: cooldown timer set to cooldown value")


func _test_cooldown_prevents_use() -> void:
	var mana := 100.0
	var cost := 20
	var timer := 1.0
	var used := false
	if timer <= 0.0 and mana >= float(cost):
		mana -= float(cost)
		used = true
	expect(not used, "Cooldown prevents use: ability not used when timer=1.0")
	expect(mana == 100.0, "Cooldown prevents use: mana unchanged")


func _test_mana_prevents_use() -> void:
	var mana := 10.0
	var cost := 20
	var timer := 0.0
	var used := false
	if timer <= 0.0 and mana >= float(cost):
		mana -= float(cost)
		used = true
	expect(not used, "Mana prevents use: ability blocked when mana=10, cost=20")
	expect(mana == 10.0, "Mana prevents use: mana unchanged")


func _test_cooldown_ticks_down() -> void:
	var timer := 2.0
	var delta := 0.5
	timer = maxf(0.0, timer - delta)
	expect(is_equal_approx(timer, 1.5), "Cooldown ticks: timer=1.5 after 0.5s delta")


func _test_mana_regen() -> void:
	var mana := 50.0
	var delta := 1.0
	mana = minf(MAX_MANA, mana + MANA_REGEN * delta)
	expect(is_equal_approx(mana, 58.0), "Mana regen: mana=58 after 1s regen from 50")

	# Test cap
	mana = 98.0
	mana = minf(MAX_MANA, mana + MANA_REGEN * delta)
	expect(is_equal_approx(mana, MAX_MANA), "Mana regen cap: mana capped at MAX_MANA=100")
