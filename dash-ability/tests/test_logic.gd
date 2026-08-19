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
	await test_the_readout_names_what_is_running()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

## The readout, and the ghost trail, driven through the real scene.
func test_the_readout_names_what_is_running() -> void:
	print("the readout")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame
	var player: CharacterBody2D = scene.get_node("Player")
	var label: Label = player.get_node("InfoLabel")

	player._dashing = false
	player._iframes = 0.0
	player._cooldown = 0.0
	player._update_label()
	expect(label.text == "READY",
		"with nothing running it says READY (%s)" % label.text)

	expect(player.try_dash(), "a dash starts")
	player._update_label()
	expect(label.text.contains("DASHING"), "and is named while it runs (%s)" % label.text)
	expect(label.text.contains("CD"), "alongside the cooldown it just started")

	# Once the dash ends the i-frames are still running, and they get named in
	# its place — that overlap is the point of the ability.
	while player.advance_dash(1.0 / 60.0):
		player.tick_timers(1.0 / 60.0)
	player._update_label()
	expect(not label.text.contains("DASHING"), "the dash stops being named (%s)" % label.text)
	expect(player._iframes > 0.0, "while the i-frames outlast it (%.2f)" % player._iframes)
	expect(label.text.contains("IFRAMES"), "and are named instead (%s)" % label.text)

	# Everything runs out and it goes back to READY, rather than to a blank bar.
	for _i in 200:
		player.tick_timers(1.0 / 60.0)
	player._update_label()
	expect(player._iframes == 0.0 and player._cooldown == 0.0, "the timers run out")
	expect(label.text == "READY", "and the readout says READY again (%s)" % label.text)

	# advance_dash on a player that is not dashing reports that nothing is
	# running. Saying otherwise would leave the caller trailing ghosts and
	# holding velocity for a dash that ended.
	player._dashing = false
	expect(not player.advance_dash(1.0 / 60.0),
		"ageing a dash that is not running reports nothing running")

	# The trail is capped, and it fills, through the demo's own loop rather than
	# a copy of it here — a cap tested by reimplementing the trimming is a cap
	# tested against itself.
	player._cooldown = 0.0
	player._ghosts.clear()
	expect(player.try_dash(), "a second dash starts once the cooldown is up")
	for _i in 40:
		player._dashing = true          # hold it open past its natural duration
		player._physics_process(1.0 / 60.0)
	expect(player._ghosts.size() == player.GHOST_MAX,
		"the trail fills to its cap and holds there (%d of %d)"
		% [player._ghosts.size(), player.GHOST_MAX])
	player._dashing = false

	# The aim survives a released key. With no input the axis reads zero, and
	# writing sign(0) into the facing would leave the next dash with no
	# direction to go in at all.
	player._dashing = false
	player._cooldown = 0.0
	player._facing = -1.0
	for _i in 20:
		player._physics_process(1.0 / 60.0)
	expect(player._facing == -1.0,
		"an untouched key leaves the facing alone (%.0f)" % player._facing)
	expect(player.try_dash(), "so a dash can still start")
	expect(player.dash_direction() != 0.0,
		"and it has a direction to travel in (%.0f)" % player.dash_direction())

	# Nothing pressed, nothing happens: neither a dash nor a jump. The cooldown
	# is the tell — a dash that started and finished between two assertions
	# still leaves its cooldown behind.
	player._dashing = false
	player._cooldown = 0.0
	player._iframes = 0.0
	player._ghosts.clear()
	for _i in 60:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player settles on the ground")
	expect(not player._dashing,
		"and does not dash on its own, though the cooldown is up")
	expect(player._cooldown == 0.0,
		"nor has one started and ended unnoticed (cooldown %.2f)" % player._cooldown)
	expect(player._ghosts.is_empty(),
		"and no afterimages were left behind (%d)" % player._ghosts.size())
	var resting: float = player.global_position.y
	var highest := resting
	for _i in 40:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"nor jump (rose %.1f px)" % (resting - highest))

	scene.queue_free()

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
