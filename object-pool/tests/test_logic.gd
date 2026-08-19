extends Node

# Drives the real ObjectPool from scripts/object_pool.gd rather than a list of
# dictionaries standing in for pooled nodes.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_pool_preallocates()
	_test_acquire_returns_inactive()
	_test_acquire_returns_null_when_all_active()
	_test_released_instance_is_reused()
	_test_hit_miss_tracking()
	_test_signals()
	await _test_a_bullet_lives_and_dies()
	await _test_the_player_aims_what_it_fires()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

const POOL_SIZE := 20

# ObjectPool fills itself in _ready(), so the pool has to enter the tree. The
# pooled scene is built here instead of loaded so the test stays self-contained.
func _make_pool(size: int = POOL_SIZE) -> ObjectPool:
	var template := Node2D.new()
	var packed := PackedScene.new()
	packed.pack(template)
	template.free()

	var pool := ObjectPool.new()
	pool.scene = packed
	pool.size = size
	add_child(pool)
	return pool

func _test_pool_preallocates() -> void:
	print("pool preallocates its instances")
	var pool := _make_pool()
	expect(pool.get_child_count() == POOL_SIZE, "pool instantiates `size` children up front")
	expect(pool.active_count() == 0, "every instance starts inactive (hidden)")

func _test_acquire_returns_inactive() -> void:
	print("acquire returns an inactive instance")
	var pool := _make_pool()
	var instance := pool.acquire()
	expect(instance != null, "inactive instance found in pool")
	expect(not instance.visible, "the returned instance is still hidden — the caller shows it")

func _test_acquire_returns_null_when_all_active() -> void:
	print("acquire returns null when the pool is exhausted")
	var pool := _make_pool(3)
	for i in 3:
		var instance := pool.acquire()
		instance.visible = true          # mark it in use
	expect(pool.active_count() == 3, "all three instances are active")
	expect(pool.acquire() == null, "null returned when every instance is active")

func _test_released_instance_is_reused() -> void:
	print("hiding an instance returns it to the pool")
	var pool := _make_pool(1)
	var first := pool.acquire()
	first.visible = true
	expect(pool.acquire() == null, "pool of 1 is exhausted while its instance is visible")
	first.visible = false                # release
	expect(pool.acquire() == first, "the same instance is handed out again after release")

func _test_hit_miss_tracking() -> void:
	print("hit and miss counters")
	var pool := _make_pool(1)
	var instance := pool.acquire()
	instance.visible = true
	pool.acquire()                       # miss
	pool.acquire()                       # miss
	expect(pool.reuse_count == 1, "hit counter increments on a successful acquire")
	expect(pool.miss_count == 2, "miss counter increments when exhausted")
	expect(pool.reuse_count + pool.miss_count == 3, "total acquire attempts tracked correctly")

func _test_signals() -> void:
	print("acquired and exhausted signals")
	var pool := _make_pool(1)
	var events: Array[String] = []
	pool.acquired.connect(func(_instance: Node) -> void: events.append("acquired"))
	pool.exhausted.connect(func() -> void: events.append("exhausted"))
	var instance := pool.acquire()
	instance.visible = true
	pool.acquire()
	expect(events == ["acquired", "exhausted"], "acquired then exhausted, in that order")

func _report() -> void:
	var summary := "[object-pool] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# --- the demo on top of the pool ---------------------------------------------
#
# Everything above drives ObjectPool, which is the reusable half. The demo's own
# two scripts — a bullet that hides itself when its life runs out, and a player
# that decides where the shot starts — had nothing on them at all.

const Bullet := preload("res://scripts/bullet.gd")

