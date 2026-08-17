extends Node

# Drives the real simulation from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_boxes_start_in_the_air()
	_test_everything_falls_at_first()
	_test_a_light_box_floats()
	_test_a_heavy_box_sinks()
	_test_a_floating_box_bobs_around_the_surface()
	_test_denser_boxes_ride_lower()
	_test_water_takes_the_bounce_out()
	_test_nothing_leaves_the_screen()
	_test_r_puts_them_back()
	_test_buoyancy_is_measured_from_the_bottom_edge()
	_test_the_boxes_keep_their_own_lane()
	_test_a_key_release_is_not_a_reset()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[buoyancy] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

func _run(m: Node2D, frames: int) -> void:
	for i in frames:
		m._physics_process(STEP)

func _box_with_density(m: Node2D, density: float) -> Dictionary:
	for box in m._boxes:
		if is_equal_approx(box.density, density):
			return box
	return {}

## The one box in the tank, at a density of the test's choosing.
func _only_box(m: Node2D, density: float) -> Dictionary:
	m._boxes = [{
		pos = Vector2(320.0, 80.0), vel = Vector2.ZERO,
		size = Vector2(60, 40), density = density, color = Color.WHITE,
	}]
	return m._boxes[0]

func _test_the_boxes_start_in_the_air() -> void:
	print("the tank")
	var m := _make()
	expect(m._boxes.size() > 1, "there is a row of boxes")
	var above := true
	var still := true
	for box in m._boxes:
		if box.pos.y > m.WATER_Y:
			above = false
		if box.vel != Vector2.ZERO:
			still = false
	expect(above, "all of them above the waterline")
	expect(still, "and all at rest")

	var densities := {}
	for box in m._boxes:
		densities[box.density] = true
	expect(densities.size() == m._boxes.size(), "each with a different density — that is the comparison")

func _test_everything_falls_at_first() -> void:
	print("falling in")
	var m := _make()
	var light := _only_box(m, 0.3)
	_run(m, 10)
	expect(light.vel.y > 0.0, "out of the water, even a light box just falls")

func _test_a_light_box_floats() -> void:
	print("floating")
	var m := _make()
	var box := _only_box(m, 0.3)
	var deepest := 0.0
	var highest := 999.0
	for i in 900:
		m._physics_process(STEP)
		deepest = maxf(deepest, box.pos.y)
		highest = minf(highest, box.pos.y)
	expect(highest < m.WATER_Y, "a box lighter than water keeps rising back out of it")
	expect(deepest + box.size.y * 0.5 < 480.0 - 1.0, "and never reaches the bottom of the tank")

func _test_a_heavy_box_sinks() -> void:
	print("sinking")
	var m := _make()
	var box := _only_box(m, 1.4)
	_run(m, 600)
	expect(box.pos.y > m.WATER_Y + box.size.y, "a box heavier than water goes to the bottom")

func _test_a_floating_box_bobs_around_the_surface() -> void:
	print("bobbing")
	var m := _make()
	var box := _only_box(m, 0.3)
	# Buoyancy pushes hardest when the box is fully under and not at all once it
	# is clear of the water, so a cork-light box overshoots and bobs. What has
	# to hold is that it keeps crossing the surface rather than drifting off.
	var crossings := 0
	var was_under: bool = box.pos.y > m.WATER_Y
	for i in 900:
		m._physics_process(STEP)
		var under: bool = box.pos.y > m.WATER_Y
		if under != was_under:
			crossings += 1
		was_under = under
	expect(crossings > 2, "the box crosses the waterline repeatedly (%d times)" % crossings)

func _test_denser_boxes_ride_lower() -> void:
	print("waterline")
	var m := _make()
	# Averaged over the run, because the lighter boxes bob rather than settle —
	# a single snapshot would compare two boxes at unrelated points of a bounce.
	var depth := {}
	for box in m._boxes:
		depth[box.density] = 0.0
	for i in 900:
		m._physics_process(STEP)
		for box in m._boxes:
			depth[box.density] += box.pos.y
	expect(depth[0.3] < depth[0.6], "the lightest box rides highest on average")
	expect(depth[0.6] < depth[0.9], "and each denser one sits lower")
	expect(depth[0.9] < depth[1.4], "with the sinkers lowest of all")

func _test_water_takes_the_bounce_out() -> void:
	print("damping")
	var m := _make()
	var box := _only_box(m, 0.3)
	box.pos = Vector2(320.0, m.WATER_Y + 100.0)
	box.vel = Vector2(200.0, 0.0)
	_run(m, 120)
	expect(absf(box.vel.x) < 200.0, "sideways motion is dragged away underwater too")

func _test_nothing_leaves_the_screen() -> void:
	print("the tank walls")
	var m := _make()
	var box := _only_box(m, 1.4)
	box.vel = Vector2(3000.0, 3000.0)
	var escaped := false
	for i in 300:
		m._physics_process(STEP)
		if box.pos.x - box.size.x * 0.5 < -0.001 or box.pos.x + box.size.x * 0.5 > 640.001 \
				or box.pos.y - box.size.y * 0.5 < -0.001 or box.pos.y + box.size.y * 0.5 > 480.001:
			escaped = true
	expect(not escaped, "even a fast box stays inside the tank")

func _test_r_puts_them_back() -> void:
	print("reset")
	var m := _make()
	_run(m, 300)
	var moved := false
	for box in m._boxes:
		if box.pos.y > m.WATER_Y:
			moved = true
	expect(moved, "the boxes have gone into the water")

	var e := InputEventKey.new()
	e.keycode = KEY_R
	e.pressed = true
	m._input(e)
	var reset := true
	for box in m._boxes:
		if box.pos.y > m.WATER_Y or box.vel != Vector2.ZERO:
			reset = false
	expect(reset, "R lifts them back out and stops them dead")

func _test_buoyancy_is_measured_from_the_bottom_edge() -> void:
	print("how deep is submerged")
	var m := _make()
	# Sitting with its top edge level with the water: the box is entirely under,
	# so it should be pushed up hard. Measuring from the wrong edge would read
	# this as not submerged at all, and it would sink instead.
	var box := _only_box(m, 0.3)
	box.pos = Vector2(320.0, m.WATER_Y + box.size.y * 0.5)
	m._physics_process(STEP)
	expect(box.vel.y < 0.0, "a fully submerged light box accelerates upwards")

	var dry := _make()
	var above := _only_box(dry, 0.3)
	above.pos = Vector2(320.0, m.WATER_Y - above.size.y)
	dry._physics_process(STEP)
	expect(above.vel.y > 0.0, "and one clear of the water only falls")

func _test_the_boxes_keep_their_own_lane() -> void:
	print("sideways")
	var m := _make()
	var start_x: Array[float] = []
	for box in m._boxes:
		start_x.append(box.pos.x)
	_run(m, 300)
	var drifted := false
	for i in m._boxes.size():
		if not is_equal_approx(m._boxes[i].pos.x, start_x[i]):
			drifted = true
	expect(not drifted, "nothing pushes the boxes sideways, so they stay in their columns")

func _test_a_key_release_is_not_a_reset() -> void:
	print("key releases")
	var m := _make()
	_run(m, 300)
	var moved: Array[float] = []
	for box in m._boxes:
		moved.append(box.pos.y)
	var release := InputEventKey.new()
	release.keycode = KEY_R
	release.pressed = false
	m._input(release)
	var same := true
	for i in m._boxes.size():
		if not is_equal_approx(m._boxes[i].pos.y, moved[i]):
			same = false
	expect(same, "letting go of R does not reset the tank")
