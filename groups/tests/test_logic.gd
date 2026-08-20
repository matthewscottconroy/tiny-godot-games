extends Node

# Drives the real enemies from scripts/enemy.gd, and the real group calls the
# demo uses — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_damage_reduces_hp()
	_test_damage_clamps_at_zero()
	_test_lethal_damage_frees_the_node()
	_test_freeze_toggles()
	_test_frozen_enemy_does_not_move()
	_test_unfrozen_enemy_moves()
	_test_bounces_off_the_bounds()
	_test_it_bounces_off_all_four_walls()
	_test_it_survives_until_its_last_hit_point()
	_test_group_call_reaches_every_member()
	_test_group_call_skips_non_members()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[groups] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const GROUP := "enemies"
var _script: GDScript = load("res://scripts/enemy.gd")

func _make(pos: Vector2 = Vector2(300, 200), vel: Vector2 = Vector2.ZERO) -> Node2D:
	var e := Node2D.new()
	e.set_script(_script)
	add_child(e)
	e.position = pos
	e.vel = vel
	return e

func _test_damage_reduces_hp() -> void:
	print("damage")
	var e := _make()
	var before: int = e.hp
	e.take_damage(25)
	expect(e.hp == before - 25, "hp drops by exactly the amount dealt")

func _test_damage_clamps_at_zero() -> void:
	print("clamping")
	var e := _make()
	e.take_damage(e.hp - 1)
	e.take_damage(999)
	expect(e.hp == 0, "hp clamps at zero rather than going negative")

func _test_lethal_damage_frees_the_node() -> void:
	print("death")
	var e := _make()
	e.take_damage(9999)
	expect(e.is_queued_for_deletion(), "an enemy reduced to zero removes itself")

func _test_freeze_toggles() -> void:
	print("freeze toggle")
	var e := _make()
	expect(not e.frozen, "starts unfrozen")
	e.freeze_toggle()
	expect(e.frozen, "one call freezes")
	e.freeze_toggle()
	expect(not e.frozen, "another unfreezes — it is a toggle, not a setter")

func _test_frozen_enemy_does_not_move() -> void:
	print("frozen enemies hold still")
	var e := _make(Vector2(300, 200), Vector2(100, 0))
	e.freeze_toggle()
	var before: Vector2 = e.position
	e._process(0.1)
	expect(e.position == before, "a frozen enemy ignores its velocity")

func _test_unfrozen_enemy_moves() -> void:
	print("unfrozen enemies move")
	var e := _make(Vector2(300, 200), Vector2(100, 0))
	e._process(0.1)
	expect(e.position.x > 300.0, "an unfrozen enemy advances along its velocity")

func _test_bounces_off_the_bounds() -> void:
	print("bouncing")
	# Heading right, already at the right edge: the next step must turn it round
	# and keep it inside rather than letting it escape.
	var e := _make(Vector2(579, 200), Vector2(100, 0))
	e._process(0.5)
	expect(e.vel.x < 0.0, "velocity reverses at the boundary")
	expect(e.position.x <= 580.0, "and the position is clamped back inside")

## Bouncing on every wall, and only when it reaches one.
##
## The test above checks one edge, heading one way. The bounds are four
## comparisons across two lines, and any one of them flipping still leaves an
## enemy that bounces — just off the wrong wall, or off nothing.
func _test_it_bounces_off_all_four_walls() -> void:
	print("all four walls")
	var cases := [
		["right", Vector2(579, 200), Vector2(120, 0)],
		["left", Vector2(61, 200), Vector2(-120, 0)],
		["bottom", Vector2(300, 389), Vector2(0, 120)],
		["top", Vector2(300, 81), Vector2(0, -120)],
	]
	for case in cases:
		var e := _make(case[1], case[2])
		var before: Vector2 = e.vel
		e._process(0.5)
		expect_quiet(e.vel.dot(before) < 0.0,
			"%s: velocity reverses (%s -> %s)" % [case[0], before, e.vel])
	expect(_quiet_failures == 0, "it turns around at each of the four walls")

	# And stays inside all of them afterwards.
	for case in cases:
		var e := _make(case[1], case[2])
		for _i in 40:
			e._process(1.0 / 30.0)
		expect_quiet(e.position.x >= 60.0 and e.position.x <= 580.0
			and e.position.y >= 80.0 and e.position.y <= 390.0,
			"%s: stays inside after bouncing (%s)" % [case[0], e.position])
	expect(_quiet_failures == 0, "and never leaves the play area")

	# Well inside, it does not bounce at all — a comparison the wrong way round
	# would have it reversing every frame in open space.
	var free := _make(Vector2(320, 235), Vector2(120, 90))
	var heading: Vector2 = free.vel
	for _i in 5:
		free._process(1.0 / 60.0)
	expect(free.vel.is_equal_approx(heading),
		"an enemy in open space keeps going (%s -> %s)" % [heading, free.vel])
	expect(free.position.x > 320.0 and free.position.y > 235.0,
		"and travels the way it was pointed (%s)" % free.position)

## An enemy dies at zero and not before.
func _test_it_survives_until_its_last_hit_point() -> void:
	print("dying")
	var e := _make()
	var full: int = e.hp
	expect(full > 1, "an enemy starts with more than one hit point (%d)" % full)

	e.take_damage(full - 1)
	expect(e.hp == 1, "damage short of lethal leaves it on one (%d)" % e.hp)
	expect(not e.is_queued_for_deletion(),
		"and alive — an enemy that dies while it still has hit points is a demo "
		+ "with nothing to shoot at")
	expect(e.hp_label.text.contains("1"),
		"with the readout following (%s)" % e.hp_label.text)

	e.take_damage(1)
	expect(e.hp == 0, "the last point kills it (%d)" % e.hp)
	expect(e.is_queued_for_deletion(), "and it removes itself")

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("    (", label, " — failed)")

func _test_group_call_reaches_every_member() -> void:
	print("call_group")
	# The point of the demo: address many nodes without holding references.
	# Enemies join the group themselves in _ready(), which is the demo's point:
	# nothing has to keep a list of them.
	var a := _make(); var b := _make(); var c := _make()
	for e in [a, b, c]:
		expect(e.is_in_group(GROUP), "an enemy joins the group on its own")
	get_tree().call_group(GROUP, "take_damage", 10)
	expect(a.hp == 90 and b.hp == 90 and c.hp == 90,
		"one call_group reaches all three enemies")

func _test_group_call_skips_non_members() -> void:
	print("group membership")
	var member := _make()
	var outsider := _make()
	# Leaving the group must stop the calls reaching it — otherwise "group"
	# would mean nothing.
	outsider.remove_from_group(GROUP)
	get_tree().call_group(GROUP, "take_damage", 10)
	expect(member.hp == 90, "the member is affected")
	expect(outsider.hp == 100, "a node that left the group is untouched")
