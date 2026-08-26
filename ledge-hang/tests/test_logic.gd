extends Node

# Drives the real player from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_player_starts_on_the_ground()
	_test_gravity_and_landing()
	_test_jumping_from_the_ground()
	_test_walking()
	_test_falling_past_a_ledge_grabs_it()
	_test_rising_past_a_ledge_does_not()
	_test_a_ledge_out_of_reach_is_not_grabbed()
	_test_hanging_holds_the_player_still()
	_test_jumping_pulls_up_onto_the_platform()
	_test_pressing_down_lets_go()
	_test_the_player_stays_on_screen()
	_test_the_right_hand_corner_is_grabbable_too()
	_test_hanging_puts_the_player_beside_the_corner()
	_test_pulling_up_lands_on_top_of_the_platform()
	_test_a_platform_pushes_out_the_way_it_was_entered()
	_test_a_held_key_counts_once()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[ledge-hang] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _run(m: Node2D, frames: int, axis: float = 0.0) -> void:
	for i in frames:
		m.tick(STEP, axis, false, false)

## Put the player just above a platform's left corner, falling.
func _falling_past_left_corner(m: Node2D, plat: Rect2) -> void:
	m._pos = Vector2(plat.position.x - m.PLAYER_W * 0.5, plat.position.y + m.PLAYER_H)
	m._vel = Vector2(0.0, 60.0)

func _a_platform(m: Node2D) -> Rect2:
	return m._platforms[1]

func _test_the_player_starts_on_the_ground() -> void:
	print("the start")
	var m := _make()
	expect(m._state == m.PState.NORMAL, "the player starts standing, not hanging")
	expect(m._platforms.size() > 1, "with platforms to climb")

func _test_gravity_and_landing() -> void:
	print("falling")
	var m := _make()
	m._pos = Vector2(320.0, 100.0)
	m._vel = Vector2.ZERO
	m.tick(STEP, 0.0, false, false)
	expect(m._vel.y > 0.0, "the player falls")
	_run(m, 300)
	expect(m._on_floor, "and lands on the ground below")
	expect(is_zero_approx(m._vel.y), "with the fall stopped")

func _test_jumping_from_the_ground() -> void:
	print("jumping")
	var m := _make()
	m._pos = Vector2(320.0, 100.0)
	_run(m, 300)
	expect(m._on_floor, "standing on the floor")
	m.tick(STEP, 0.0, true, false)
	expect(m._vel.y < 0.0, "jump sends the player up")

	var airborne := _make()
	airborne._pos = Vector2(320.0, 100.0)
	airborne.tick(STEP, 0.0, true, false)
	expect(airborne._vel.y > 0.0, "but a jump in mid-air does nothing")

func _test_walking() -> void:
	print("walking")
	var m := _make()
	m._pos = Vector2(320.0, 100.0)
	_run(m, 300)
	var x: float = m._pos.x
	_run(m, 30, 1.0)
	expect(m._pos.x > x, "holding right walks right")
	_run(m, 60, -1.0)
	expect(m._pos.x < x, "and left walks left")

func _test_falling_past_a_ledge_grabs_it() -> void:
	print("grabbing")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.HANGING, "falling past a corner catches it")
	expect(m._hang_edge.x == plat.position.x, "the corner that was passed")

func _test_rising_past_a_ledge_does_not() -> void:
	print("on the way up")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	# Same place, travelling upwards: a player who jumped past the ledge should
	# clear it rather than being yanked into a hang.
	m._vel = Vector2(0.0, -60.0)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.NORMAL, "a rising player does not grab the ledge")

func _test_a_ledge_out_of_reach_is_not_grabbed() -> void:
	print("out of reach")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m._pos.x -= m.LEDGE_GRAB_RANGE * 4.0
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.NORMAL, "a corner too far to the side is not grabbed")

	var below := _make()
	_falling_past_left_corner(below, plat)
	below._pos.y += below.LEDGE_VERT_RANGE * 4.0
	below.tick(STEP, 0.0, false, false)
	expect(below._state == below.PState.NORMAL, "and neither is one well above the player's head")

