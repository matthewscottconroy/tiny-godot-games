extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_coyote_timer_starts_on_leave()
	_test_buffer_prevents_jump_after_expiry()
	_test_jump_fires_when_both_timers_active()
	_test_timers_tick_down()
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

# --- Minimal player state simulation ---

const COYOTE_TIME := 0.12
const BUFFER_TIME := 0.15
const JUMP_VEL    := -420.0
const GRAVITY     := 900.0

class FakePlayer:
	var velocity_y       := 0.0
	var coyote_timer     := 0.0
	var jump_buffer      := 0.0
	var was_on_floor     := false
	var jumped           := false

	func tick(delta: float, on_floor: bool, jump_pressed: bool) -> void:
		# Apply gravity
		if not on_floor:
			velocity_y += GRAVITY * delta

		# Detect leaving the floor
		if was_on_floor and not on_floor:
			coyote_timer = COYOTE_TIME

		# Refresh while grounded
		if on_floor:
			coyote_timer = COYOTE_TIME

		# Count down
		coyote_timer -= delta
		jump_buffer  -= delta
		if coyote_timer < 0.0:
			coyote_timer = 0.0
		if jump_buffer < 0.0:
			jump_buffer = 0.0

		# Record press
		if jump_pressed:
			jump_buffer = BUFFER_TIME

		# Fire jump
		jumped = false
		if coyote_timer > 0.0 and jump_buffer > 0.0:
			velocity_y   = JUMP_VEL
			coyote_timer = 0.0
			jump_buffer  = 0.0
			jumped       = true

		was_on_floor = on_floor

# --- Tests ---

func _test_coyote_timer_starts_on_leave() -> void:
	print("coyote timer starts when leaving floor")
	var p := FakePlayer.new()
	p.was_on_floor = true

	# Tick with on_floor=false: this is the frame we just left the floor
	p.tick(0.016, false, false)

	# Timer should have been set to COYOTE_TIME then ticked down by delta
	var expected := COYOTE_TIME - 0.016
	expect(p.coyote_timer > 0.0, "coyote timer is positive immediately after leaving floor")
	expect_approx(p.coyote_timer, expected, "coyote timer = COYOTE_TIME - delta after one frame")

func _test_buffer_prevents_jump_after_expiry() -> void:
	print("jump buffer prevents jump after expiry")
	var p := FakePlayer.new()
	p.was_on_floor = false
	p.coyote_timer = 0.0
	p.jump_buffer  = 0.0

	# Press jump while airborne with no coyote time — buffer fills but no jump fires
	p.tick(0.016, false, true)
	expect(!p.jumped, "no jump when coyote timer is zero (buffer fills)")
	expect(p.jump_buffer > 0.0, "buffer is now active")

	# Let the buffer expire (BUFFER_TIME + margin)
	var elapsed := 0.016
	while elapsed < BUFFER_TIME + 0.05:
		p.tick(0.016, false, false)
		elapsed += 0.016

	expect_approx(p.jump_buffer, 0.0, "buffer has fully expired")

	# Now land on floor — coyote timer refreshes but buffer is gone, so no jump
	p.was_on_floor = false
	p.tick(0.016, true, false)
	expect(!p.jumped, "no buffered jump after buffer expired before landing")

func _test_jump_fires_when_both_timers_active() -> void:
	print("jump fires when both coyote and buffer timers are active")
	var p := FakePlayer.new()

	# Give the player active coyote time (simulate just left floor)
	p.coyote_timer = COYOTE_TIME
	p.jump_buffer  = 0.0
	p.was_on_floor = false

	# Player presses jump mid-air while coyote window is open
	p.tick(0.016, false, true)
	expect(p.jumped, "jump fires when coyote_timer > 0 and jump is pressed")
	expect_approx(p.velocity_y, JUMP_VEL, "velocity.y set to JUMP_VEL on jump")
	expect_approx(p.coyote_timer, 0.0, "coyote timer cleared after jump")
	expect_approx(p.jump_buffer,  0.0, "jump buffer cleared after jump")

func _test_timers_tick_down() -> void:
	print("timers tick down correctly and clamp to zero")
	var p := FakePlayer.new()
	p.coyote_timer = 0.05
	p.jump_buffer  = 0.08
	p.was_on_floor = false

	p.tick(0.016, false, false)
	expect_approx(p.coyote_timer, 0.05 - 0.016, "coyote timer decremented by delta")
	expect_approx(p.jump_buffer,  0.08 - 0.016, "jump buffer decremented by delta")

	# Exhaust both timers
	p.coyote_timer = 0.001
	p.jump_buffer  = 0.001
	p.tick(0.016, false, false)
	expect_approx(p.coyote_timer, 0.0, "coyote timer clamped to zero (not negative)")
	expect_approx(p.jump_buffer,  0.0, "jump buffer clamped to zero (not negative)")

func _report() -> void:
	var summary := "[coyote-time] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
