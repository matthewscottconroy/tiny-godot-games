extends Node

# Drives the real player from scripts/player.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_dash_available_at_rest()
	_test_dash_starts()
	_test_no_dash_while_dashing()
	_test_no_dash_during_cooldown()
	_test_dash_ends_after_its_duration()
	_test_dash_available_again_after_cooldown()
	_test_iframes_outlast_the_dash()
	_test_iframes_end_before_the_cooldown()
	_test_dash_follows_facing()
	_test_timers_clamp_at_zero()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[dash-ability] %d/%d passed" % [_pass, _pass + _fail]
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

# Run the dash to completion, ticking both the dash and the timers.
func _run(p: CharacterBody2D, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		p.tick_timers(STEP)
		p.advance_dash(STEP)
		elapsed += STEP

func _test_dash_available_at_rest() -> void:
	print("initial state")
	var p := _make()
	expect(not p.is_dashing(), "not dashing to begin with")
	expect(is_zero_approx(p.cooldown_left()), "and nothing on cooldown")

func _test_dash_starts() -> void:
	print("starting a dash")
	var p := _make()
	expect(p.try_dash(), "the first dash is allowed")
	expect(p.is_dashing(), "and it begins")

func _test_no_dash_while_dashing() -> void:
	print("no dash during a dash")
	var p := _make()
	p.try_dash()
	expect(not p.try_dash(), "a second dash cannot start while one is running")

func _test_no_dash_during_cooldown() -> void:
	print("cooldown blocks")
	var p := _make()
	p.try_dash()
	_run(p, p.DASH_DURATION + STEP)
	expect(not p.is_dashing(), "the dash has ended")
	expect(not p.try_dash(), "but the cooldown still blocks the next one")

func _test_dash_ends_after_its_duration() -> void:
	print("dash duration")
	var p := _make()
	p.try_dash()
	_run(p, p.DASH_DURATION * 0.5)
	expect(p.is_dashing(), "still dashing halfway through")
	_run(p, p.DASH_DURATION)
	expect(not p.is_dashing(), "finished after the full duration")

func _test_dash_available_again_after_cooldown() -> void:
	print("recovery")
	var p := _make()
	p.try_dash()
	_run(p, p.DASH_COOLDOWN + 0.05)
	expect(p.try_dash(), "the dash is available again once the cooldown expires")

func _test_iframes_outlast_the_dash() -> void:
	print("invincibility covers the dash")
	var p := _make()
	p.try_dash()
	expect(p.is_invincible(), "a dash grants invincibility immediately")
	_run(p, p.DASH_DURATION + STEP)
	# The overlap is what makes a dash an escape rather than just fast movement.
	expect(p.is_invincible(), "and it outlasts the dash itself")

func _test_iframes_end_before_the_cooldown() -> void:
	print("invincibility is not permanent")
	var p := _make()
	p.try_dash()
	_run(p, p.IFRAME_TIME + 0.05)
	expect(not p.is_invincible(), "the window closes well before the dash is ready again")
	expect(p.cooldown_left() > 0.0, "while the cooldown is still running")

func _test_dash_follows_facing() -> void:
	print("direction")
	var p := _make()
	p._facing = -1.0
	p.try_dash()
	expect(p.dash_direction() < 0.0, "the dash goes the way the player is facing")
	_run(p, p.DASH_COOLDOWN + 0.05)
	p._facing = 1.0
	p.try_dash()
	expect(p.dash_direction() > 0.0, "and follows a new facing on the next dash")

func _test_timers_clamp_at_zero() -> void:
	print("clamping")
	var p := _make()
	p.try_dash()
	_run(p, 5.0)
	expect(p.cooldown_left() >= 0.0, "the cooldown stops at zero rather than going negative")
	expect(not p.is_invincible(), "and invincibility does not come back round")
