extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_attack_fires_when_ready()
	test_attack_blocked_during_cooldown()
	test_buffer_queues_during_cooldown()
	test_buffer_fires_when_cooldown_clears()
	test_buffer_expires_without_firing()
	test_cooldown_decrements()
	test_consume_fires_only_once_per_press()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[input-buffer] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const ATTACK_COOLDOWN := 0.5
const BUFFER_WINDOW   := 0.18
const DELTA           := 0.016

# These tests drive the real InputBuffer from scripts/input_buffer.gd rather
# than a copy of its logic, so a change to the component shows up here.
func _make() -> InputBuffer:
	var buf := InputBuffer.new()
	buf.cooldown_time = ATTACK_COOLDOWN
	buf.buffer_window = BUFFER_WINDOW
	return buf

# One frame of the player's order of operations: age the timers, apply the
# press, then ask whether the action may fire.
func _tick(buf: InputBuffer, pressed: bool, delta: float = DELTA) -> bool:
	buf.update(delta)
	if pressed:
		buf.press()
	return buf.consume()

func test_attack_fires_when_ready() -> void:
	var buf := _make()
	expect(_tick(buf, true), "attack fires immediately when cooldown is 0 and pressed")

func test_attack_blocked_during_cooldown() -> void:
	var buf := _make()
	_tick(buf, true)                       # fires, starting the cooldown
	expect(not _tick(buf, true), "attack doesn't fire during cooldown even with press")
	expect(buf.buffer_left() > 0.0, "press sets buffer even during cooldown")

func test_buffer_queues_during_cooldown() -> void:
	var buf := _make()
	_tick(buf, true)                       # fires
	_tick(buf, true)                       # blocked, but queued
	expect(buf.buffer_left() > 0.0, "buffer accumulates when pressed during cooldown")

func test_buffer_fires_when_cooldown_clears() -> void:
	var buf := _make()
	_tick(buf, true)                       # fires; cooldown = 0.5
	# Press with a hair of cooldown left, then let that last sliver expire.
	var elapsed := DELTA
	while buf.cooldown_left() > DELTA:
		_tick(buf, false)
		elapsed += DELTA
	expect(buf.cooldown_left() > 0.0, "cooldown still running just before it clears")
	var fired_on_press := _tick(buf, true)
	# update() ages the cooldown to 0 *before* consume() looks at it, so a press
	# on this frame fires the same frame rather than waiting for the next one.
	expect(fired_on_press, "queued press fires on the frame the cooldown reaches 0")

func test_buffer_expires_without_firing() -> void:
	var buf := _make()
	_tick(buf, true)                       # fires; cooldown = 0.5
	_tick(buf, true)                       # queued during cooldown
	# Drain the buffer window without ever clearing the cooldown.
	for i in 15:
		_tick(buf, false)
	expect(is_zero_approx(buf.buffer_left()), "buffer expires after enough frames")
	expect(buf.cooldown_left() > 0.0, "cooldown still running when buffer expired")

func test_cooldown_decrements() -> void:
	var buf := _make()
	_tick(buf, true)
	var before := buf.cooldown_left()
	_tick(buf, false)
	expect(is_equal_approx(buf.cooldown_left(), before - DELTA), "cooldown decrements by delta")
	expect(is_equal_approx(buf.cooldown_ratio(), buf.cooldown_left() / ATTACK_COOLDOWN),
		"cooldown_ratio tracks the remaining cooldown")

func test_consume_fires_only_once_per_press() -> void:
	var buf := _make()
	buf.press()
	expect(buf.consume(), "consume() is true on the first call after a press")
	expect(not buf.consume(), "consume() is false on the second call — the press is spent")
