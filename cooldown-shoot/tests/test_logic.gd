extends Node

# Drives the real player from scripts/player.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_starts_ready()
	_test_firing_blocks_immediately()
	_test_cooldown_expires()
	_test_cooldown_never_goes_negative()
	_test_ratio_spans_zero_to_one()
	_test_ratio_is_monotonic()
	_test_firing_again_restarts_the_full_cooldown()
	_test_facing_follows_real_input_only()
	_test_bullet_travels_and_expires()
	await test_the_bullet_flies_and_expires()
	await test_a_shot_starts_clear_of_the_player()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_facing_follows_real_input_only() -> void:
	print("aim")
	var p := _make()
	p.update_facing(Vector2.RIGHT)
	expect(p.facing.is_equal_approx(Vector2.RIGHT), "aim follows movement")
	# Analogue sticks rest slightly off centre; that must not rewrite the aim.
	p.update_facing(Vector2(0.02, 0.0))
	expect(p.facing.is_equal_approx(Vector2.RIGHT), "drift below the threshold is ignored")
	p.update_facing(Vector2.ZERO)
	expect(p.facing.is_equal_approx(Vector2.RIGHT), "releasing keeps the last aim")
	p.update_facing(Vector2(0, -1))
	expect(p.facing.is_equal_approx(Vector2.UP), "a real heading updates it")
	p.update_facing(Vector2(3, 4))
	expect(is_equal_approx(p.facing.length(), 1.0), "aim is always a unit vector")

func _test_bullet_travels_and_expires() -> void:
	print("bullets")
	var bullet_script: GDScript = load("res://scripts/bullet.gd")
	var b := Area2D.new()
	b.set_script(bullet_script)
	add_child(b)
	b.direction = Vector2.RIGHT
	b.position = Vector2.ZERO

	b._process(0.1)
	expect(b.position.x > 0.0, "a bullet advances along its direction")
	expect(is_zero_approx(b.position.y), "and does not drift off-axis")

	# A bullet that never expires is a leak in every shooter that fires often.
	var elapsed := 0.1
	while elapsed < 2.0 and not b.is_queued_for_deletion():
		b._process(0.05)
		elapsed += 0.05
	expect(b.is_queued_for_deletion(), "a bullet frees itself once its lifetime runs out")

## The bullet's own life, and where it starts.
func test_the_bullet_flies_and_expires() -> void:
	print("the bullet")
	var bullet: Area2D = load("res://scripts/bullet.gd").new()
	add_child(bullet)
	bullet.direction = Vector2.RIGHT
	bullet.position = Vector2(100, 100)

	var life: float = bullet._lifetime
	expect(life > 0.0, "a fresh bullet has time on the clock (%.2f)" % life)

	bullet._process(0.1)
	expect(bullet.position.x > 100.0, "it travels along its direction (%s)" % bullet.position)
	expect(is_equal_approx(bullet.position.y, 100.0), "and not sideways")
	# A frame has to pass before this means anything: queue_free() is deferred,
	# so a bullet that freed itself on its very first step would still look
	# valid on the line after the call.
	await get_tree().process_frame
	await get_tree().process_frame
	expect(is_instance_valid(bullet),
		"and is still alive well inside its lifetime (%.2f left)" % bullet._lifetime)

	# It frees itself when the clock runs out — a bullet that never expires
	# accumulates one node per shot for as long as the game runs.
	bullet._process(life)
	# queue_free() takes effect at the end of a frame, not on the call.
	await get_tree().process_frame
	await get_tree().process_frame
	expect(not is_instance_valid(bullet), "and frees itself once the clock runs out")