func _test_hanging_holds_the_player_still() -> void:
	print("hanging")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.HANGING, "hanging")
	# The grab happens at the end of a falling frame; the snap to the ledge
	# happens on the next one, so that is where the hang position settles.
	m.tick(STEP, 0.0, false, false)
	var hung_at: Vector2 = m._pos
	_run(m, 60, 1.0)
	expect(m._pos == hung_at, "gravity and the walk keys do nothing while hanging")
	expect(m._vel == Vector2.ZERO, "the player is held in place")

func _test_jumping_pulls_up_onto_the_platform() -> void:
	print("climbing up")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.HANGING, "hanging from the ledge")
	m.tick(STEP, 0.0, true, false)
	expect(m._state == m.PState.NORMAL, "jump lets go of the ledge")
	expect(m._vel.y < 0.0, "with an upward boost to clear it")
	expect(m._pos.y < plat.position.y + m.PLAYER_H, "and the player is lifted above the edge")

func _test_pressing_down_lets_go() -> void:
	print("dropping off")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	m.tick(STEP, 0.0, false, true)
	expect(m._state == m.PState.NORMAL, "down lets go")
	expect(m._vel.y > 0.0, "and the player drops")

func _test_the_player_stays_on_screen() -> void:
	print("the edges of the screen")
	var m := _make()
	m._pos = Vector2(320.0, 100.0)
	_run(m, 600, -1.0)
	expect(m._pos.x >= m.PLAYER_W * 0.5, "walking left stops at the edge of the screen")
	_run(m, 900, 1.0)
	expect(m._pos.x <= 640.0 - m.PLAYER_W * 0.5, "and walking right at the other one")

## The right-hand corner catches too, and it is the right-hand one.
##
## Every grab test above uses the left corner, so the right one's edge — the
## platform's near side plus its width — was never computed with anything to
## check it against. Get that wrong and only half the ledges in the level work.
func _test_the_right_hand_corner_is_grabbable_too() -> void:
	print("the other corner")
	var m := _make()
	var plat := _a_platform(m)

	# Approaching the right corner from outside the platform, falling.
	m._state = m.PState.NORMAL
	m._pos = Vector2(plat.end.x + m.PLAYER_W * 0.5, plat.position.y + m.PLAYER_H)
	m._vel = Vector2(0.0, 200.0)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.HANGING,
		"falling past the right corner catches it (%d)" % m._state)
	expect(is_equal_approx(m._hang_edge.x, plat.end.x),
		"on the far side of the platform (%.1f, platform ends at %.1f)"
		% [m._hang_edge.x, plat.end.x])
	expect(is_equal_approx(m._hang_edge.y, plat.position.y),
		"at its top (%.1f)" % m._hang_edge.y)

## Hanging puts the player beside the corner, on the side it came from.
func _test_hanging_puts_the_player_beside_the_corner() -> void:
	print("where a hang holds you")
	# Left corner: the player is outside the platform, so it hangs to the left
	# of the edge — half its width clear of it.
	var left := _make()
	var lplat := _a_platform(left)
	_falling_past_left_corner(left, lplat)
	left.tick(STEP, 0.0, false, false)
	left.tick(STEP, 0.0, false, false)
	expect(left._state == left.PState.HANGING, "hanging on the left corner")
	expect(left._pos.x < lplat.position.x,
		"the player hangs outside the platform, not under it (%.1f < %.1f)"
		% [left._pos.x, lplat.position.x])
	expect(is_equal_approx(left._pos.x, lplat.position.x - left.PLAYER_W * 0.5),
		"half a body clear of the edge (%.1f)" % left._pos.x)
	expect(left._pos.y > lplat.position.y,
		"and below its top, which is what hanging is (%.1f > %.1f)"
		% [left._pos.y, lplat.position.y])

	# Right corner: the same, mirrored.
	var right := _make()
	var rplat := _a_platform(right)
	right._state = right.PState.NORMAL
	right._pos = Vector2(rplat.end.x + right.PLAYER_W * 0.5, rplat.position.y + right.PLAYER_H)
	right._vel = Vector2(0.0, 200.0)
	right.tick(STEP, 0.0, false, false)
	right.tick(STEP, 0.0, false, false)
	expect(right._state == right.PState.HANGING, "hanging on the right corner")
	expect(right._pos.x > rplat.end.x,
		"the player hangs off the far side (%.1f > %.1f)" % [right._pos.x, rplat.end.x])
	expect(is_equal_approx(right._pos.x, rplat.end.x + right.PLAYER_W * 0.5),
		"half a body clear of that edge too (%.1f)" % right._pos.x)

