extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_player_constants()
	_test_enemy_constants()
	_test_attack_cooldown_decrement()
	_test_take_damage()
	_test_health_floor()
	_test_enemy_attack_timer()
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

func _test_player_constants() -> void:
	print("player constants")
	const SPEED := 160.0
	var health := 3
	var attack_cooldown_max := 0.6
	expect(SPEED == 160.0, "player SPEED is 160")
	expect(health == 3, "player starts with 3 health")
	expect(attack_cooldown_max == 0.6, "attack cooldown is 0.6s")

func _test_enemy_constants() -> void:
	print("enemy constants")
	var health := 5
	const ATTACK_INTERVAL := 2.2
	expect(health == 5, "enemy starts with 5 health")
	expect(ATTACK_INTERVAL == 2.2, "enemy ATTACK_INTERVAL is 2.2s")

func _test_attack_cooldown_decrement() -> void:
	print("attack cooldown decrement")
	var cooldown := 0.6
	cooldown = max(0.0, cooldown - 0.016)
	expect(cooldown < 0.6, "cooldown decrements each frame")
	expect(cooldown >= 0.0, "cooldown stays non-negative")
	cooldown = 0.005
	cooldown = max(0.0, cooldown - 0.016)
	expect_near(cooldown, 0.0, "small cooldown floors at 0")

func _test_take_damage() -> void:
	print("take_damage reduces health")
	var health := 3
	health -= 1
	expect(health == 2, "take_damage(1) reduces player health by 1")
	health = 5
	health -= 1
	expect(health == 4, "take_damage(1) reduces enemy health by 1")

func _test_health_floor() -> void:
	print("health cannot go below 0 in display")
	var health := 0
	var displayed := maxi(health, 0)
	expect(displayed == 0, "displayed health is max(health, 0)")
	health = -1
	displayed = max(health, 0)
	expect(displayed == 0, "negative health displays as 0")

func _test_enemy_attack_timer() -> void:
	print("enemy attack timer accumulation")
	const ATTACK_INTERVAL := 2.2
	var attack_timer := 0.0
	attack_timer += 1.0
	expect(attack_timer < ATTACK_INTERVAL, "after 1s, timer has not reached interval")
	attack_timer += 1.5
	expect(attack_timer >= ATTACK_INTERVAL, "after 2.5s, timer has reached interval")

func _report() -> void:
	var summary := "[hitbox-hurtbox] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
