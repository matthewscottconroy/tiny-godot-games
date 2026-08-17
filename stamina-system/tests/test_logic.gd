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
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

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
