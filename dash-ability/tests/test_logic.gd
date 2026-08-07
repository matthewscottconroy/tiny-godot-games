extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_dash_activates_when_ready()
	test_dash_blocked_during_cooldown()
	test_dash_timer_expires()
	test_cooldown_decrements()
	test_iframes_active_during_dash()
	test_iframes_expire()
	test_ghost_count_capped()
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

const DASH_DURATION := 0.14
const DASH_COOLDOWN := 0.65
const IFRAME_TIME   := 0.20
const GHOST_MAX     := 8

func _try_dash(cooldown: float, dashing: bool) -> Dictionary:
	if cooldown <= 0.0 and not dashing:
		return {"started": true, "timer": DASH_DURATION, "cooldown": DASH_COOLDOWN, "iframes": IFRAME_TIME}
	return {"started": false, "timer": 0.0, "cooldown": cooldown, "iframes": 0.0}

func test_dash_activates_when_ready() -> void:
	var r := _try_dash(0.0, false)
	expect(r["started"], "dash starts when cooldown=0 and not already dashing")

func test_dash_blocked_during_cooldown() -> void:
	var r := _try_dash(0.3, false)
	expect(not r["started"], "dash blocked while cooldown > 0")

func test_dash_blocked_while_dashing() -> void:
	var r := _try_dash(0.0, true)
	expect(not r["started"], "dash blocked while already dashing")

func test_dash_timer_expires() -> void:
	var timer := DASH_DURATION
	timer -= 0.016 * 9  # ~9 frames
	expect(timer > 0.0, "dash timer not yet expired after 9 frames")
	timer -= DASH_DURATION
	expect(timer <= 0.0, "dash timer expired")

func test_cooldown_decrements() -> void:
	var cd := DASH_COOLDOWN
	cd = maxf(cd - 0.016, 0.0)
	expect(cd < DASH_COOLDOWN, "cooldown decrements each frame")

func test_iframes_active_during_dash() -> void:
	var r := _try_dash(0.0, false)
	expect(r["iframes"] > 0.0, "iframes set when dash starts")

func test_iframes_expire() -> void:
	var iframes := IFRAME_TIME
	iframes = maxf(iframes - IFRAME_TIME - 0.01, 0.0)
	expect(iframes == 0.0, "iframes reach zero after duration")

func test_ghost_count_capped() -> void:
	var ghosts: Array[Vector2] = []
	for i in GHOST_MAX + 5:
		ghosts.append(Vector2(i * 10, 0))
		if ghosts.size() > GHOST_MAX:
			ghosts.pop_front()
	expect(ghosts.size() == GHOST_MAX, "ghost trail capped at GHOST_MAX")