## Pulling up puts the player on top of the platform, not back under it.
func _test_pulling_up_lands_on_top_of_the_platform() -> void:
	print("pulling up")
	var m := _make()
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.HANGING, "hanging first")

	m.tick(STEP, 0.0, true, false)      # jump
	expect(m._state == m.PState.NORMAL, "the jump lets go (%d)" % m._state)
	expect(m._pos.y < plat.position.y,
		"placing the player above the platform top, not below it (%.1f < %.1f)"
		% [m._pos.y, plat.position.y])
	expect(m._vel.y < 0.0, "moving upward (%.0f)" % m._vel.y)

## A platform pushes the player out the way it was entered.
##
## The push picks the shallower axis and then the side, from the two centres.
## Compare them the wrong way round and walking into a platform's left face
## teleports the player out of its right one.
func _test_a_platform_pushes_out_the_way_it_was_entered() -> void:
	print("pushing out")
	var m := _make()
	var plat := _a_platform(m)

	# Overlapping the platform's left face by a little, deep enough vertically
	# that the horizontal overlap is the shallower one.
	m._state = m.PState.NORMAL
	m._pos = Vector2(plat.position.x + 4.0, plat.position.y + plat.size.y)
	m._vel = Vector2.ZERO
	m._resolve_collisions()
	expect(m._pos.x < plat.position.x,
		"entering from the left is pushed back out to the left (%.1f < %.1f)"
		% [m._pos.x, plat.position.x])

	var other := _make()
	var oplat := _a_platform(other)
	other._state = other.PState.NORMAL
	other._pos = Vector2(oplat.end.x - 4.0, oplat.position.y + oplat.size.y)
	other._vel = Vector2.ZERO
	other._resolve_collisions()
	expect(other._pos.x > oplat.end.x,
		"and from the right, back out to the right (%.1f > %.1f)"
		% [other._pos.x, oplat.end.x])

	# Landing on top is the vertical case, and it is what sets _on_floor —
	# which starts each resolve as false, or a player who has walked off an
	# edge keeps jumping from thin air.
	var lander := _make()
	var lplat := _a_platform(lander)
	lander._state = lander.PState.NORMAL
	lander._pos = Vector2(lplat.position.x + lplat.size.x * 0.5, lplat.position.y + 4.0)
	lander._vel = Vector2(0.0, 200.0)
	lander._resolve_collisions()
	expect(lander._on_floor, "landing on a platform reports floor contact")
	expect(is_equal_approx(lander._pos.y, lplat.position.y),
		"with the player's feet on its top (%.1f)" % lander._pos.y)

	var airborne := _make()
	_a_platform(airborne)
	airborne._state = airborne.PState.NORMAL
	airborne._pos = Vector2(320.0, 100.0)
	airborne._vel = Vector2(0.0, 200.0)
	airborne._resolve_collisions()
	expect(not airborne._on_floor,
		"while touching nothing reports none — every resolve starts from false")

	# Head-bump: entering a platform from underneath, moving up. The player is
	# pushed back down and loses its upward speed, or it keeps rising into the
	# platform and pops out of the top of it.
	var bumper := _make()
	var bplat: Rect2 = bumper._platforms[1]
	bumper._state = bumper.PState.NORMAL
	# Feet just below the platform's underside, head 4px inside it.
	bumper._pos = Vector2(bplat.position.x + bplat.size.x * 0.5,
		bplat.end.y + bumper.PLAYER_H - 4.0)
	bumper._vel = Vector2(0.0, -200.0)
	bumper._resolve_collisions()
	expect(bumper._pos.y - bumper.PLAYER_H >= bplat.end.y - 0.01,
		"a head-bump pushes the player back below the platform (head at %.1f, "
		+ "underside %.1f)" % [bumper._pos.y - bumper.PLAYER_H, bplat.end.y])
	expect(bumper._vel.y == 0.0,
		"and stops it rising (%.0f)" % bumper._vel.y)
	expect(not bumper._on_floor, "without calling that a floor")

	# The horizontal push reads the player's own centre. Entering the left face
	# of a platform whose middle is far to the right, a centre computed half a
	# body too far left is still left of the platform's middle — so the case
	# that separates them is entering the *right* face of a platform whose
	# middle is close by.
	# The horizontal push reads the player's own centre, and the only way to see
	# that is to stand just past a platform's middle: a centre computed half a
	# body too far left then falls on the other side of it, and the player is
	# thrown the wrong way across the platform. The ground is wide and deep
	# enough for the horizontal overlap to be the shallower one.
	var ground := _make()
	var gplat: Rect2 = ground._platforms[0]        # x 0..640, y 440..480
	var just_right := gplat.position.x + gplat.size.x * 0.5 + 10.0
	ground._state = ground.PState.NORMAL
	ground._pos = Vector2(just_right, gplat.end.y - 2.0)
	ground._vel = Vector2.ZERO
	ground._resolve_collisions()
	expect(ground._pos.x > just_right,
		"a player just right of a platform's middle is pushed right (%.1f from %.1f)"
		% [ground._pos.x, just_right])

	var just_left := gplat.position.x + gplat.size.x * 0.5 - 10.0
	var mirror := _make()
	mirror._state = mirror.PState.NORMAL
	mirror._pos = Vector2(just_left, gplat.end.y - 2.0)
	mirror._vel = Vector2.ZERO
	mirror._resolve_collisions()
	expect(mirror._pos.x < just_left,
		"and one just left of it, left (%.1f from %.1f)" % [mirror._pos.x, just_left])

	# The vertical push compares against the platform's own middle. A player
	# level with the platform's top is above its middle and lands on it; a
	# middle computed half a platform too high would call the same player
	# "below" and shove it down through the floor.
	var straddler := _make()
	var splat: Rect2 = straddler._platforms[1]     # y 340..358
	straddler._state = straddler.PState.NORMAL
	# Feet level with the platform's underside, so the player's own centre sits
	# on the platform's top edge — between the true middle and a middle
	# computed half a platform too high.
	straddler._pos = Vector2(splat.position.x + splat.size.x * 0.5,
		splat.position.y + splat.size.y)
	straddler._vel = Vector2(0.0, 60.0)
	var dropped_from: float = straddler._pos.y
	straddler._resolve_collisions()
	expect(straddler._pos.y < dropped_from,
		"a player level with a platform's top is lifted onto it, not pushed "
		+ "through (%.1f from %.1f)" % [straddler._pos.y, dropped_from])
	expect(straddler._on_floor, "and is standing on it")

