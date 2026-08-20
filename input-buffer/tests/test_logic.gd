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
	await test_the_player_shows_what_the_buffer_is_doing()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

## The demo's readout and its hit flash, driven through the real player.
##
## Everything above drives the AttackBuffer, which is the reusable half. The
## player is what turns it into something on screen, and had nothing on it.
func test_the_player_shows_what_the_buffer_is_doing() -> void:
	print("the readout")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame
	var player: CharacterBody2D = scene.get_node("Player")
	var info: Label = player.get_node("InfoLabel")

	player._update_labels()
	expect(info.text.contains("READY"),
		"a rested attack reads READY (%s)" % info.text)
	expect(not info.text.contains("BUFFERED"),
		"with nothing queued behind it (%s)" % info.text)

	# Pressing puts it on cooldown, and the readout switches over.
	player._attack.press()
	expect(player._attack.consume(), "the press fires immediately")
	player._update_labels()
	expect(player._attack.cooldown_left() > 0.0,
		"the attack is now cooling down (%.2f)" % player._attack.cooldown_left())
	expect(info.text.contains("COOLDOWN"),
		"and the readout says so rather than READY (%s)" % info.text)
	expect(not info.text.contains("READY"), "the two states are not shown at once")

	# A press during the cooldown is remembered, and shown as remembered.
	player._attack.press()
	player._update_labels()
	expect(player._attack.buffer_left() > 0.0,
		"the second press is buffered (%.2f)" % player._attack.buffer_left())
	expect(info.text.contains("BUFFERED"),
		"and the readout shows it waiting (%s)" % info.text)

	# Run the cooldown out: the buffered press fires, and the readout settles.
	for _i in 120:
		player._attack.update(1.0 / 60.0)
		if player._attack.consume():
			player._fire_attack()
	player._update_labels()
	expect(player._attack.cooldown_left() == 0.0,
		"the cooldown finishes (%.2f)" % player._attack.cooldown_left())
	expect(player._attack.buffer_left() == 0.0,
		"and nothing is left buffered (%.2f)" % player._attack.buffer_left())
	expect(info.text.contains("READY"),
		"so the readout goes back to READY (%s)" % info.text)
	expect(not info.text.contains("BUFFERED"), "with no stale buffer on it")

	# The count on screen follows the attacks that actually landed.
	var status: Label = player.get_node("StatusLabel")
	var before_count: int = player._hits
	player._fire_attack()
	expect(player._hits == before_count + 1,
		"an attack landing adds one to the count (%d -> %d)" % [before_count, player._hits])
	player._update_labels()
	expect(status.text.contains(str(player._hits)),
		"and the count on screen agrees (%s)" % status.text)

	# The hit flash counts down and clears, rather than staying lit or growing.
	var lit: float = player._flash
	expect(lit > 0.0, "an attack lights the player up (%.2f)" % lit)
	player._physics_process(1.0 / 60.0)
	expect(player._flash < lit,
		"the flash fades (%.3f -> %.3f)" % [lit, player._flash])
	for _i in 120:
		player._physics_process(1.0 / 60.0)
	expect(player._flash == 0.0,
		"and goes out rather than counting past zero (%.3f)" % player._flash)

	# Nothing pressed, nothing happens — the grounded half of the jump.
	for _i in 60:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player settles on the ground")
	var resting: float = player.global_position.y
	var highest := resting
	for _i in 40:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"and stays there with no key pressed (rose %.1f px)" % (resting - highest))

	scene.queue_free()

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
