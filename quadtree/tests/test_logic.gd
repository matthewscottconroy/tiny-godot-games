extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_insert_and_query()
	_test_query_miss()
	_test_subdivision()
	_test_max_depth()
	_test_clear()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[quadtree] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make_obj(x: float, y: float, r: float = 5.0) -> Dictionary:
	return {"pos": Vector2(x, y), "radius": r}

# ──────────────────────── Tests ────────────────────────

func _test_insert_and_query() -> void:
	print("Test: insert 3 objects, query all")
	var qt := QTNode.new(Rect2(0, 0, 100, 100))
	qt.insert(_make_obj(10, 10))
	qt.insert(_make_obj(50, 50))
	qt.insert(_make_obj(80, 80))
	var result := qt.query(Rect2(0, 0, 100, 100))
	expect(result.size() == 3, "query returns 3 objects (got %d)" % result.size())

func _test_query_miss() -> void:
	print("Test: query area with no objects")
	var qt := QTNode.new(Rect2(0, 0, 100, 100))
	qt.insert(_make_obj(10, 10))
	qt.insert(_make_obj(20, 20))
	# Query bottom-right quadrant where no objects exist
	var result := qt.query(Rect2(60, 60, 40, 40))
	expect(result.size() == 0, "query miss returns 0 (got %d)" % result.size())

func _test_subdivision() -> void:
	print("Test: insert MAX_OBJECTS+1 → subdivides")
	var qt := QTNode.new(Rect2(0, 0, 100, 100))
	# Insert MAX_OBJECTS+1 objects in the same area
	for i in range(QTNode.MAX_OBJECTS + 1):
		qt.insert(_make_obj(25.0 + i * 0.5, 25.0 + i * 0.5))
	expect(qt.children.size() == 4, "node subdivided into 4 children (got %d)" % qt.children.size())

func _test_max_depth() -> void:
	print("Test: no subdivision beyond MAX_DEPTH")
	# Create a node already at MAX_DEPTH
	var qt := QTNode.new(Rect2(0, 0, 10, 10), QTNode.MAX_DEPTH)
	# Insert more than MAX_OBJECTS
	for i in range(QTNode.MAX_OBJECTS + 5):
		qt.insert(_make_obj(5.0 + randf() * 0.01, 5.0 + randf() * 0.01))
	expect(qt.children.size() == 0, "no subdivision at MAX_DEPTH (got %d children)" % qt.children.size())

func _test_clear() -> void:
	print("Test: clear empties tree")
	var qt := QTNode.new(Rect2(0, 0, 100, 100))
	qt.insert(_make_obj(10, 10))
	qt.insert(_make_obj(50, 50))
	qt.insert(_make_obj(80, 80))
	qt.clear()
	var result := qt.query(Rect2(0, 0, 100, 100))
	expect(result.size() == 0, "after clear, query returns 0 (got %d)" % result.size())
	expect(qt.children.size() == 0, "after clear, no children remain")
