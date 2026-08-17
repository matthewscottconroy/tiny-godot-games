extends Node

# Drives the real block and player from scripts/ — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_blocks_join_the_pushable_group()
	_test_a_push_moves_the_block()
	_test_a_push_from_the_right_goes_left()
	_test_the_shove_direction_opposes_the_normal()
	_test_friction_slows_the_block()
	_test_the_block_comes_to_a_full_stop()
	_test_an_unpushed_block_stays_put()
	_test_what_counts_as_pushable()
	_test_jumping_needs_the_floor()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[pushable-blocks] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _block_script: GDScript = load("res://scripts/pushable.gd")
var _player_script: GDScript = load("res://scripts/player.gd")

func _block() -> CharacterBody2D:
	var b := CharacterBody2D.new()
	b.set_script(_block_script)
	add_child(b)
	return b

func _player() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.set_script(_player_script)
	add_child(p)
	return p

func _test_blocks_join_the_pushable_group() -> void:
	print("finding the blocks")
	# The player only pushes what is in this group, so the block registers itself.
	var b := _block()
	expect(b.is_in_group("pushable"), "a block adds itself to the pushable group")

func _test_a_push_moves_the_block() -> void:
	print("pushing")
	var b := _block()
	b.push(200.0)
	b._physics_process(STEP)
	expect(b.velocity.x > 0.0, "a rightward push moves the block right")

func _test_a_push_from_the_right_goes_left() -> void:
	print("direction")
	var b := _block()
	b.push(-200.0)
	b._physics_process(STEP)
	expect(b.velocity.x < 0.0, "and a leftward push moves it left")

func _test_the_shove_direction_opposes_the_normal() -> void:
	print("the collision normal")
	var p := _player()
	# Walking right into a block: the normal points back at the player, so the
	# shove has to be the other way round.
	expect(p.push_from_normal(-1.0) > 0.0, "hitting a block on your right pushes it right")
	expect(p.push_from_normal(1.0) < 0.0, "and one on your left goes left")
	expect(absf(p.push_from_normal(-1.0)) == p.PUSH_STR, "at the demo's push strength")

func _test_friction_slows_the_block() -> void:
	print("friction")
	var b := _block()
	b.push(300.0)
	b._physics_process(STEP)
	var first: float = b.velocity.x
	for i in 5:
		b._physics_process(STEP)
	expect(b.velocity.x < first, "the block slows down after the shove")
	expect(b.velocity.x > 0.0, "but is still drifting the way it was pushed")

func _test_the_block_comes_to_a_full_stop() -> void:
	print("stopping")
	var b := _block()
	b.push(300.0)
	for i in 240:
		b._physics_process(STEP)
	# Exponential decay never quite reaches zero, so the demo snaps the last
	# pixel-per-second away. Otherwise blocks creep forever.
	expect(b.velocity.x == 0.0, "the block stops dead rather than creeping")

func _test_an_unpushed_block_stays_put() -> void:
	print("at rest")
	var b := _block()
	b._physics_process(STEP)
	expect(b.velocity.x == 0.0, "a block nobody pushed does not move sideways")
	expect(b.velocity.y > 0.0, "though gravity still applies to it")

func _test_what_counts_as_pushable() -> void:
	print("what gets pushed")
	var p := _player()
	expect(p.is_pushable(_block()), "a block is pushable")

	var wall := StaticBody2D.new()
	wall.add_to_group("pushable")
	add_child(wall)
	expect(not p.is_pushable(wall), "a static body is not, even in the group — it has no push()")

	var loose := CharacterBody2D.new()
	add_child(loose)
	expect(not p.is_pushable(loose), "and a moving body outside the group is left alone")

func _test_jumping_needs_the_floor() -> void:
	print("jumping")
	var p := _player()
	expect(p.can_jump(true, true), "pressing jump on the floor jumps")
	expect(not p.can_jump(true, false), "pressing it in mid-air does not")
	expect(not p.can_jump(false, true), "and standing on the floor is not enough by itself")