## A pooled bullet is hidden until fired and hides itself again when spent.
##
## Visibility is the whole recycling mechanism here: the pool never frees
## anything, so "returned to the pool" means "invisible and not moving". A
## bullet that spawns visible litters the screen with dead rounds at startup,
## and one that stays visible after its lifetime never comes back.
func _test_a_bullet_lives_and_dies() -> void:
	print("a bullet's life")
	# The pool is what hides its instances — that is its whole contract, and it
	# is asserted above. Here the bullet is taken as the pool hands it over.
	var bullet: Node2D = Bullet.new()
	bullet.visible = false
	add_child(bullet)
	await get_tree().process_frame

	expect(not bullet.visible, "a pooled bullet waits out of sight")

	bullet.fire(Vector2(100, 50), Vector2.RIGHT)
	expect(bullet.visible, "firing puts it on screen")
	expect(bullet.global_position == Vector2(100, 50), "at the position it was given")
	expect(bullet.direction == Vector2.RIGHT, "travelling the way it was aimed")
	expect(bullet._lifetime > 0.0, "with time on the clock (%.2f)" % bullet._lifetime)

	# Moving: the direction is what carries it, so a step must land downrange.
	var started: Vector2 = bullet.global_position
	bullet._process(0.1)
	expect(bullet.global_position.x > started.x, "it travels along its direction")
	expect(is_equal_approx(bullet.global_position.y, started.y),
		"and not sideways (%.1f)" % bullet.global_position.y)
	var travelled: float = bullet.global_position.x - started.x
	expect(absf(travelled - bullet.speed * 0.1) < 1.0,
		"at its own speed (%.1f of %.1f)" % [travelled, bullet.speed * 0.1])

	# Spent: the lifetime runs out and it takes itself off the screen.
	var life: float = bullet._lifetime
	bullet._process(life * 0.5)
	expect(bullet.visible, "it is still alive halfway through its life")
	bullet._process(life)
	expect(not bullet.visible, "and gone once the clock runs out")
	expect(bullet._lifetime == 0.0, "with its clock cleared for the next use (%.2f)" % bullet._lifetime)

	# An invisible bullet is inert — otherwise every returned round would keep
	# flying around the pool costing time forever.
	var parked: Vector2 = bullet.global_position
	bullet._process(1.0)
	expect(bullet.global_position == parked, "a returned bullet does not keep moving")

	# And it is reusable, which is the point of pooling it at all.
	bullet.fire(Vector2(-40, 200), Vector2.UP)
	expect(bullet.visible and bullet._lifetime > 0.0, "the same bullet fires again")
	expect(bullet.global_position == Vector2(-40, 200), "from wherever it is next needed")

	bullet.queue_free()

## The player fires from in front of itself, in the direction it faces.
##
## The muzzle offset is `facing * 20`. Subtract it instead and every shot is
## born behind the player — which reads as the player shooting itself in the
## back, and in a demo with collisions would be exactly that.
func _test_the_player_aims_what_it_fires() -> void:
	print("where a shot starts")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame

	var player: CharacterBody2D = scene.get_node("Player")
	var caught: Array = []
	player.fired.connect(func(from: Vector2, dir: Vector2) -> void:
		caught.append([from, dir]))

	player.facing = Vector2.RIGHT
	player.global_position = Vector2(300, 240)
	player.fired.emit(player.muzzle(), player.facing)
	expect(caught.size() == 1, "the shot is announced once")
	if caught.size() == 1:
		var from: Vector2 = caught[0][0]
		expect(from.x > player.global_position.x,
			"it starts in front of the player, not behind (%s vs %s)"
			% [from, player.global_position])
		expect(is_equal_approx(from.distance_to(player.global_position), player.MUZZLE_OFFSET),
			"one muzzle length out (%.1f)" % from.distance_to(player.global_position))

	# The muzzle turns with the player, or every shot leaves from the same side
	# however the player is aimed.
	player.facing = Vector2.UP
	expect(player.muzzle().y < player.global_position.y, "facing up, the muzzle is above")
	player.facing = Vector2.LEFT
	expect(player.muzzle().x < player.global_position.x, "facing left, it is to the left")

	# The pool is what receives it, and a shot must actually take a bullet out.
	var before: int = scene.pool.active_count()
	scene._on_fired(Vector2(100, 100), Vector2.LEFT)
	expect(scene.pool.active_count() == before + 1,
		"firing takes a bullet from the pool (%d -> %d)" % [before, scene.pool.active_count()])

	# Facing only changes while there is input to change it — a released key
	# must leave the player aiming where it was, not snap back to the default.
	expect(player.aim_for(Vector2.ZERO, Vector2.UP) == Vector2.UP,
		"no input at all leaves the aim alone")
	expect(player.aim_for(Vector2(0, -3), Vector2.RIGHT) == Vector2.UP,
		"a push up aims up, normalised (%s)" % player.aim_for(Vector2(0, -3), Vector2.RIGHT))
	expect(player.aim_for(Vector2(1, 1), Vector2.RIGHT).length() < 1.01,
		"a diagonal is not longer than a straight push")
	player.facing = Vector2.UP
	player._physics_process(1.0 / 60.0)
	expect(player.facing == Vector2.UP, "and driving the real frame keeps it too")

	scene.queue_free()
