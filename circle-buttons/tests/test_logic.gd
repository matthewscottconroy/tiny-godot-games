extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_hit_inside()
	_test_hit_outside()
	_test_hit_edge()
	_test_hit_overlap_priority()
	_test_place_single_centered()
	_test_place_three_symmetric()
	_test_place_gap()
	_test_data_preserved()
	_test_extra_keys_preserved()
	_report()

# ---- mirror of circle_display.gd logic -------------------------------------

const GAP := 20.0

func _place(specs: Array) -> Array:
	var circles := []
	for s in specs:
		circles.append(s.duplicate())

	var total_w := 0.0
	for c in circles:
		total_w += c.get("radius", 30.0) * 2.0
	if circles.size() > 1:
		total_w += GAP * (circles.size() - 1)

	var x := -total_w * 0.5
	for c in circles:
		var r: float = c.get("radius", 30.0)
		c["_ox"] = x + r
		c["_oy"] = 0.0
		x += r * 2.0 + GAP
	return circles

func _hit_test(circles: Array, local_pos: Vector2, ctrl_size: Vector2) -> int:
	var center := ctrl_size * 0.5
	for i in range(circles.size() - 1, -1, -1):
		var c := circles[i]
		var pos := center + Vector2(c["_ox"], c["_oy"])
		if local_pos.distance_to(pos) <= c.get("radius", 30.0):
			return i
	return -1

# ---- helpers ---------------------------------------------------------------

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

# ---- tests -----------------------------------------------------------------

func _test_hit_inside() -> void:
	print("hit: inside circle")
	var circles := _place([{"radius": 40.0}])
	var sz := Vector2(200.0, 120.0)
	expect(_hit_test(circles, sz * 0.5, sz) == 0, "click at center of single circle → index 0")

func _test_hit_outside() -> void:
	print("hit: outside all circles")
	var circles := _place([{"radius": 30.0}])
	var sz := Vector2(200.0, 100.0)
	expect(_hit_test(circles, Vector2(4.0, 4.0), sz) == -1, "click in corner returns -1")

func _test_hit_edge() -> void:
	print("hit: edge boundary")
	var circles := _place([{"radius": 30.0}])
	var sz   := Vector2(200.0, 100.0)
	var ctr  := sz * 0.5
	# exactly on radius
	expect(_hit_test(circles, ctr + Vector2(30.0, 0.0), sz) == 0,  "distance == radius → hit")
	# just outside
	expect(_hit_test(circles, ctr + Vector2(30.1, 0.0), sz) == -1, "distance > radius → miss")

func _test_hit_overlap_priority() -> void:
	print("hit: overlap priority (last drawn wins)")
	# Two circles at the same center — index 1 is drawn on top
	var circles := [
		{"radius": 40.0, "color": Color.RED,  "_ox": 0.0, "_oy": 0.0},
		{"radius": 40.0, "color": Color.BLUE, "_ox": 0.0, "_oy": 0.0},
	]
	var sz := Vector2(200.0, 100.0)
	expect(_hit_test(circles, sz * 0.5, sz) == 1, "overlapping circles: higher index wins")

func _test_place_single_centered() -> void:
	print("layout: single circle offset is zero")
	var circles := _place([{"radius": 25.0}])
	expect_near(circles[0]["_ox"], 0.0, "single circle _ox == 0")
	expect_near(circles[0]["_oy"], 0.0, "single circle _oy == 0")

func _test_place_three_symmetric() -> void:
	print("layout: three equal circles are symmetric around center")
	var r := 30.0
	var circles := _place([{"radius": r}, {"radius": r}, {"radius": r}])
	expect_near(circles[1]["_ox"], 0.0,              "middle circle _ox == 0")
	expect_near(circles[0]["_ox"], -circles[2]["_ox"], "outer circles are symmetric")
	expect(circles[0]["_ox"] < 0.0, "first circle is left of center")

func _test_place_gap() -> void:
	print("layout: gap between adjacent circles")
	var r := 20.0
	var circles := _place([{"radius": r}, {"radius": r}])
	# Distance between centers = 2*r + GAP
	var dist := circles[1]["_ox"] - circles[0]["_ox"]
	expect_near(dist, r * 2.0 + GAP, "centers are 2r + GAP apart")

func _test_data_preserved() -> void:
	print("data: spec fields survive configure")
	var spec := {"radius": 44.0, "color": Color.TOMATO, "label": "Z"}
	var circles := _place([spec])
	expect(circles[0]["label"]  == "Z",            "label preserved")
	expect(circles[0]["color"]  == Color.TOMATO,   "color preserved")
	expect(circles[0]["radius"] == 44.0,           "radius preserved")

func _test_extra_keys_preserved() -> void:
	print("data: extra keys survive configure")
	var spec := {"radius": 30.0, "color": Color.WHITE, "id": 42, "tag": "boss"}
	var circles := _place([spec])
	expect(circles[0]["id"]  == 42,     "integer extra key preserved")
	expect(circles[0]["tag"] == "boss", "string extra key preserved")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
