extends Node

# Drives the real player from scripts/player.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_no_input_is_no_movement()
	_test_cardinal_directions_are_unit_length()
	_test_diagonals_are_not_faster()
	_test_all_eight_directions()
	_test_tiny_input_is_treated_as_none()
	_test_facing_is_remembered()
	_test_facing_starts_somewhere_sensible()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[top-down-controller] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/player.gd")

func _make() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.set_script(_script)
	add_child(p)
	return p

func _test_no_input_is_no_movement() -> void:
	print("no input")
	var p := _make()
	expect(p.direction_for(Vector2.ZERO) == Vector2.ZERO, "no input produces no direction")

func _test_cardinal_directions_are_unit_length() -> void:
	print("cardinals")
	var p := _make()
	for raw in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var d: Vector2 = p.direction_for(raw)
		expect(is_equal_approx(d.length(), 1.0), "%s is unit length" % raw)

func _test_diagonals_are_not_faster() -> void:
	print("diagonal speed")
	# The bug this guards against: an un-normalised diagonal has length √2, so
	# moving corner-wise is 41% faster than moving straight.
	var p := _make()
	var diagonal: Vector2 = p.direction_for(Vector2(1, 1))
	var cardinal: Vector2 = p.direction_for(Vector2(1, 0))
	expect(is_equal_approx(diagonal.length(), cardinal.length()),
		"a diagonal moves at the same speed as a cardinal")
	expect(is_equal_approx(diagonal.length(), 1.0), "and both are unit length")

func _test_all_eight_directions() -> void:
	print("eight directions")
	var p := _make()
	var seen := {}
	for x in [-1.0, 0.0, 1.0]:
		for y in [-1.0, 0.0, 1.0]:
			var d: Vector2 = p.direction_for(Vector2(x, y))
			if d != Vector2.ZERO:
				seen["%.2f,%.2f" % [d.x, d.y]] = true
	expect(seen.size() == 8, "all eight headings are reachable and distinct")

func _test_tiny_input_is_treated_as_none() -> void:
	print("dead zone")
	var p := _make()
	# Analogue sticks rest slightly off centre; normalising that would produce a
	# full-speed direction from a stick nobody touched.
	expect(p.direction_for(Vector2(0.0001, 0.0)) == Vector2.ZERO,
		"input below the threshold is ignored rather than amplified")

func _test_facing_is_remembered() -> void:
	print("facing")
	var p := _make()
	p.update_facing(p.direction_for(Vector2.RIGHT))
	expect(p.facing().is_equal_approx(Vector2.RIGHT), "facing follows movement")
	p.update_facing(p.direction_for(Vector2.ZERO))
	expect(p.facing().is_equal_approx(Vector2.RIGHT),
		"releasing input keeps the last facing rather than resetting it")
	p.update_facing(p.direction_for(Vector2.UP))
	expect(p.facing().is_equal_approx(Vector2.UP), "moving again updates it")

func _test_facing_starts_somewhere_sensible() -> void:
	print("initial facing")
	var p := _make()
	expect(p.facing().length() > 0.001,
		"facing starts non-zero, so the indicator has a direction before you move")
