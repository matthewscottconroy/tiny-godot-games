extends Node

# Drives the real Knockback from scripts/knockback.gd rather than a copy of its
# impulse and decay maths.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_knockback_direction_from_hit()
	test_hit_sets_iframes()
	test_knockback_blocked_during_iframes()
	test_hit_allowed_again_after_iframes_expire()
	test_knockback_decays_each_frame()
	test_knockback_adds_to_control()
	test_iframes_decrement()
	await test_the_player_layers_it_on_top()
	await test_the_enemy_patrols_around_where_it_started()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[knockback] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const DELTA := 0.016

func test_knockback_direction_from_hit() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2(0, 0), Vector2(100, 0))   # hit from the left
	expect(kb.velocity.x > 0.0, "knockback pushes player away from hit source")
	expect(kb.velocity.y == kb.up, "vertical launch is the configured `up` speed")
	expect(is_equal_approx(kb.velocity.x, kb.impulse), "horizontal launch is the full impulse")

	# Hit from the right, and from a source that is not the origin: with the
	# attacker at (0,0) the direction is `target - source` and `target + source`
	# alike, so a test that only ever hits from the origin cannot tell a
	# subtraction from an addition.
	var right := Knockback.new()
	right.hit(Vector2(200, 0), Vector2(100, 0))
	expect(right.velocity.x < 0.0,
		"a hit from the right pushes left (%.0f)" % right.velocity.x)
	expect(is_equal_approx(absf(right.velocity.x), right.impulse),
		"with the same impulse either way")

	# The push is away from the attacker wherever both of them stand.
	var offset := Knockback.new()
	offset.hit(Vector2(500, 300), Vector2(400, 300))
	expect(offset.velocity.x < 0.0,
		"and away from an attacker standing well off the origin (%.0f)" % offset.velocity.x)

	# The pop is always upward, whichever side the hit came from — a hit that
	# drove the player into the ground would be unrecoverable.
	expect(right.velocity.y < 0.0, "the vertical pop is upward on a hit from the right")
	expect(offset.velocity.y < 0.0, "and on one from anywhere else")

func test_hit_sets_iframes() -> void:
	var kb := Knockback.new()
	expect(not kb.is_invincible(), "not invincible before any hit")
	expect(kb.hit(Vector2.ZERO, Vector2(100, 0)), "first hit lands and returns true")
	expect(kb.is_invincible(), "invincible immediately after a hit")

func test_knockback_blocked_during_iframes() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	var before := kb.velocity
	expect(not kb.hit(Vector2(200, 0), Vector2(100, 0)), "hit ignored while invincible")
	expect(kb.velocity == before, "a blocked hit does not change the knockback velocity")

func test_hit_allowed_again_after_iframes_expire() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	# Age past the i-frame window.
	var elapsed := 0.0
	while elapsed <= kb.iframe_time:
		kb.update(DELTA)
		elapsed += DELTA
	expect(not kb.is_invincible(), "i-frames expire after iframe_time")
	expect(kb.hit(Vector2.ZERO, Vector2(100, 0)), "a new hit lands once i-frames are gone")

func test_knockback_decays_each_frame() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	var launch_x := kb.velocity.x
	kb.update(DELTA)
	expect(kb.velocity.x < launch_x, "knockback decays per frame")
	expect(kb.velocity.x > 0.0, "one frame of decay does not zero it out")

func test_knockback_adds_to_control() -> void:
	# The owning body layers knockback on top of its own movement rather than
	# replacing it — that is the whole point of keeping it in its own vector.
	var kb := Knockback.new()
	kb.impulse = 300.0
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	var control_x := 200.0
	expect(is_equal_approx(control_x + kb.velocity.x, 500.0), "knockback adds to control velocity")

func test_iframes_decrement() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	var before := kb.iframes
	kb.update(DELTA)
	expect(is_equal_approx(kb.iframes, before - DELTA), "iframes count down by delta each frame")

# --- the body that owns it ---------------------------------------------------