## A held key is one press, not a press every frame.
##
## Both the pull-up and the drop are edge-triggered. Lose the edge and holding
## jump pulls the player up the instant it grabs a ledge — and holding down
## drops it again immediately, so a ledge can never be hung from at all.
func _test_a_held_key_counts_once() -> void:
	print("edges")
	var m := _make()
	expect(m.just_pressed(true, false), "a key going down is a press")
	expect(not m.just_pressed(true, true), "a key held is not a press again")
	expect(not m.just_pressed(false, true), "a key coming up is not a press")
	expect(not m.just_pressed(false, false), "and neither is a key left alone")

	# Driven through the state machine: hanging, with jump held from before the
	# grab, the player stays hung.
	var plat := _a_platform(m)
	_falling_past_left_corner(m, plat)
	m.tick(STEP, 0.0, false, false)
	m.tick(STEP, 0.0, false, false)
	expect(m._state == m.PState.HANGING, "hanging")

	for i in 30:
		m.tick(STEP, 0.0, false, false)      # jump held, but never a fresh edge
	expect(m._state == m.PState.HANGING,
		"holding a key that is never a fresh press leaves it hanging (%d)" % m._state)

	m.tick(STEP, 0.0, true, false)
	expect(m._state == m.PState.NORMAL, "and one real press lets go")
