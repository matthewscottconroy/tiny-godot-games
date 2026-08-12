extends Node

# Drives the real Knockback from scripts/knockback.gd rather than a copy of its
# impulse and decay maths.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_knockback_direction_from_hit()
	test_hit_sets_iframes()
	test_knockback_blocked_during_iframes()
	test_hit_allowed_again_after_iframes_expire()
	test_knockback_decays_each_frame()
	test_knockback_adds_to_control()
	test_iframes_decrement()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[knockback] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const DELTA := 0.016

func test_knockback_direction_from_hit() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2(0, 0), Vector2(100, 0))   # hit from the left
	expect(kb.velocity.x > 0.0, "knockback pushes player away from hit source")
	expect(kb.velocity.y == kb.up, "vertical launch is the configured `up` speed")
	expect(is_equal_approx(kb.velocity.x, kb.impulse), "horizontal launch is the full impulse")

func test_hit_sets_iframes() -> void:
	var kb := Knockback.new()
	expect(not kb.is_invincible(), "not invincible before any hit")
	expect(kb.hit(Vector2.ZERO, Vector2(100, 0)), "first hit lands and returns true")
	expect(kb.is_invincible(), "invincible immediately after a hit")

func test_knockback_blocked_during_iframes() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	var before := kb.velocity
	expect(not kb.hit(Vector2(200, 0), Vector2(100, 0)), "hit ignored while invincible")
	expect(kb.velocity == before, "a blocked hit does not change the knockback velocity")

func test_hit_allowed_again_after_iframes_expire() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	# Age past the i-frame window.
	var elapsed := 0.0
	while elapsed <= kb.iframe_time:
		kb.update(DELTA)
		elapsed += DELTA
	expect(not kb.is_invincible(), "i-frames expire after iframe_time")
	expect(kb.hit(Vector2.ZERO, Vector2(100, 0)), "a new hit lands once i-frames are gone")

func test_knockback_decays_each_frame() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	var launch_x := kb.velocity.x
	kb.update(DELTA)
	expect(kb.velocity.x < launch_x, "knockback decays per frame")
	expect(kb.velocity.x > 0.0, "one frame of decay does not zero it out")

func test_knockback_adds_to_control() -> void:
	# The owning body layers knockback on top of its own movement rather than
	# replacing it — that is the whole point of keeping it in its own vector.
	var kb := Knockback.new()
	kb.impulse = 300.0
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	var control_x := 200.0
	expect(is_equal_approx(control_x + kb.velocity.x, 500.0), "knockback adds to control velocity")

func test_iframes_decrement() -> void:
	var kb := Knockback.new()
	kb.hit(Vector2.ZERO, Vector2(100, 0))
	var before := kb.iframes
	kb.update(DELTA)
	expect(is_equal_approx(kb.iframes, before - DELTA), "iframes count down by delta each frame")