## Everything above drives Knockback, which is the reusable half. player.gd is
## what layers it onto normal movement and spends the HP, and nothing touched it.
func test_the_player_layers_it_on_top() -> void:
	print("the player")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame
	var player: CharacterBody2D = scene.get_node("Player")

	var full: int = player._hp
	expect(full > 0, "the player starts with hit points (%d)" % full)

	# A hit costs exactly one, and only when it actually lands.
	player.take_hit(player.global_position - Vector2(100, 0))
	expect(player._hp == full - 1, "a hit costs one hit point (%d -> %d)" % [full, player._hp])
	expect(player._kb.is_invincible(), "and starts the i-frames")

	player.take_hit(player.global_position - Vector2(100, 0))
	expect(player._hp == full - 1,
		"a second hit inside the i-frames costs nothing (%d)" % player._hp)

	# The upward pop is handed to the body once and then cleared, so gravity
	# takes over. Left in place it would be re-applied every frame and the
	# player would hang in the air.
	expect(player._kb.velocity.y < 0.0, "the recoil is holding an upward pop")
	player._physics_process(1.0 / 60.0)
	expect(player.velocity.y < 0.0, "which the body takes on (%.0f)" % player.velocity.y)
	expect(player._kb.velocity.y == 0.0,
		"and the recoil lets go of it (%.0f)" % player._kb.velocity.y)

	# Horizontal recoil adds to control rather than replacing it: with no keys
	# pressed the control term is zero, so the body moves at the recoil's speed
	# and in the recoil's direction.
	var pushed: float = player._kb.velocity.x
	expect(pushed > 0.0, "the recoil is pushing right, away from the hit (%.0f)" % pushed)
	player._physics_process(1.0 / 60.0)
	expect(player.velocity.x > 0.0,
		"so the body moves right too, not against it (%.0f)" % player.velocity.x)

	# Nothing pressed, nothing happens. The jump reads Input, which a headless
	# test cannot press, but its other half is is_on_floor() — loosen the `and`
	# to an `or` and the player launches on every grounded frame.
	player._kb.velocity = Vector2.ZERO
	player._kb.iframes = 0.0
	for _i in 60:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player settles on the floor")
	var resting: float = player.global_position.y
	var highest := resting
	for _i in 40:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"and stays there untouched (rose %.1f px)" % (resting - highest))

	# Down to zero and no further — a negative HP readout is a bug on screen.
	for _i in 200:
		player._kb.iframes = 0.0
		player.take_hit(player.global_position - Vector2(100, 0))
	expect(player._hp == 0, "hit points stop at zero (%d)" % player._hp)

	scene.queue_free()

## The enemy walks a fixed distance either side of where it was placed.
##
## `absf(position.x - _origin.x) >= patrol_range` is doing two jobs: measuring
## from the spawn rather than from the world origin, and turning at the far edge
## rather than at the near one. Both are invisible to a test that only watches
## the enemy move.
func test_the_enemy_patrols_around_where_it_started() -> void:
	print("the patrol")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame

	var enemy: Node2D = scene.get_node("Enemy1")
	var spawn: float = enemy._origin.x
	var range: float = enemy.patrol_range
	expect(spawn > range,
		"the enemy is placed further from the world origin than its own range, "
		+ "so measuring from the wrong one would show (%.0f vs %.0f)" % [spawn, range])

	var lowest := spawn
	var highest := spawn
	# Long enough to walk out and back on both sides at 100 px/s.
	for _i in 400:
		enemy._process(1.0 / 60.0)
		lowest = minf(lowest, enemy.position.x)
		highest = maxf(highest, enemy.position.x)

	expect(highest > spawn and lowest < spawn,
		"it walks to both sides of its spawn (%.0f .. %.0f around %.0f)"
		% [lowest, highest, spawn])
	# One frame of overshoot at 100 px/s is under two pixels.
	expect(highest - spawn <= range + 2.0,
		"it turns at the far edge of its range, not past it (%.0f)" % (highest - spawn))
	expect(spawn - lowest <= range + 2.0, "on the near side too (%.0f)" % (spawn - lowest))
	expect(highest - spawn > range - 4.0,
		"and goes all the way out rather than turning early (%.0f of %.0f)"
		% [highest - spawn, range])

	# A second enemy with a different range walks a different distance — which
	# is what makes patrol_range an export rather than a constant.
	var other: Node2D = scene.get_node("Enemy2")
	expect(other.patrol_range != range,
		"the two enemies are configured differently (%.0f vs %.0f)"
		% [other.patrol_range, range])
	var other_far: float = other._origin.x
	for _i in 400:
		other._process(1.0 / 60.0)
		other_far = maxf(other_far, other.position.x)
	expect(absf((other_far - other._origin.x) - other.patrol_range) < 4.0,
		"the second walks its own range (%.0f of %.0f)"
		% [other_far - other._origin.x, other.patrol_range])

	scene.queue_free()
