extends Node

# Drives the real player from scripts/player.gd. The previous suite ran a
# `class FakePlayer` copy of the timers, so flipping the `and` in the real
# script to `or` — which inverts the entire lesson — went unnoticed.
# See docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_coyote_timer_starts_on_leave()
	_test_grounded_keeps_it_full()
	_test_timers_tick_down()
	_test_both_windows_required()
	_test_jump_fires_when_both_are_live()
	_test_jump_consumes_both()
	_test_coyote_window_expires()
	_test_buffer_expires()
	_test_buffered_press_fires_on_landing()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_approx(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) < tol, label)

func _report() -> void:
	var summary := "[coyote-time] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 0.016

var _script: GDScript = load("res://scripts/player.gd")

# The player is a CharacterBody2D, so it needs to be in the tree — but tick_jump
# takes its inputs as parameters, so no physics or input is involved.
func _make() -> CharacterBody2D:
	var player := CharacterBody2D.new()
	player.set_script(_script)
	add_child(player)
	return player

func _ground(player: CharacterBody2D, frames: int = 3) -> void:
	for i in frames:
		player.tick_jump(STEP, true, false)

func _test_coyote_timer_starts_on_leave() -> void:
	print("coyote timer starts when leaving the floor")
	var p := _make()
	_ground(p)
	p.tick_jump(STEP, false, false)
	expect(p.coyote_left() > 0.0, "the window is open just after stepping off")
	expect_approx(p.coyote_left(), p.COYOTE_TIME - STEP, "and started full, minus one tick")

func _test_grounded_keeps_it_full() -> void:
	print("the window stays fresh while grounded")
	var p := _make()
	for i in 50:
		p.tick_jump(STEP, true, false)
	expect_approx(p.coyote_left(), p.COYOTE_TIME - STEP, "standing still does not drain it")

func _test_timers_tick_down() -> void:
	print("timers age")
	var p := _make()
	_ground(p)
	var first: float = p.coyote_left()
	p.tick_jump(STEP, false, false)
	p.tick_jump(STEP, false, false)
	expect(p.coyote_left() < first, "the coyote window shrinks in the air")
	expect(p.coyote_left() >= 0.0, "and never goes negative")

func _test_both_windows_required() -> void:
	print("either window alone is not a jump")
	# This is the assertion the old suite could not make, and the one that
	# catches `and` being changed to `or`.
	var only_coyote := _make()
	_ground(only_coyote)
	expect(not only_coyote.tick_jump(STEP, false, false),
		"coyote window open, no press queued -> no jump")

	var only_buffer := _make()
	# Airborne long enough for the coyote window to lapse, then press.
	only_buffer.tick_jump(STEP, false, false)
	var elapsed := 0.0
	while elapsed < only_buffer.COYOTE_TIME + 0.05:
		only_buffer.tick_jump(STEP, false, false)
		elapsed += STEP
	expect(is_zero_approx(only_buffer.coyote_left()), "the coyote window has closed")
	expect(not only_buffer.tick_jump(STEP, false, true),
		"press queued, coyote window closed -> no jump")
	expect(only_buffer.buffer_left() > 0.0, "but the press is remembered")

func _test_jump_fires_when_both_are_live() -> void:
	print("both windows live")
	var p := _make()
	_ground(p)
	expect(p.tick_jump(STEP, false, true), "stepping off and pressing fires the jump")

func _test_jump_consumes_both() -> void:
	print("a jump spends both windows")
	var p := _make()
	_ground(p)
	p.tick_jump(STEP, false, true)
	expect(is_zero_approx(p.coyote_left()), "the coyote window is cleared")
	expect(is_zero_approx(p.buffer_left()), "so is the buffer — no double jump from one press")
	expect(not p.tick_jump(STEP, false, false), "and the next frame does not fire again")

func _test_coyote_window_expires() -> void:
	print("the coyote window closes")
	var p := _make()
	_ground(p)
	var elapsed := 0.0
	while elapsed < p.COYOTE_TIME + 0.05:
		p.tick_jump(STEP, false, false)
		elapsed += STEP
	expect(is_zero_approx(p.coyote_left()), "it reaches zero")
	expect(not p.tick_jump(STEP, false, true), "a late press is too late")

func _test_buffer_expires() -> void:
	print("the buffer closes")
	var p := _make()
	p.tick_jump(STEP, false, true)
	var elapsed := 0.0
	while elapsed < p.BUFFER_TIME + 0.05:
		p.tick_jump(STEP, false, false)
		elapsed += STEP
	expect(is_zero_approx(p.buffer_left()), "the remembered press expires")
	# Landing now must not produce a jump from a press made far too early.
	expect(not p.tick_jump(STEP, true, false), "landing later does not fire a stale press")

func _test_buffered_press_fires_on_landing() -> void:
	print("a slightly early press still lands")
	var p := _make()
	# Falling, press just before touching down.
	p.tick_jump(STEP, false, false)
	p.tick_jump(STEP, false, true)
	expect(p.buffer_left() > 0.0, "the press is buffered while airborne")
	expect(p.tick_jump(STEP, true, false),
		"touching down within the buffer window fires it — the whole point")
