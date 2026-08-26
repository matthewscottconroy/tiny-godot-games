extends Node

# Drives the real player from scripts/player.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_starts_full_and_walking()
	_test_sprinting_drains()
	_test_not_sprinting_when_empty()
	_test_stamina_never_goes_below_zero()
	_test_regen_waits_before_starting()
	_test_regen_refills_to_the_cap()
	_test_stamina_never_exceeds_the_cap()
	_test_tapping_sprint_does_not_dodge_the_delay()
	_test_sprint_speed_applies_only_while_sprinting()
	_test_standing_still_does_not_burn_stamina()
	_test_the_readout_tells_the_three_states_apart()
	await _test_the_player_stays_down_untouched()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

## Sprinting takes a key *and* somewhere to run.
func _test_standing_still_does_not_burn_stamina() -> void:
	print("sprinting on the spot")
	var Player := load("res://scripts/player.gd")
	expect(Player.wants_to_sprint(true, 1.0), "running with the key down is sprinting")
	expect(Player.wants_to_sprint(true, -1.0), "in either direction")
	expect(not Player.wants_to_sprint(true, 0.0),
		"holding the key while standing still is not — the meter would empty "
		+ "while the player was not moving")
	expect(not Player.wants_to_sprint(false, 1.0),
		"and running without the key is not sprinting either")
	expect(not Player.wants_to_sprint(false, 0.0), "nor is doing neither")

## The bar and the readout say which of the three states the player is in.
func _test_the_readout_tells_the_three_states_apart() -> void:
	print("the readout")
	var m := _make()

	m._stamina = m.STAMINA_MAX
	m._sprinting = false
	expect(m.status_text() == "READY",
		"a full meter reads READY (%s)" % m.status_text())
	expect(m.bar_colour() == Color.GREEN,
		"and the bar is green (%s)" % m.bar_colour())

	m._sprinting = true
	expect(m.status_text() == "SPRINTING",
		"sprinting says so (%s)" % m.status_text())

	m._sprinting = false
	m._stamina = 0.0
	expect(m.status_text() == "DEPLETED",
		"an empty meter reads DEPLETED (%s)" % m.status_text())
	expect(m.bar_colour() == Color.ORANGE_RED,
		"with an amber bar (%s)" % m.bar_colour())

	# The warning colour arrives before the meter runs out, not with it.
	m._stamina = m.LOW_STAMINA - 1.0
	expect(m.bar_colour() == Color.ORANGE_RED,
		"the bar warns below the threshold (%s)" % m.bar_colour())
	expect(m.status_text() == "READY",
		"while there is still stamina to spend (%s)" % m.status_text())
	m._stamina = m.LOW_STAMINA + 1.0
	expect(m.bar_colour() == Color.GREEN,
		"and is green above it (%s)" % m.bar_colour())

	# Sprinting wins over the meter: a sprint that has just started on a low
	# meter still reads SPRINTING rather than DEPLETED.
	m._stamina = 0.0
	m._sprinting = true
	expect(m.status_text() == "SPRINTING",
		"sprinting is reported over an empty meter (%s)" % m.status_text())

## Nothing pressed, nothing happens.
##
## The jump reads Input, which a headless test cannot press — but its other half
## is is_on_floor(), and loosening the `and` to an `or` launches the player on
## every grounded frame.
func _test_the_player_stays_down_untouched() -> void:
	print("standing still")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	var player: CharacterBody2D = scene.get_node("Player")
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
	var summary := "[stamina-system] %d/%d passed" % [_pass, _pass + _fail]
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

func _run(p: CharacterBody2D, seconds: float, sprinting: bool) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		p.tick_stamina(STEP, sprinting)
		elapsed += STEP

func _test_starts_full_and_walking() -> void:
	print("initial state")
	var p := _make()
	expect(is_equal_approx(p.stamina(), p.STAMINA_MAX), "stamina starts full")
	expect(not p.is_sprinting(), "and the player is not sprinting")
	expect(is_equal_approx(p.current_speed(), p.SPEED), "so it moves at walking speed")

func _test_sprinting_drains() -> void:
	print("draining")
	var p := _make()
	_run(p, 0.5, true)
	expect(p.stamina() < p.STAMINA_MAX, "sprinting spends stamina")
	expect(p.is_sprinting(), "and the player is sprinting while it lasts")

func _test_not_sprinting_when_empty() -> void:
	print("empty bar")
	var p := _make()
	_run(p, 10.0, true)
	expect(is_zero_approx(p.stamina()), "the bar empties")
	expect(not p.is_sprinting(), "and wanting to sprint is no longer enough")
	expect(is_equal_approx(p.current_speed(), p.SPEED), "so speed drops back to walking")

func _test_stamina_never_goes_below_zero() -> void:
	print("lower clamp")
	var p := _make()
	_run(p, 20.0, true)
	expect(p.stamina() >= 0.0, "stamina clamps at zero rather than going negative")

func _test_regen_waits_before_starting() -> void:
	print("the regen delay")
	var p := _make()
	_run(p, 1.0, true)
	var after_sprint: float = p.stamina()
	# Half the delay: nothing should have come back yet.
	_run(p, p.REGEN_DELAY * 0.5, false)
	expect(is_equal_approx(p.stamina(), after_sprint),
		"stamina does not start refilling until the delay has passed")

func _test_regen_refills_to_the_cap() -> void:
	print("regeneration")
	var p := _make()
	_run(p, 1.5, true)
	var drained: float = p.stamina()
	_run(p, p.REGEN_DELAY + 1.0, false)
	expect(p.stamina() > drained, "stamina comes back once the delay expires")

func _test_stamina_never_exceeds_the_cap() -> void:
	print("upper clamp")
	var p := _make()
	_run(p, 30.0, false)
	expect(p.stamina() <= p.STAMINA_MAX, "regeneration stops at the maximum")

func _test_tapping_sprint_does_not_dodge_the_delay() -> void:
	print("tapping")
	# Releasing sprint for a single frame must not restart regeneration —
	# otherwise tapping the key sprints indefinitely for free.
	var p := _make()
	_run(p, 1.0, true)
	var before: float = p.stamina()
	for i in 20:
		p.tick_stamina(STEP, false)     # one frame off
		p.tick_stamina(STEP, true)      # straight back on
	expect(p.stamina() < before, "alternating still spends stamina overall")

func _test_sprint_speed_applies_only_while_sprinting() -> void:
	print("speed")
	var p := _make()
	p.tick_stamina(STEP, true)
	expect(is_equal_approx(p.current_speed(), p.SPRINT_SPEED), "sprinting is faster")
	p.tick_stamina(STEP, false)
	expect(is_equal_approx(p.current_speed(), p.SPEED), "and walking is not")
	expect(p.SPRINT_SPEED > p.SPEED, "sprint speed is actually higher")
