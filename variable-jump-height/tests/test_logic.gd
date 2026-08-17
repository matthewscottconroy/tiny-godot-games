extends Node

# Drives the real player from scripts/player.gd. The previous suite recomputed
# the cut inline, so the rule the demo exists to teach could be inverted in the
# real script without an assertion failing — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_gravity_pulls_down()
	_test_jump_from_floor()
	_test_no_jump_in_midair()
	_test_release_while_rising_cuts()
	_test_hold_reaches_higher_than_tap()
	_test_release_while_falling_does_nothing()
	_test_cut_applies_once_per_jump()
	_test_landing_clears_the_flag()
	_test_fresh_player_is_not_mid_jump()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[variable-jump-height] %d/%d passed" % [_pass, _pass + _fail]
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

func _test_gravity_pulls_down() -> void:
	print("gravity")
	var p := _make()
	var vy: float = p.tick_vertical(0.0, STEP, false, false, false)
	expect(vy > 0.0, "an airborne player accelerates downward")

func _test_jump_from_floor() -> void:
	print("jumping")
	var p := _make()
	var vy: float = p.tick_vertical(0.0, STEP, true, true, false)
	expect(vy == p.JUMP_VEL, "a grounded press sets exactly JUMP_VEL")
	expect(p.is_jumping(), "and marks the jump as in progress")

func _test_no_jump_in_midair() -> void:
	print("no mid-air jump")
	var p := _make()
	var vy: float = p.tick_vertical(0.0, STEP, false, true, false)
	expect(vy > 0.0, "pressing in mid-air does not launch")

func _test_release_while_rising_cuts() -> void:
	print("the cut")
	var p := _make()
	var vy: float = p.tick_vertical(0.0, STEP, true, true, false)   # jump
	var before := vy
	vy = p.tick_vertical(vy, STEP, false, false, true)               # release
	expect(vy > before, "releasing early reduces the upward speed")
	expect(is_equal_approx(vy, (before + p.GRAVITY * STEP) * p.JUMP_CUT),
		"the remaining rise is scaled by JUMP_CUT")

func _test_hold_reaches_higher_than_tap() -> void:
	print("hold beats tap")
	# The whole point of the mechanic, measured as apex height rather than as an
	# implementation detail.
	var tap := _apex(true)
	var hold := _apex(false)
	expect(hold > tap, "holding reaches a higher apex than tapping")

## Simulate a jump to its apex, returning the height gained.
func _apex(release_early: bool) -> float:
	var p := _make()
	var vy: float = p.tick_vertical(0.0, STEP, true, true, false)
	var height := 0.0
	var frames := 0
	while vy < 0.0 and frames < 600:
		var released := release_early and frames == 3
		vy = p.tick_vertical(vy, STEP, false, false, released)
		height -= vy * STEP          # vy is negative while rising
		frames += 1
	return height

func _test_release_while_falling_does_nothing() -> void:
	print("releasing on the way down")
	var p := _make()
	p.tick_vertical(0.0, STEP, true, true, false)     # jump, sets _jumping
	var falling := 200.0                              # already descending
	var vy: float = p.tick_vertical(falling, STEP, false, false, true)
	expect(vy > falling, "a release while falling only adds gravity — no scaling")

func _test_cut_applies_once_per_jump() -> void:
	print("one cut per jump")
	var p := _make()
	var vy: float = p.tick_vertical(0.0, STEP, true, true, false)
	vy = p.tick_vertical(vy, STEP, false, false, true)   # first release cuts
	expect(not p.is_jumping(), "the jump is no longer cuttable")
	var before := vy
	vy = p.tick_vertical(vy, STEP, false, false, true)   # second release
	expect(vy > before, "a second release does not cut again")

func _test_fresh_player_is_not_mid_jump() -> void:
	print("initial state")
	# A player that started life flagged as jumping would have its very first
	# fall cut by a stray release, before it had ever jumped.
	var p := _make()
	expect(not p.is_jumping(), "a fresh player is not mid-jump")
	var vy: float = p.tick_vertical(-100.0, STEP, false, false, true)
	expect(vy > -100.0 and not is_equal_approx(vy, (-100.0 + p.GRAVITY * STEP) * p.JUMP_CUT),
		"and a release before any jump cuts nothing")

func _test_landing_clears_the_flag() -> void:
	print("landing")
	var p := _make()
	p.tick_vertical(0.0, STEP, true, true, false)
	p.tick_vertical(-100.0, STEP, true, false, false)    # touched down
	expect(not p.is_jumping(), "landing clears the jump flag")
