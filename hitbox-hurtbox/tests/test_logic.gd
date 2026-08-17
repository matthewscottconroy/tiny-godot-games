extends Node

# Drives the real fighters from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The lesson is the hitbox/hurtbox split: a hitbox deals damage, a hurtbox
# receives it, and they are separate areas on separate layers. The suite emits
# the overlaps the physics engine would emit.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_both_fighters_start_whole()
	_test_hurtboxes_announce_themselves()
	_test_hitboxes_are_off_until_a_swing()
	_test_a_hit_takes_health_off_the_other_fighter()
	_test_a_hitbox_only_hurts_hurtboxes()
	_test_running_out_of_health_is_a_knockout()
	_test_health_is_not_shown_as_negative()
	_test_the_hitbox_and_hurtbox_are_on_different_layers()
	_test_the_cooldown_runs_down()
	_test_the_enemy_swings_on_a_timer()
	_test_a_fighter_at_full_health_is_not_knocked_out()
	await _test_a_swing_puts_the_hitbox_away_again()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[hitbox-hurtbox] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _test_both_fighters_start_whole() -> void:
	print("the fighters")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	var enemy: CharacterBody2D = m.get_node("Enemy")
	expect(player.health > 0, "the player starts with health")
	expect(enemy.health > 0, "and so does the enemy")
	expect(enemy.health > player.health, "the enemy is the tougher of the two")

func _test_hurtboxes_announce_themselves() -> void:
	print("finding what can be hit")
	var m := _make()
	# A hitbox looks for the group rather than for a node name, so anything that
	# can be hurt opts in the same way.
	expect(m.get_node("Player/Hurtbox").is_in_group("hurtbox"), "the player's hurtbox joins the group")
	expect(m.get_node("Enemy/Hurtbox").is_in_group("hurtbox"), "and so does the enemy's")
	expect(not m.get_node("Player/Hitbox").is_in_group("hurtbox"), "a hitbox does not — it deals damage")

func _test_hitboxes_are_off_until_a_swing() -> void:
	print("swinging")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	expect(not player.hitbox.monitoring, "a hitbox is inert between attacks")
	player._attack()
	expect(player.hitbox.monitoring, "attacking switches it on")
	expect(player.attack_cooldown > 0.0, "and starts the cooldown")

	# The cooldown is what stops an attack every frame.
	player._physics_process(1.0 / 60.0)
	expect(player.attack_cooldown > 0.0, "which does not clear on the next frame")

func _test_a_hit_takes_health_off_the_other_fighter() -> void:
	print("landing a hit")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	var enemy: CharacterBody2D = m.get_node("Enemy")
	var before: int = enemy.health

	player._on_hitbox_area_entered(m.get_node("Enemy/Hurtbox"))
	expect(enemy.health == before - 1, "the enemy loses a point of health")
	expect(player.health == 3, "and the player loses none")

	var player_before: int = player.health
	enemy._on_hitbox_area_entered(m.get_node("Player/Hurtbox"))
	expect(player.health == player_before - 1, "it works the other way round too")

func _test_a_hitbox_only_hurts_hurtboxes() -> void:
	print("what does not count")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	var enemy: CharacterBody2D = m.get_node("Enemy")
	var before: int = enemy.health

	# Two hitboxes crossing is not a hit — otherwise trading blows would damage
	# whoever's swing arrived second.
	player._on_hitbox_area_entered(m.get_node("Enemy/Hitbox"))
	expect(enemy.health == before, "overlapping another hitbox does no damage")

	var loose := Area2D.new()
	add_child(loose)
	player._on_hitbox_area_entered(loose)
	expect(enemy.health == before, "and neither does an unrelated area")

func _test_running_out_of_health_is_a_knockout() -> void:
	print("knockout")
	var m := _make()
	var enemy: CharacterBody2D = m.get_node("Enemy")
	var label: Label = enemy.get_node("HealthLabel")
	for i in enemy.health:
		enemy.take_damage(1)
	expect(enemy.health <= 0, "enough hits empty the health bar")
	expect(label.text.contains("KO"), "and the readout says so")

func _test_health_is_not_shown_as_negative() -> void:
	print("overkill")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	var label: Label = player.get_node("HealthLabel")
	player.take_damage(1)
	expect(label.text.contains("2"), "the readout follows the health down")
	player.take_damage(99)
	expect(not label.text.contains("-"), "and a huge hit does not print a negative")

func _test_the_hitbox_and_hurtbox_are_on_different_layers() -> void:
	print("collision layers")
	var m := _make()
	var hitbox: Area2D = m.get_node("Player/Hitbox")
	var hurtbox: Area2D = m.get_node("Player/Hurtbox")
	# Keeping them apart is what stops a fighter's own swing from hitting them.
	expect(hitbox.collision_layer != hurtbox.collision_layer,
		"a hitbox and a hurtbox sit on different layers")
	expect(hitbox.collision_mask & hurtbox.collision_layer != 0,
		"and a hitbox watches the layer hurtboxes live on")
	expect(hitbox.collision_mask & hitbox.collision_layer == 0,
		"but not its own, so swings do not collide with each other")

func _test_the_cooldown_runs_down() -> void:
	print("the cooldown")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	player._attack()
	var started: float = player.attack_cooldown
	player._physics_process(0.1)
	expect(player.attack_cooldown < started, "the cooldown counts down, it does not grow")
	for i in 60:
		player._physics_process(1.0 / 60.0)
	expect(is_zero_approx(player.attack_cooldown), "and reaches zero, freeing the next attack")

func _test_the_enemy_swings_on_a_timer() -> void:
	print("the enemy's attack")
	var m := _make()
	var enemy: CharacterBody2D = m.get_node("Enemy")
	# The enemy has no input — it attacks on a fixed interval, so the interval
	# has to actually elapse first.
	enemy._process(enemy.ATTACK_INTERVAL * 0.5)
	expect(not enemy.hitbox.monitoring, "it does not swing before its interval is up")
	enemy._process(enemy.ATTACK_INTERVAL * 0.6)
	expect(enemy.hitbox.monitoring, "and does once the interval passes")
	expect(is_zero_approx(enemy.attack_timer), "the timer restarts for the next swing")

func _test_a_fighter_at_full_health_is_not_knocked_out() -> void:
	print("still standing")
	var m := _make()
	var enemy: CharacterBody2D = m.get_node("Enemy")
	var label: Label = enemy.get_node("HealthLabel")
	enemy.take_damage(1)
	expect(enemy.health > 0, "one hit does not finish the enemy")
	expect(not label.text.contains("KO"), "and the readout does not call it")

func _test_a_swing_puts_the_hitbox_away_again() -> void:
	print("the swing ending")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	player._attack()
	expect(player.hitbox.monitoring, "the hitbox is live during the swing")
	# A hitbox left on would keep dealing damage on contact forever, so the
	# timer that switches it off is the important half of the attack.
	await get_tree().create_timer(0.4).timeout
	expect(not player.hitbox.monitoring, "and is switched off when the swing ends")