## Firing spawns a bullet in front of the player, and only when the cooldown says so.
func test_a_shot_starts_clear_of_the_player() -> void:
	print("the muzzle")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame
	var player: CharacterBody2D = scene.get_node("Player")

	player.facing = Vector2.RIGHT
	expect(player.muzzle().x > player.global_position.x,
		"facing right, a shot starts to the right (%s vs %s)"
		% [player.muzzle(), player.global_position])
	player.facing = Vector2.LEFT
	expect(player.muzzle().x < player.global_position.x, "facing left, to the left")
	player.facing = Vector2.UP
	expect(player.muzzle().y < player.global_position.y, "facing up, above")
	expect(is_equal_approx(player.muzzle().distance_to(player.global_position),
			player.MUZZLE_OFFSET),
		"always one muzzle length out (%.1f)"
		% player.muzzle().distance_to(player.global_position))

	# The real spawn goes through the same point, and only fires off cooldown.
	player.facing = Vector2.RIGHT
	player.cooldown = 0.0
	var before := scene.get_child_count()
	player._shoot()
	expect(scene.get_child_count() == before + 1,
		"firing adds a bullet to the scene (%d -> %d)" % [before, scene.get_child_count()])
	expect(not player.can_fire(), "and starts the cooldown")

	var spawned: Node2D = scene.get_child(scene.get_child_count() - 1)
	expect(spawned.global_position.x > player.global_position.x,
		"the bullet starts in front of the player (%s)" % spawned.global_position)
	expect(spawned.direction == player.facing, "travelling the way the player aims")

	# Nothing pressed, nothing fired. The trigger reads Input, which cannot be
	# pressed headless — but its other half is can_fire(), and loosening the
	# `and` to an `or` empties the magazine on every frame the cooldown is up.
	player.cooldown = 0.0
	var quiet := scene.get_child_count()
	for _i in 30:
		await get_tree().physics_frame
	expect(player.can_fire(), "the player is off cooldown and able to fire")
	expect(scene.get_child_count() == quiet,
		"but fires nothing with no key pressed (%d -> %d)"
		% [quiet, scene.get_child_count()])

	scene.queue_free()

func _report() -> void:
	var summary := "[cooldown-shoot] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/player.gd")

func _make() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.set_script(_script)
	add_child(p)
	return p

func _test_starts_ready() -> void:
	print("initial state")
	var p := _make()
	expect(p.can_fire(), "a fresh player can fire immediately")
	expect(is_equal_approx(p.cooldown_ratio(), 1.0), "and the bar reads full")

func _test_firing_blocks_immediately() -> void:
	print("firing")
	var p := _make()
	p.begin_cooldown()
	expect(not p.can_fire(), "firing blocks the next shot at once")
	expect(is_zero_approx(p.cooldown_ratio()), "and the bar empties")

func _test_cooldown_expires() -> void:
	print("recovery")
	var p := _make()
	p.begin_cooldown()
	var elapsed := 0.0
	while elapsed < p.FIRE_COOLDOWN + STEP:
		p.tick_cooldown(STEP)
		elapsed += STEP
	expect(p.can_fire(), "the shot is available again after FIRE_COOLDOWN")

func _test_cooldown_never_goes_negative() -> void:
	print("clamping")
	# An unclamped timer keeps counting down past zero. can_fire() tests for
	# exactly zero, so a negative value would leave the player permanently
	# unable to shoot.
	var p := _make()
	p.begin_cooldown()
	for i in 600:
		p.tick_cooldown(STEP)
	expect(p.cooldown >= 0.0, "the timer stops at zero rather than going negative")
	expect(p.can_fire(), "so the player can still fire long afterwards")

func _test_ratio_spans_zero_to_one() -> void:
	print("bar range")
	var p := _make()
	p.begin_cooldown()
	expect(is_zero_approx(p.cooldown_ratio()), "empty right after firing")
	for i in 600:
		p.tick_cooldown(STEP)
	expect(is_equal_approx(p.cooldown_ratio(), 1.0), "full once recovered")

func _test_ratio_is_monotonic() -> void:
	print("bar fills steadily")
	var p := _make()
	p.begin_cooldown()
	var previous: float = p.cooldown_ratio()
	for i in 20:
		p.tick_cooldown(STEP)
		var now: float = p.cooldown_ratio()
		expect(now >= previous, "the bar only ever fills, never jumps back")
		previous = now

func _test_firing_again_restarts_the_full_cooldown() -> void:
	print("re-firing")
	var p := _make()
	p.begin_cooldown()
	for i in 5:
		p.tick_cooldown(STEP)
	p.begin_cooldown()
	expect(is_equal_approx(p.cooldown, p.FIRE_COOLDOWN),
		"a second shot resets the full duration rather than topping it up")
